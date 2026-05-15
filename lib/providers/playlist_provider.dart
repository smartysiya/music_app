import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/music_library.dart';

/// A single user-created playlist.
class UserPlaylist {
  final String id;
  final String name;
  final List<String> songIds; // Stores song IDs for persistence
  final DateTime createdAt;

  UserPlaylist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'songIds': songIds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    return UserPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled',
      songIds: List<String>.from(json['songIds'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Provider that manages user playlists with rock-solid persistence.
/// 
/// Design principles:
/// - Playlists are NEVER auto-deleted. Only explicit user action removes them.
/// - Every mutation is persisted immediately.
/// - Load errors never corrupt or discard existing data.
class PlaylistProvider extends ChangeNotifier {
  static const String _storageKey = 'user_playlists_v1';

  List<UserPlaylist> _playlists = [];
  bool _isLoaded = false;

  List<UserPlaylist> get playlists => List.unmodifiable(_playlists);
  bool get isLoaded => _isLoaded;

  PlaylistProvider() {
    _loadPlaylists();
  }

  /// Load playlists from persistent storage.
  /// On any error, keeps whatever was loaded and logs the issue — never wipes data.
  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        _playlists = decoded
            .map((item) => UserPlaylist.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('Loaded ${_playlists.length} playlists from storage.');
      } else {
        debugPrint('No saved playlists found. Starting fresh.');
      }
    } catch (e) {
      // CRITICAL: Never discard data on error.
      debugPrint('Error loading playlists (data preserved): $e');
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Persist all playlists to storage immediately.
  Future<bool> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_playlists.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      debugPrint('Saved ${_playlists.length} playlists to storage.');
      return true;
    } catch (e) {
      debugPrint('CRITICAL: Failed to save playlists: $e');
      return false;
    }
  }

  /// Create a new playlist. Returns the created playlist.
  Future<UserPlaylist> createPlaylist(String name) async {
    final playlist = UserPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Untitled Playlist' : name.trim(),
      songIds: [],
      createdAt: DateTime.now(),
    );

    _playlists.insert(0, playlist); // Newest first
    notifyListeners();
    await _savePlaylists();
    return playlist;
  }

  /// Rename a playlist.
  Future<void> renamePlaylist(String playlistId, String newName) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    _playlists[index] = UserPlaylist(
      id: _playlists[index].id,
      name: newName.trim().isEmpty ? 'Untitled Playlist' : newName.trim(),
      songIds: _playlists[index].songIds,
      createdAt: _playlists[index].createdAt,
    );
    notifyListeners();
    await _savePlaylists();
  }

  /// Delete a playlist. ONLY called by explicit user action.
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    await _savePlaylists();
  }

  /// Add a song to a playlist. Avoids duplicates.
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    if (!_playlists[index].songIds.contains(songId)) {
      _playlists[index].songIds.add(songId);
      notifyListeners();
      await _savePlaylists();
    }
  }

  /// Remove a song from a playlist.
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    _playlists[index].songIds.remove(songId);
    notifyListeners();
    await _savePlaylists();
  }

  /// Resolve song IDs to Song objects (handles missing songs gracefully).
  List<Song> getSongsForPlaylist(String playlistId) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => UserPlaylist(id: '', name: '', songIds: [], createdAt: DateTime.now()),
    );

    final List<Song> songs = [];
    for (final songId in playlist.songIds) {
      // Check local library first
      final libSong = MusicLibrary.songs.where((s) => s.id == songId);
      if (libSong.isNotEmpty) {
        songs.add(libSong.first);
      }
      // YouTube songs are stored by ID and resolved at play time
    }
    return songs;
  }

  /// Get a single playlist by ID.
  UserPlaylist? getPlaylist(String playlistId) {
    try {
      return _playlists.firstWhere((p) => p.id == playlistId);
    } catch (_) {
      return null;
    }
  }
}
