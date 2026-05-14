import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../data/music_library.dart';
import '../services/audio_service.dart';
import '../services/youtube_service.dart';
import 'history_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;

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
  yt.YoutubePlayerController? _ytController;
  Timer? _ytPositionTimer;
  bool _isVideoMode = true;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  LoopMode get loopMode => _loopMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  List<String> get favoriteSongIds => _favoriteSongIds;
  yt.YoutubePlayerController? get youtubeController => _ytController;
  bool get isVideoMode => _isVideoMode;

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

    // If song ID is empty (e.g. from Last.fm metadata), find it first
    String videoId = song.id;
    if (videoId.isEmpty) {
      debugPrint('Finding YouTube ID for: ${song.title} by ${song.artist}');
      final foundId = await _youtubeService.findVideoIdForSong(song.title, song.artist);
      if (foundId == null) {
        debugPrint('Could not find YouTube match for ${song.title}');
        return false;
      }
      videoId = foundId;
      // Update the song object with YouTube ID and YouTube Visuals (images)
      final ytResults = await _youtubeService.searchSongs('${song.title} ${song.artist}');
      final ytImage = ytResults.isNotEmpty ? ytResults[0].imageUrl : '';
      
      song = song.copyWith(
        id: videoId,
        imageUrl: ytImage,
        license: 'YouTube Standard License', // Media visuals/audio from YouTube
      );
    }

    if (isInLibrary) {
      debugPrint('Playing library song: ${song.title}');
      await _ytController?.pauseVideo();
      final index = MusicLibrary.songs.indexWhere((s) => s.id == song.id);
      await _audioService.loadAndPlay(index);
      _currentSong = song;
      notifyListeners();
      return true;
    } else {
      // YouTube song - use IFrame Player
      debugPrint('Playing YouTube song: ${song.title} (${song.id})');
      await _audioService.stop();
      
      // Close/Dispose old controller to ensure fresh state
      _ytController?.close();
      
      _ytController = yt.YoutubePlayerController.fromVideoId(
        videoId: song.id,
        autoPlay: true,
        params: const yt.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          showVideoAnnotations: false,
          playsInline: true,
        ),
      );
      
      // Listen to state changes
      _ytController!.listen((state) {
        if (state.playerState == yt.PlayerState.playing) {
          _isPlaying = true;
          _startYtPositionTimer();
        } else if (state.playerState == yt.PlayerState.paused) {
          _isPlaying = false;
          _stopYtPositionTimer();
        } else if (state.playerState == yt.PlayerState.ended) {
          _isPlaying = false;
          _stopYtPositionTimer();
          skipNext();
        }
        
        // Update duration from YouTube state (position fix pending)
        if (state.metaData.duration.inSeconds > 0) {
          _duration = state.metaData.duration;
        }
        
        notifyListeners();
      });

      _currentSong = song;
      _isPlaying = true;
      notifyListeners();
      return true;
    }

    
    return false;
  }

  Future<void> resume() async {
    if (_ytController != null && !MusicLibrary.songs.any((s) => s.id == _currentSong?.id)) {
      await _ytController!.playVideo();
    } else {
      await _audioService.play();
    }
  }

  Future<void> pause() async {
    if (_ytController != null && !MusicLibrary.songs.any((s) => s.id == _currentSong?.id)) {
      await _ytController!.pauseVideo();
    } else {
      await _audioService.pause();
    }
  }

  Future<void> seek(Duration position) async {
    if (_ytController != null && !MusicLibrary.songs.any((s) => s.id == _currentSong?.id)) {
      await _ytController!.seekTo(seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
    } else {
      await _audioService.seek(position);
    }
  }
  
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
       // For YouTube, "previous" just restarts or plays a related song
       await _ytController?.seekTo(seconds: 0);
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

  void toggleVideoMode() {
    _isVideoMode = !_isVideoMode;
    notifyListeners();
  }

  void _startYtPositionTimer() {
    _ytPositionTimer?.cancel();
    _ytPositionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_ytController != null && _isPlaying) {
        final time = await _ytController!.currentTime;
        _position = Duration(seconds: time.toInt());
        notifyListeners();
      }
    });
  }

  void _stopYtPositionTimer() {
    _ytPositionTimer?.cancel();
    _ytPositionTimer = null;
  }

  @override
  void dispose() {
    _stopYtPositionTimer();
    _audioService.dispose();
    _ytController?.close();
    super.dispose();
  }
}
