import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/music_library.dart';

class DownloadProvider extends ChangeNotifier {
  final List<String> _downloadedSongIds = [];
  bool _isDownloadingAll = false;
  double _downloadProgress = 0.0;

  List<String> get downloadedSongIds => _downloadedSongIds;
  bool get isDownloadingAll => _isDownloadingAll;
  double get downloadProgress => _downloadProgress;

  DownloadProvider() {
    _loadDownloads();
  }

  bool isDownloaded(String songId) => _downloadedSongIds.contains(songId);

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDownloads = prefs.getStringList('downloaded_song_ids');
    if (savedDownloads != null) {
      _downloadedSongIds.clear();
      _downloadedSongIds.addAll(savedDownloads);
      notifyListeners();
    }
  }

  Future<void> _saveDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('downloaded_song_ids', _downloadedSongIds);
  }

  Future<void> downloadSong(String songId) async {
    if (isDownloaded(songId)) return;

    // Simulate download delay
    await Future.delayed(const Duration(seconds: 1));
    _downloadedSongIds.add(songId);
    await _saveDownloads();
    notifyListeners();
  }

  Future<void> downloadAll() async {
    if (_isDownloadingAll) return;
    
    _isDownloadingAll = true;
    _downloadProgress = 0.0;
    notifyListeners();

    final allSongs = MusicLibrary.songs;
    int total = allSongs.length;
    int current = 0;

    for (var song in allSongs) {
      if (!isDownloaded(song.id)) {
        // Simulate download for each song
        await Future.delayed(const Duration(milliseconds: 500));
        _downloadedSongIds.add(song.id);
        await _saveDownloads();
      }
      current++;
      _downloadProgress = current / total;
      notifyListeners();
    }

    _isDownloadingAll = false;
    notifyListeners();
  }

  Future<void> removeDownload(String songId) async {
    _downloadedSongIds.remove(songId);
    await _saveDownloads();
    notifyListeners();
  }
}
