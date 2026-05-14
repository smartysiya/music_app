import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/music_library.dart';

class HistoryItem {
  final Song song;
  final DateTime playedAt;

  HistoryItem({required this.song, required this.playedAt});

  Map<String, dynamic> toJson() => {
    'song': {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'duration': song.duration,
      'imageUrl': song.imageUrl,
      'genre': song.genre,
    },
    'playedAt': playedAt.toIso8601String(),
  };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final songData = json['song'];
    return HistoryItem(
      song: Song(
        id: songData['id'],
        title: songData['title'],
        artist: songData['artist'],
        album: songData['album'],
        duration: songData['duration'],
        imageUrl: songData['imageUrl'],
        genre: songData['genre'],
      ),
      playedAt: DateTime.parse(json['playedAt']),
    );
  }
}

class HistoryProvider extends ChangeNotifier {
  final List<HistoryItem> _history = [];
  static const String _storageKey = 'playback_history';

  List<HistoryItem> get history => List.unmodifiable(_history.reversed);

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> addToHistory(Song song) async {
    // Remove if already exists (to move it to top)
    _history.removeWhere((item) => item.song.id == song.id);
    
    _history.add(HistoryItem(song: song, playedAt: DateTime.now()));
    
    // Keep only last 50 items
    if (_history.length > 50) {
      _history.removeAt(0);
    }
    
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_storageKey);
    if (encoded != null) {
      final List decoded = json.decode(encoded);
      _history.clear();
      _history.addAll(decoded.map((item) => HistoryItem.fromJson(item)));
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_history.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  String formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
