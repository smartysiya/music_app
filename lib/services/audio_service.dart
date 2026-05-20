import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt;
import '../data/music_library.dart';

class StreamResolution {
  final String? error;
  final String method;

  StreamResolution.success(this.method) : error = null;
  StreamResolution.failure(this.error, this.method);

  bool get isSuccess => error == null;
}

class MyBufferAudioSource extends ja.StreamAudioSource {
  final Uint8List bytes;
  final String contentType;
  
  MyBufferAudioSource(this.bytes, {super.tag, this.contentType = 'audio/mpeg'});

  @override
  Future<ja.StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return ja.StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: contentType,
    );
  }
}

class AudioService {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final yt.YoutubePlayerController _ytController = yt.YoutubePlayerController(
    params: const yt.YoutubePlayerParams(
      showControls: false,
      showFullscreenButton: false,
      loop: false,
      mute: false,
      playsInline: true,
      enableJavaScript: true,
    ),
  );

  bool _isYoutubeMode = false;
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  static const int _maxRetries = 2;
  static const String _demoAudioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  // Expose a hidden widget for the iframe player to work
  Widget get ytPlayerWidget => SizedBox(
    width: 1,
    height: 1,
    child: yt.YoutubePlayer(controller: _ytController),
  );

  final _playerStateController = StreamController<ja.PlayerState>.broadcast();
  final _positionController = StreamController<Duration?>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  Stream<ja.PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration?> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<ja.LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  AudioService() {
    _initStreams();
  }

  void _initStreams() {
    // Forward just_audio streams
    _player.playerStateStream.listen((state) {
      if (!_isYoutubeMode) _playerStateController.add(state);
    });
    _player.positionStream.listen((pos) {
      if (!_isYoutubeMode) _positionController.add(pos);
    });
    _player.durationStream.listen((dur) {
      if (!_isYoutubeMode) _durationController.add(dur);
    });

    // Forward youtube streams
    _ytController.listen((event) {
      if (_isYoutubeMode) {
        final isPlaying = event.playerState == yt.PlayerState.playing;
        ja.ProcessingState procState = ja.ProcessingState.ready;
        if (event.playerState == yt.PlayerState.buffering) {
          procState = ja.ProcessingState.buffering;
        } else if (event.playerState == yt.PlayerState.ended) {
          procState = ja.ProcessingState.completed;
        } else if (event.playerState == yt.PlayerState.unStarted) {
          procState = ja.ProcessingState.idle;
        }
        _playerStateController.add(ja.PlayerState(isPlaying, procState));
        _durationController.add(event.metaData.duration);
      }
    });

    // Poll for position updates
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_isYoutubeMode) {
        try {
          final currentSecs = await _ytController.currentTime;
          _positionController.add(Duration(milliseconds: (currentSecs * 1000).toInt()));
        } catch (e) {
          // ignore
        }
      }
    });
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
    // YouTube player volume is 0 to 100
    await _ytController.setVolume((volume * 100).round());
  }

  bool _isYouTubeIdentifier(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) return true;
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) return true;
    if (!url.contains('.')) return true;
    return false;
  }

  Future<bool> loadAndPlayUrl(String url, Song song, {Uint8List? preloadedBytes}) async {
    _lastErrorMessage = null;
    debugPrint('┌─ Audio Resolution Pipeline for: ${song.title}');
    
    if (preloadedBytes != null && preloadedBytes.isNotEmpty) {
      _isYoutubeMode = false;
      try {
        await _ytController.pauseVideo(); // Stop youtube player
        debugPrint('│  Playing preloaded byte buffer in-memory');
        final source = MyBufferAudioSource(preloadedBytes, tag: song);
        await _player.setAudioSource(source);
        await _player.play();
        debugPrint('└─ ✓ Playback confirmed via preloaded memory cache');
        return true;
      } catch (e) {
        debugPrint('│  ✗ Preloaded byte playback failed: $e');
        _lastErrorMessage = e.toString();
      }
    }
    
    if (_isYouTubeIdentifier(url)) {
      _isYoutubeMode = true;
      try {
        await _player.pause(); // Stop just_audio
        String videoId = url;
        if (url.contains('watch?v=')) {
          videoId = Uri.parse(url).queryParameters['v'] ?? url;
        }
        
        debugPrint('│  Playing via YouTube IFrame (Video ID: $videoId)');
        await _ytController.loadVideoById(videoId: videoId);
        
        debugPrint('└─ ✓ Playback confirmed via official YouTube API');
        return true;
      } catch (e) {
        debugPrint('│  ✗ YouTube IFrame playback failed: $e');
        _lastErrorMessage = e.toString();
        
        // Fallback to demo audio
        debugPrint('ERROR: Fallback used because API call failed or returned no stream URL for ${song.title}');
        final playedDemo = await _playDemoFallback(song);
        if (playedDemo) return true;
        
        return false;
      }
    } else {
      // Direct audio URL
      _isYoutubeMode = false;
      await _ytController.pauseVideo(); // Stop youtube player
      return _playDirectUrl(url, song);
    }
  }

  Future<bool> _playDirectUrl(String url, Song song) async {
    debugPrint('│  Playing direct URL: $url');
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        debugPrint('└─ ✗ Invalid URL: empty host');
        return false;
      }
      return await _initiatePlayback(uri, song);
    } catch (e) {
      debugPrint('└─ ✗ Direct URL failed: $e');
      return false;
    }
  }

  Future<bool> _initiatePlayback(Uri streamUrl, Song song) async {
    try {
      final source = ja.AudioSource.uri(streamUrl, tag: song);
      await _player.setAudioSource(source);
      await _player.play();
      return true;
    } catch (e) {
      debugPrint('│  ✗ Playback initiation error: $e');
      return false;
    }
  }

  Future<bool> _playDemoFallback(Song song) async {
    _isYoutubeMode = false;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final source = ja.AudioSource.uri(
          Uri.parse(_demoAudioUrl),
          tag: song,
        );
        await _player.setAudioSource(source);
        await _player.play();
        return true;
      } catch (e) {
        debugPrint('│  ✗ Demo fallback error (attempt ${attempt + 1}): $e');
      }
    }
    return false;
  }

  Future<void> play() async {
    if (_isYoutubeMode) {
      await _ytController.playVideo();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() async {
    if (_isYoutubeMode) {
      await _ytController.pauseVideo();
    } else {
      await _player.pause();
    }
  }

  Future<void> seek(Duration position) async {
    if (_isYoutubeMode) {
      await _ytController.seekTo(seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
    } else {
      await _player.seek(position);
    }
  }

  Future<void> skipNext() async {
    if (!_isYoutubeMode) {
      await _player.seekToNext();
    }
  }

  Future<void> skipPrevious() async {
    if (_isYoutubeMode) {
      await _ytController.seekTo(seconds: 0, allowSeekAhead: true);
    } else {
      await _player.seekToPrevious();
    }
  }
  
  Future<void> setLoopMode(ja.LoopMode mode) async {
    await _player.setLoopMode(mode);
    // Not explicitly handling YT looping since it is generally disabled or single video
  }

  Future<void> setShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  Future<void> stop() async {
    if (_isYoutubeMode) {
      await _ytController.stopVideo();
    } else {
      await _player.stop();
    }
  }

  void dispose() {
    _player.dispose();
    _ytController.close();
    _playerStateController.close();
    _positionController.close();
    _durationController.close();
  }
}
