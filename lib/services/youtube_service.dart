import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../constants.dart';
import '../data/music_library.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Search for songs on YouTube using the Data API v3.
  Future<List<Song>> searchSongs(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final searchUrl = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$encodedQuery&type=video&videoCategoryId=10&maxResults=10&key=$kYouTubeApiKey';

    debugPrint('YouTube API Request: $searchUrl');

    try {
      final searchResponse = await http.get(Uri.parse(searchUrl));
      debugPrint('YouTube API Status: ${searchResponse.statusCode}');
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final List? items = searchData['items'];
        
        if (items == null || items.isEmpty) {
          debugPrint('YouTube API returned empty data for query: $query');
          return _fallbackSearch(query);
        }

        debugPrint('YouTube API Response (first item): ${json.encode(items[0]).substring(0, 200)}...');

        final videoIds = items.map((item) => item['id']['videoId']).join(',');
        final detailsUrl = 'https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=$videoIds&key=$kYouTubeApiKey';
        
        final detailsResponse = await http.get(Uri.parse(detailsUrl));
        Map<String, String> durations = {};
        
        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);
          for (var item in detailsData['items']) {
            durations[item['id']] = _parseDuration(item['contentDetails']['duration']);
          }
        } else {
          debugPrint('YouTube Details API Failed: ${detailsResponse.statusCode} - ${detailsResponse.body}');
        }

        return items.map((item) {
          final snippet = item['snippet'];
          final videoId = item['id']['videoId'];
          
          return Song(
            id: videoId,
            title: snippet['title'],
            artist: snippet['channelTitle'],
            album: 'YouTube',
            duration: durations[videoId] ?? '--:--',
            imageUrl: snippet['thumbnails']['high']['url'],
            genre: 'Online',
          );
        }).toList();
      } else {
        debugPrint('YouTube API Error: ${searchResponse.statusCode} - ${searchResponse.body}');
        return _fallbackSearch(query);
      }
    } catch (e) {
      debugPrint('YouTube API Exception: $e');
      return _fallbackSearch(query);
    }
  }

  /// Fallback search using youtube_explode_dart when Data API is unavailable or fails.
  Future<List<Song>> _fallbackSearch(String query) async {
    debugPrint('Executing fallback search for: $query');
    try {
      final results = await _yt.search.search(query);
      return results.map((video) {
        return Song(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: 'YouTube',
          duration: video.duration?.toString().split('.').first ?? '--:--',
          imageUrl: video.thumbnails.highResUrl,
          genre: 'Online',
        );
      }).toList();
    } catch (e) {
      debugPrint('Fallback Search Failed: $e');
      return [];
    }
  }

  String _parseDuration(String isoDuration) {
    // PT3M42S -> 3:42
    // PT1H2M30S -> 1:02:30
    final regExp = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regExp.firstMatch(isoDuration);
    if (match == null) return '--:--';

    final hours = match.group(1);
    final minutes = match.group(2) ?? '0';
    final seconds = match.group(3) ?? '0';

    String result = '';
    if (hours != null) {
      result += '$hours:${minutes.padLeft(2, '0')}:';
    } else {
      result += '$minutes:';
    }
    result += seconds.padLeft(2, '0');
    return result;
  }

  /// Get a direct audio stream URL for a given YouTube song.
  /// If the original video is unavailable (e.g., official music videos blocking streams),
  /// it performs a fallback search for an audio version.
  Future<String?> getAudioStreamUrl(Song song) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(song.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      return audioStream.url.toString();
    } catch (e) {
      // Original video failed, try fallback search
      try {
        final query = '${song.title} ${song.artist} audio';
        final searchResults = await _yt.search.search(query);
        for (var video in searchResults) {
          if (video.id.value != song.id) {
            try {
              final manifest = await _yt.videos.streamsClient.getManifest(video.id);
              final audioStream = manifest.audioOnly.withHighestBitrate();
              return audioStream.url.toString();
            } catch (_) {
              continue;
            }
          }
        }
      } catch (fallbackError) {
        return null;
      }
      return null;
    }
  }

  Future<List<Song>> getFeaturedSongs() async {
    return searchSongs('trending music 2024');
  }

  Future<List<Song>> getRelatedSongs(String videoId) async {
    try {
      final video = await _yt.videos.get(VideoId(videoId));
      final relatedVideos = await _yt.videos.getRelatedVideos(video);
      if (relatedVideos == null) return [];
      
      return relatedVideos.map((video) {
        return Song(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: 'YouTube',
          duration: video.duration?.toString().split('.').first ?? '--:--',
          imageUrl: video.thumbnails.highResUrl,
          genre: 'Online',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting related songs: $e');
      return [];
    }
  }

  void dispose() {
    _yt.close();
  }

  Future<String?> findVideoIdForSong(String title, String artist) async {
    final query = '$title by $artist official audio';
    final results = await searchSongs(query);
    if (results.isNotEmpty) {
      return results[0].id;
    }
    return null;
  }

  /// Fetches the real, authoritative metadata for a YouTube video.
  /// Returns an updated [Song] with fresh title, artist, duration, and thumbnail.
  /// Returns null only if the video is completely unreachable.
  Future<Song?> fetchVideoMetadata(String videoId, {Song? existing}) async {
    try {
      debugPrint('Fetching metadata for video: $videoId');
      final video = await _yt.videos.get(VideoId(videoId))
          .timeout(const Duration(seconds: 5));

      // Parse the actual duration from the Video object
      final dur = video.duration;
      String durationStr = '--:--';
      if (dur != null) {
        final hours = dur.inHours;
        final minutes = dur.inMinutes.remainder(60);
        final seconds = dur.inSeconds.remainder(60);
        if (hours > 0) {
          durationStr = '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        } else {
          durationStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
        }
      }

      // Clean up the title: remove " (Official Video)", " [Official Audio]", etc.
      String cleanTitle = video.title
          .replaceAll(RegExp(r'\s*[\(\[](Official|Lyric|Music|Audio|HD|HQ)[\s\w]*[\)\]]', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s*\|\s*.*$'), '') // Remove " | Something"
          .trim();

      final updatedSong = Song(
        id: videoId,
        title: cleanTitle.isNotEmpty ? cleanTitle : video.title,
        artist: video.author,
        album: existing?.album ?? 'YouTube',
        duration: durationStr,
        imageUrl: video.thumbnails.highResUrl,
        genre: existing?.genre ?? 'Online',
        license: 'YouTube Standard License',
      );

      debugPrint('Metadata resolved: "${updatedSong.title}" by ${updatedSong.artist} [${updatedSong.duration}]');
      return updatedSong;
    } catch (e) {
      debugPrint('Failed to fetch metadata for $videoId: $e');
      return null;
    }
  }
}
