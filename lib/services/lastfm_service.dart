import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../data/music_library.dart';

class LastFmService {
  static const String _baseUrl = 'https://ws.audioscrobbler.com/2.0/';

  Future<List<Song>> searchTracks(String query) async {
    final url = '$_baseUrl?method=track.search&track=$query&api_key=$kLastFmApiKey&format=json&limit=10';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results']['trackmatches']['track'];
        return results.map((item) {
          return Song(
            id: '', // We'll find the YouTube ID later
            title: item['name'] ?? 'Unknown',
            artist: item['artist'] ?? 'Unknown',
            album: 'Last.fm Search',
            duration: '--:--',
            imageUrl: '', // Visuals handled by YouTube
            genre: 'Music',
            license: 'Last.fm Metadata',
          );
        }).toList();
      }
    } catch (e) {
      print('Error searching Last.fm tracks: $e');
    }
    return [];
  }

  Future<List<Song>> getTopTracks() async {
    final url = '$_baseUrl?method=chart.gettoptracks&api_key=$kLastFmApiKey&format=json&limit=10';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['tracks']['track'];
        return results.map((item) {
          return Song(
            id: '',
            title: item['name'] ?? 'Unknown',
            artist: item['artist']['name'] ?? 'Unknown',
            album: 'Trending',
            duration: '--:--',
            imageUrl: '', // Visuals handled by YouTube
            genre: 'Popular',
            license: 'Last.fm Metadata',
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching Top Tracks: $e');
    }
    return [];
  }

  Future<List<Song>> getTopArtists() async {
    final url = '$_baseUrl?method=chart.gettopartists&api_key=$kLastFmApiKey&format=json&limit=10';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['artists']['artist'];
        return results.map((item) {
          return Song(
            id: '',
            title: item['name'] ?? 'Unknown',
            artist: item['name'] ?? 'Artist',
            album: 'Artist',
            duration: '--:--',
            imageUrl: '', // Visuals handled by YouTube
            genre: 'Trending',
            license: 'Last.fm Metadata',
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching Top Artists: $e');
    }
    return [];
  }

  Future<List<Song>> searchAlbums(String query) async {
    final url = '$_baseUrl?method=album.search&album=$query&api_key=$kLastFmApiKey&format=json&limit=10';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results']['albummatches']['album'];
        return results.map((item) {
          return Song(
            id: '', 
            title: item['name'] ?? 'Unknown',
            artist: item['artist'] ?? 'Unknown',
            album: item['name'] ?? 'Album',
            duration: '--:--',
            imageUrl: '', // Visuals handled by YouTube
            genre: 'Album',
            license: 'Last.fm Metadata',
          );
        }).toList();
      }
    } catch (e) {
      print('Error searching Last.fm albums: $e');
    }
    return [];
  }

  Future<List<Song>> getAlbumTracks(String artist, String album) async {
    final url = '$_baseUrl?method=album.getinfo&api_key=$kLastFmApiKey&artist=$artist&album=$album&format=json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['album']['tracks']['track'];
        return results.map((item) {
          return Song(
            id: '',
            title: item['name'] ?? 'Unknown',
            artist: artist,
            album: album,
            duration: _formatSeconds(item['duration'] ?? 0),
            imageUrl: '', // Track info often doesn't have image, we'll use album's
            genre: 'Music',
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching album tracks: $e');
    }
    return [];
  }

  String _formatSeconds(dynamic sec) {
    int s = int.tryParse(sec.toString()) ?? 0;
    int minutes = (s / 60).floor();
    int remainingSeconds = s % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getHighestResImage(List? images) {
    if (images == null || images.isEmpty) return '';
    // Last.fm image sizes: small, medium, large, extralarge, mega
    final mega = images.firstWhere((img) => img['size'] == 'mega', orElse: () => null);
    if (mega != null && mega['#text'].isNotEmpty) return mega['#text'];
    
    final xl = images.firstWhere((img) => img['size'] == 'extralarge', orElse: () => null);
    if (xl != null && xl['#text'].isNotEmpty) return xl['#text'];
    
    return images.last['#text'] ?? '';
  }
}
