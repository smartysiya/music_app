import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../data/music_library.dart';

class YouTubeService {
  /// Search for songs on YouTube using the Data API v3.
  Future<List<Song>> searchSongs(String query) async {
    if (kYouTubeApiKey.isEmpty) {
      debugPrint('YouTube API Error: YOUTUBE_API_KEY is not set. Check your .env file.');
      return [];
    }
    final encodedQuery = Uri.encodeComponent(query);
    final searchUrl = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$encodedQuery&type=video&videoCategoryId=10&maxResults=10&key=$kYouTubeApiKey';

    debugPrint('YouTube API Request: ...q=$encodedQuery&type=video&videoCategoryId=10&maxResults=1');

    try {
      final searchResponse = await http.get(Uri.parse(searchUrl));
      debugPrint('YouTube API Status: ${searchResponse.statusCode}');
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final List? items = searchData['items'];
        
        if (items == null || items.isEmpty) {
          debugPrint('YouTube API returned empty data for query: $query');
          return [];
        }

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
            isLive: snippet['liveBroadcastContent'] == 'live' || snippet['liveBroadcastContent'] == 'upcoming',
          );
        }).toList();
      } else {
        debugPrint('YouTube API Error: ${searchResponse.statusCode} - ${searchResponse.body}');
        return [];
      }
    } catch (e) {
      debugPrint('YouTube API Exception: $e');
      return [];
    }
  }

  String _parseDuration(String isoDuration) {
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

  /// Extracts the videoId and builds the playable URL.
  /// (Required for passing to the YouTube Player IFrame)
  Future<String?> getAudioStreamUrl(Song song) async {
    // We now just build the official playable URL instead of scraping a raw stream.
    return 'https://www.youtube.com/watch?v=${song.id}';
  }

  Future<List<Song>> getFeaturedSongs() async {
    return searchSongs('trending music 2024');
  }

  Future<List<Song>> getRelatedSongs(String videoId, {String? title, String? artist}) async {
    if (kYouTubeApiKey.isEmpty) {
      debugPrint('YouTube API Error: YOUTUBE_API_KEY is not set. Check your .env file.');
      return [];
    }
    try {
      final relatedUrl = 'https://www.googleapis.com/youtube/v3/search?part=snippet&relatedToVideoId=$videoId&type=video&maxResults=10&key=$kYouTubeApiKey';
      final response = await http.get(Uri.parse(relatedUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List? items = data['items'];
        if (items != null && items.isNotEmpty) {
          final videoIds = items.map((item) => item['id']['videoId']).join(',');
          final detailsUrl = 'https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=$videoIds&key=$kYouTubeApiKey';
          final detailsResponse = await http.get(Uri.parse(detailsUrl)).timeout(const Duration(seconds: 4));
          Map<String, String> durations = {};
          
          if (detailsResponse.statusCode == 200) {
            final detailsData = json.decode(detailsResponse.body);
            for (var item in detailsData['items']) {
              durations[item['id']] = _parseDuration(item['contentDetails']['duration']);
            }
          }

          return items.map((item) {
            final snippet = item['snippet'];
            final vidId = item['id']['videoId'];
            return Song(
              id: vidId,
              title: snippet['title'],
              artist: snippet['channelTitle'],
              album: 'YouTube',
              duration: durations[vidId] ?? '--:--',
              imageUrl: snippet['thumbnails']['high']['url'],
              genre: 'Online',
              isLive: snippet['liveBroadcastContent'] == 'live' || snippet['liveBroadcastContent'] == 'upcoming',
            );
          }).toList();
        }
      }
      debugPrint('YouTube relatedToVideoId call returned status ${response.statusCode} or empty. Falling back to search recommendations.');
    } catch (e) {
      debugPrint('Error getting related songs via relatedToVideoId: $e. Falling back to search recommendations.');
    }

    if (title != null && title.isNotEmpty) {
      final query = artist != null && artist.isNotEmpty ? '$title by $artist recommendations' : '$title recommendations';
      debugPrint('Executing fallback search recommendations query: "$query"');
      return await searchSongs(query);
    }
    return [];
  }

  void dispose() {
    // No more YoutubeExplode to close.
  }

  Future<String?> findVideoId(String title, String artist) async {
    if (kYouTubeApiKey.isEmpty) {
      debugPrint('YouTube API Error: YOUTUBE_API_KEY is not set. Check your .env file.');
      return null;
    }
    final query = '$title by $artist official audio';
    final encodedQuery = Uri.encodeComponent(query);
    final searchUrl = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$encodedQuery&type=video&videoCategoryId=10&maxResults=1&key=$kYouTubeApiKey';
    try {
      final response = await http.get(Uri.parse(searchUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final searchData = json.decode(response.body);
        final List? items = searchData['items'];
        if (items != null && items.isNotEmpty) {
          return items[0]['id']['videoId'];
        }
      }
    } catch (e) {
      debugPrint('Error finding video ID for $title by $artist: $e');
    }
    return null;
  }
}

