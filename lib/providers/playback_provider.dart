import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../data/music_library.dart';
import '../services/audio_service.dart';
import '../services/youtube_service.dart';
import 'history_provider.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final YouTubeService _youtubeService = YouTubeService();
  
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  final List<String> _favoriteSongIds = []; 
  String? _lastErrorMessage;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  LoopMode get loopMode => _loopMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  List<String> get favoriteSongIds => _favoriteSongIds;
  String? get lastErrorMessage => _lastErrorMessage;
  bool isFavorite(String songId) => _favoriteSongIds.contains(songId);

  void toggleFavorite(String songId) {
    if (_favoriteSongIds.contains(songId)) {
      _favoriteSongIds.remove(songId);
    } else {
      _favoriteSongIds.add(songId);
    }
    _saveToPrefs();
    notifyListeners();
  }

  PlaybackProvider() {
    _loadFromPrefs();
    
    // Listen to player state
    _audioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    // Listen to position updates
    _audioService.positionStream.listen((pos) {
      if (pos != null) {
        _position = pos;
        notifyListeners();
      }
    });

    // Listen to duration updates
    _audioService.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    // Listen to volume updates
    _audioService.volumeStream.listen((vol) {
      _volume = vol;
      notifyListeners();
    });

    // Listen to sequence state to get the current song from the tag
    _audioService.player.sequenceStateStream.listen((state) {
      final tag = state?.currentSource?.tag;
      if (tag is Song) {
        _currentSong = tag;
        notifyListeners();
      }
    });

    // Listen to loop mode updates
    _audioService.loopModeStream.listen((mode) {
      _loopMode = mode;
      notifyListeners();
    });

    // Listen to shuffle updates
    _audioService.shuffleModeEnabledStream.listen((enabled) {
      _isShuffleEnabled = enabled;
      notifyListeners();
    });
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastSaved = prefs.getInt('favorites_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - lastSaved < 30 * 60 * 1000) {
      final savedFavs = prefs.getStringList('favorite_song_ids');
      if (savedFavs != null) {
        _favoriteSongIds.clear();
        _favoriteSongIds.addAll(savedFavs);
        notifyListeners();
      }
    } else {
      debugPrint('Favorites data expired or not found');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_song_ids', _favoriteSongIds);
    await prefs.setInt('favorites_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> playSong(Song song, {bool isOffline = false, bool isDownloaded = false}) async {
    // Check if it's a YouTube song (assuming ID is video ID and not in library)
    final isInLibrary = MusicLibrary.songs.any((s) => s.id == song.id);

    if (isOffline && !isDownloaded && isInLibrary) {
      return false; // Cannot play local song: offline and not downloaded
    }

    if (_currentSong?.id == song.id && song.id.isNotEmpty) {
      if (_isPlaying) {
        await pause();
      } else {
        await resume();
      }
      return true;
    }

    // If song ID is empty (e.g. from metadata), find it first
    String videoId = song.id;
    if (videoId.isEmpty) {
      debugPrint('Finding YouTube ID for: ${song.title} by ${song.artist}');
      final foundId = await _youtubeService.findVideoIdForSong(song.title, song.artist);
      if (foundId == null) {
        debugPrint('Could not find YouTube match for ${song.title}');
        return false;
      }
      videoId = foundId;
      song = song.copyWith(id: videoId);
    }

    if (isInLibrary) {
      debugPrint('Playing library song: ${song.title}');
      final index = MusicLibrary.songs.indexWhere((s) => s.id == song.id);
      await _audioService.loadAndPlay(index);
      _currentSong = song;
      notifyListeners();
      return true;
    } else {
      // YouTube song — fetch fresh metadata + resolve audio stream
      debugPrint('Playing YouTube audio: ${song.title} (${song.id})');
      
      // Fetch real metadata from YouTube API to update title/artist/duration/thumbnail
      final freshMetadata = await _youtubeService.fetchVideoMetadata(
        videoId,
        existing: song,
      );
      
      if (freshMetadata != null) {
        // Update song with authoritative metadata from YouTube
        song = freshMetadata;
        debugPrint('Metadata updated: "${song.title}" by ${song.artist} [${song.duration}]');
        
        // Immediately update UI with fresh metadata (before audio loads)
        _currentSong = song;
        notifyListeners();
      } else {
        debugPrint('Metadata fetch failed — using existing metadata for: ${song.title}');
      }

      // Now resolve and play the audio stream
      final success = await _audioService.loadAndPlayUrl(song.id, song);
      
      if (success) {
        // Ensure the current song reflects the version that was actually loaded
        _currentSong = song;
        _lastErrorMessage = null;
        notifyListeners();
        return true;
      }
      
      _lastErrorMessage = _audioService.lastErrorMessage;
      debugPrint('All resolution tiers failed for: ${song.title}');
      return false;
    }
  }

  Future<void> resume() async => await _audioService.play();
  Future<void> pause() async => await _audioService.pause();
  Future<void> seek(Duration position) async => await _audioService.seek(position);
  
  Future<void> skipNext() async {
    if (_currentSong?.album == 'YouTube') {
      debugPrint('Fetching next YouTube song...');
      final related = await _youtubeService.getRelatedSongs(_currentSong!.id);
      if (related.isNotEmpty) {
        await playSong(related[0]);
      } else {
        await playSong(MusicLibrary.songs[0]);
      }
    } else {
      await _audioService.skipNext();
    }
  }

  Future<void> skipPrevious() async {
    if (_currentSong?.album == 'YouTube') {
       await seek(Duration.zero);
    } else {
      await _audioService.skipPrevious();
    }
  }

  Future<void> toggleLoopMode() async {
    final nextMode = _loopMode == LoopMode.off 
        ? LoopMode.one 
        : (_loopMode == LoopMode.one ? LoopMode.all : LoopMode.off);
    await _audioService.setLoopMode(nextMode);
  }

  Future<void> toggleShuffle() async {
    await _audioService.setShuffleMode(!_isShuffleEnabled);
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
