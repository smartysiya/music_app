import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/music_library.dart';
import '../services/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class PlaybackProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  final List<String> _favoriteSongIds = []; 

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  LoopMode get loopMode => _loopMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  List<String> get favoriteSongIds => _favoriteSongIds;

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

    // Listen to current index updates
    _audioService.currentIndexStream.listen((index) {
      if (index != null && index < MusicLibrary.songs.length) {
        _currentSong = MusicLibrary.songs[index];
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

  Future<void> playSong(Song song) async {
    final index = MusicLibrary.songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      if (_currentSong?.id == song.id) {
        if (_isPlaying) {
          await pause();
        } else {
          await resume();
        }
      } else {
        await _audioService.loadAndPlay(index);
      }
    }
  }

  Future<void> resume() => _audioService.play();
  Future<void> pause() => _audioService.pause();
  Future<void> seek(Duration position) => _audioService.seek(position);
  
  Future<void> skipNext() => _audioService.skipNext();
  Future<void> skipPrevious() => _audioService.skipPrevious();

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
