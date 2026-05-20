import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../data/music_library.dart';
import '../services/audio_service.dart';
import '../services/youtube_service.dart';
import '../services/lastfm_service.dart';
import 'package:just_audio/just_audio.dart';

class SmartAudioCacheItem {
  final Uint8List? audioBytes;
  final String? youtubeVideoId;
  final TrackMetadata? metadata;

  SmartAudioCacheItem({
    this.audioBytes,
    this.youtubeVideoId,
    this.metadata,
  });
}

class SmartAudioCache {
  final Map<String, SmartAudioCacheItem> _cache = {};
  final YouTubeService _youtubeService;
  final LastFmService _lastFmService;
  final http.Client _client = http.Client();

  SmartAudioCache({
    required YouTubeService youtubeService,
    required LastFmService lastFmService,
  })  : _youtubeService = youtubeService,
        _lastFmService = lastFmService;

  SmartAudioCacheItem? get(String songId) => _cache[songId];

  void put(String songId, SmartAudioCacheItem item) {
    _cache[songId] = item;
  }

  List<String> get cachedKeys => _cache.keys.toList();

  void keepOnly(List<String> allowedKeys) {
    final toRemove = _cache.keys.where((k) => !allowedKeys.contains(k)).toList();
    for (var key in toRemove) {
      _cache.remove(key);
      debugPrint('SmartAudioCache: Evicted $key from cache');
    }
  }

  Future<void> preloadSong(Song song) async {
    if (_cache.containsKey(song.id)) {
      final item = _cache[song.id]!;
      if (item.metadata != null && (item.youtubeVideoId != null || item.audioBytes != null)) {
        return;
      }
    }

    debugPrint('SmartAudioCache: Preloading background task started for "${song.title}"');
    _cache[song.id] = SmartAudioCacheItem();

    try {
      TrackMetadata? metadata;
      try {
        metadata = await _lastFmService.fetchTrackInfo(song.title, song.artist);
      } catch (e) {
        debugPrint('SmartAudioCache: Error preloading Last.fm metadata for "${song.title}": $e');
      }

      String? youtubeVideoId;
      Uint8List? audioBytes;

      final isYoutube = song.id.length == 11 || !song.id.contains('.') || song.id.isEmpty;
      if (isYoutube) {
        try {
          String searchTitle = metadata?.title ?? song.title;
          String searchArtist = metadata?.artist ?? song.artist;
          youtubeVideoId = await _youtubeService.findVideoId(searchTitle, searchArtist);
        } catch (e) {
          debugPrint('SmartAudioCache: Error preloading YouTube ID for "${song.title}": $e');
        }
      } else {
        try {
          final uri = Uri.parse(song.id);
          if (uri.host.isNotEmpty) {
            final res = await _client.get(uri).timeout(const Duration(seconds: 10));
            if (res.statusCode == 200) {
              audioBytes = res.bodyBytes;
              debugPrint('SmartAudioCache: Preloaded ${audioBytes.length} bytes for "${song.title}"');
            }
          }
        } catch (e) {
          debugPrint('SmartAudioCache: Error preloading audio bytes for "${song.title}": $e');
        }
      }

      _cache[song.id] = SmartAudioCacheItem(
        metadata: metadata,
        youtubeVideoId: youtubeVideoId,
        audioBytes: audioBytes,
      );
      debugPrint('SmartAudioCache: Successfully cached "${song.title}"');
    } catch (e) {
      debugPrint('SmartAudioCache: Failed preload task for "${song.title}": $e');
      _cache.remove(song.id);
    }
  }

  void dispose() {
    _client.close();
    _cache.clear();
  }
}

class PlaybackProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  final YouTubeService _youtubeService = YouTubeService();
  final LastFmService _lastFmService = LastFmService();
  late final SmartAudioCache _audioCache;

  int _playSequence = 0;
  
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  final List<String> _favoriteSongIds = []; 
  String? _lastErrorMessage;
  String? _loadingSongId;

  int _currentTrackIndex = -1;
  List<Song> _queue = [];
  PlayerState? _playbackState;

  final Map<String, String> _resolvedArtwork = {};

  String getArtworkForTrack(String trackId) {
    return _resolvedArtwork[trackId] ?? '';
  }

  String getArtworkForAlbum(String albumName) {
    return _resolvedArtwork['album_$albumName'] ?? '';
  }

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  LoopMode get loopMode => _loopMode;
  bool get isShuffleEnabled => _isShuffleEnabled;
  List<String> get favoriteSongIds => _favoriteSongIds;
  String? get lastErrorMessage => _lastErrorMessage;
  String? get loadingSongId => _loadingSongId;
  Widget get ytPlayerWidget => _audioService.ytPlayerWidget;

  int get currentTrackIndex => _currentTrackIndex;
  List<Song> get queue => _queue;
  List<String> get cachedAudio => _audioCache.cachedKeys;
  PlayerState? get playbackState => _playbackState;

  TrackMetadata? get currentMetadata {
    if (_currentSong == null) return null;
    final cached = _audioCache.get(_currentSong!.id);
    return cached?.metadata ?? TrackMetadata(
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.album,
      artworkUrl: _currentSong!.imageUrl,
      duration: _currentSong!.duration,
    );
  }

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
    _audioCache = SmartAudioCache(youtubeService: _youtubeService, lastFmService: _lastFmService);

    // Prepopulate artwork cache from MusicLibrary
    for (var song in MusicLibrary.songs) {
      if (song.imageUrl.isNotEmpty) {
        _resolvedArtwork[song.id] = song.imageUrl;
        _resolvedArtwork['album_${song.album}'] = song.imageUrl;
      }
    }
    _loadFromPrefs();
    
    // Listen to player state
    bool skipGuard = false;
    _audioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _playbackState = state;
      
      if (state.processingState == ProcessingState.completed && !skipGuard) {
        skipGuard = true;
        debugPrint('Playback completed. Auto-skipping to next song.');
        skipNext().then((_) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            skipGuard = false;
          });
        });
      }
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
    final savedFavs = prefs.getStringList('favorite_song_ids');
    if (savedFavs != null) {
      _favoriteSongIds.clear();
      _favoriteSongIds.addAll(savedFavs);
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_song_ids', _favoriteSongIds);
  }

  void _updateCacheAndPreload() {
    if (_queue.isEmpty || _currentTrackIndex == -1) return;

    final List<String> targetIds = [];
    final List<Song> targetSongs = [];

    void addSongAt(int idx) {
      if (idx >= 0 && idx < _queue.length) {
        final song = _queue[idx];
        if (!targetIds.contains(song.id)) {
          targetIds.add(song.id);
          targetSongs.add(song);
        }
      } else if (_loopMode == LoopMode.all && _queue.isNotEmpty) {
        final wrapIdx = idx % _queue.length;
        final song = _queue[wrapIdx];
        if (!targetIds.contains(song.id)) {
          targetIds.add(song.id);
          targetSongs.add(song);
        }
      }
    }

    addSongAt(_currentTrackIndex - 1);
    addSongAt(_currentTrackIndex);
    addSongAt(_currentTrackIndex + 1);
    addSongAt(_currentTrackIndex + 2);

    _audioCache.keepOnly(targetIds);

    for (var song in targetSongs) {
      _audioCache.preloadSong(song).then((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _generateQueueRecommendations(Song currentSong) async {
    try {
      debugPrint('Generating related recommendations for queue based on: ${currentSong.title} by ${currentSong.artist}');
      List<Song> recommendations = [];
      
      if (currentSong.id.isNotEmpty && currentSong.id.length >= 11) {
        recommendations = await _youtubeService.getRelatedSongs(
          currentSong.id,
          title: currentSong.title,
          artist: currentSong.artist,
        );
      } else {
        final query = '${currentSong.title} ${currentSong.artist} related';
        recommendations = await _youtubeService.searchSongs(query);
      }

      recommendations.removeWhere((rec) => 
        rec.id == currentSong.id || 
        _queue.any((q) => q.id == rec.id || (q.title.toLowerCase() == rec.title.toLowerCase() && q.artist.toLowerCase() == rec.artist.toLowerCase()))
      );

      if (recommendations.isNotEmpty) {
        _queue.addAll(recommendations);
        debugPrint('Appended ${recommendations.length} recommendations to the queue. New queue size: ${_queue.length}');
        notifyListeners();
        _updateCacheAndPreload();
      }
    } catch (e) {
      debugPrint('Error generating queue recommendations: $e');
    }
  }

  Future<bool> playSong(Song song, {bool isOffline = false, bool isDownloaded = false}) async {
    final int currentSeq = ++_playSequence;

    int idx = _queue.indexWhere((q) => q.id == song.id || (q.title == song.title && q.artist == song.artist));
    if (idx != -1) {
      _currentTrackIndex = idx;
    } else {
      final isLib = MusicLibrary.songs.any((s) => s.id == song.id || (s.title == song.title && s.artist == song.artist));
      if (isLib) {
        _queue = List.from(MusicLibrary.songs);
        _currentTrackIndex = _queue.indexWhere((s) => s.id == song.id || (s.title == song.title && s.artist == song.artist));
      } else {
        _queue = [song];
        _currentTrackIndex = 0;
      }
    }

    if (song.imageUrl.isNotEmpty) {
      _resolvedArtwork[song.id] = song.imageUrl;
      if (song.album.isNotEmpty) {
        _resolvedArtwork['album_${song.album}'] = song.imageUrl;
      }
    }

    final isInLibrary = MusicLibrary.songs.any((s) => s.id == song.id);

    if (isOffline && !isDownloaded && isInLibrary) {
      return false;
    }

    if (_currentSong?.id == song.id && song.id.isNotEmpty && _queue.isNotEmpty && _currentTrackIndex >= 0) {
      if (_isPlaying) {
        await pause();
      } else {
        await resume();
      }
      return true;
    }

    _loadingSongId = song.id;
    _currentSong = song;
    notifyListeners();

    _updateCacheAndPreload();

    try {
      final cachedItem = _audioCache.get(song.id);

      Future<String?> resolveVideoId() async {
        if (cachedItem?.youtubeVideoId != null) {
          debugPrint('Resolved YouTube Video ID from Cache: ${cachedItem!.youtubeVideoId}');
          return cachedItem.youtubeVideoId;
        }

        String videoId = song.id;
        final isYoutube = videoId.length == 11 || !videoId.contains('.') || videoId.isEmpty;
        if (isYoutube && (videoId.isEmpty || videoId.length < 11)) {
          debugPrint('Finding YouTube ID for: ${song.title} by ${song.artist}');
          final foundId = await _youtubeService.findVideoId(song.title, song.artist);
          if (foundId == null) {
            debugPrint('Could not find YouTube match for ${song.title}');
            return null;
          }
          videoId = foundId;
        }
        return videoId;
      }

      Future<bool> playAudio(String videoId) async {
        debugPrint('Playing audio: ${song.title} ($videoId)');
        if (cachedItem?.audioBytes != null) {
          return await _audioService.loadAndPlayUrl(videoId, song, preloadedBytes: cachedItem!.audioBytes);
        }
        return await _audioService.loadAndPlayUrl(videoId, song);
      }

      Future<TrackMetadata?> fetchLastFmMetadata() async {
        if (cachedItem?.metadata != null) {
          debugPrint('Resolved Metadata from Cache: ${cachedItem!.metadata!.title}');
          return cachedItem.metadata;
        }
        debugPrint('Fetching Last.fm metadata for: ${song.title} by ${song.artist}');
        return await _lastFmService.fetchTrackInfo(song.title, song.artist);
      }

      final results = await Future.wait([
        resolveVideoId().then((vidId) {
          if (vidId == null) return null;
          return playAudio(vidId).then((success) => success ? vidId : null);
        }).catchError((e) {
          debugPrint('Audio resolution/playback failed: $e');
          return null;
        }),
        fetchLastFmMetadata().catchError((e) {
          debugPrint('Last.fm metadata fetch failed: $e');
          return null;
        }),
      ]);

      if (currentSeq != _playSequence) {
        debugPrint('Discarding results for "${song.title}" because track has changed (sequence guard).');
        return false;
      }

      final dynamic audioResult = results[0];
      final TrackMetadata? metadata = results[1] as TrackMetadata?;

      if (metadata != null) {
        song = song.copyWith(
          title: metadata.title,
          artist: metadata.artist,
          album: metadata.album,
          duration: metadata.duration != '--:--' ? metadata.duration : song.duration,
          imageUrl: metadata.artworkUrl.isNotEmpty ? metadata.artworkUrl : song.imageUrl,
        );
        if (metadata.artworkUrl.isNotEmpty) {
          _resolvedArtwork[song.id] = metadata.artworkUrl;
          if (song.album.isNotEmpty) {
            _resolvedArtwork['album_${song.album}'] = metadata.artworkUrl;
          }
        }
        _audioCache.put(
          song.id,
          SmartAudioCacheItem(
            metadata: metadata,
            youtubeVideoId: audioResult is String ? audioResult : cachedItem?.youtubeVideoId,
            audioBytes: cachedItem?.audioBytes,
          ),
        );
        debugPrint('Last.fm metadata resolved: "${song.title}" by ${song.artist}');
      } else {
        debugPrint('Last.fm metadata fetch failed/returned null for: ${song.title}');
      }

      _currentSong = song;

      if (_currentTrackIndex >= 0 && _currentTrackIndex < _queue.length) {
        _queue[_currentTrackIndex] = song;
      }

      if (_queue.length - _currentTrackIndex <= 3) {
        _generateQueueRecommendations(song);
      }

      if (audioResult != null && audioResult is String) {
        _currentSong = song.copyWith(id: audioResult);
        _lastErrorMessage = null;
        notifyListeners();
        return true;
      } else {
        _lastErrorMessage = _audioService.lastErrorMessage ?? 'Could not stream this song';
        debugPrint('All resolution tiers failed for: ${song.title}');
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('General playSong exception: $e');
      _lastErrorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      if (currentSeq == _playSequence) {
        _loadingSongId = null;
        notifyListeners();
      }
    }
  }

  Future<void> resume() async => await _audioService.play();
  Future<void> pause() async => await _audioService.pause();
  Future<void> seek(Duration position) async => await _audioService.seek(position);
  
  Future<void> skipNext() async {
    if (_queue.isEmpty) return;

    int nextIndex = _currentTrackIndex + 1;
    if (_loopMode == LoopMode.one) {
      nextIndex = _currentTrackIndex;
    } else if (nextIndex >= _queue.length) {
      if (_loopMode == LoopMode.all) {
        nextIndex = 0;
      } else {
        await _generateQueueRecommendations(_queue[_currentTrackIndex]);
        if (_currentTrackIndex + 1 < _queue.length) {
          nextIndex = _currentTrackIndex + 1;
        } else {
          debugPrint('skipNext: End of queue reached and no recommendations found.');
          return;
        }
      }
    }

    _currentTrackIndex = nextIndex;
    final nextSong = _queue[_currentTrackIndex];
    await playSong(nextSong);
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;

    int prevIndex = _currentTrackIndex - 1;
    if (prevIndex < 0) {
      if (_loopMode == LoopMode.all) {
        prevIndex = _queue.length - 1;
      } else {
        await seek(Duration.zero);
        return;
      }
    }

    _currentTrackIndex = prevIndex;
    final prevSong = _queue[_currentTrackIndex];
    await playSong(prevSong);
  }

  Future<void> toggleLoopMode() async {
    final nextMode = _loopMode == LoopMode.off 
        ? LoopMode.one 
        : (_loopMode == LoopMode.one ? LoopMode.all : LoopMode.off);
    await _audioService.setLoopMode(nextMode);
  }

  Future<void> toggleShuffle() async {
    final nextShuffle = !_isShuffleEnabled;
    _isShuffleEnabled = nextShuffle;
    
    if (_isShuffleEnabled && _queue.isNotEmpty && _currentTrackIndex >= 0) {
      final currentSong = _queue[_currentTrackIndex];
      final rest = _queue.where((s) => s.id != currentSong.id).toList();
      rest.shuffle();
      _queue = [currentSong, ...rest];
      _currentTrackIndex = 0;
    }
    await _audioService.setShuffleMode(nextShuffle);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }

  @override
  void dispose() {
    _audioCache.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
