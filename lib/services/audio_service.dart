import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;
import '../data/music_library.dart';

/// Result of an audio stream resolution attempt.
class StreamResolution {
  final Uri? streamUrl;
  final String? error;
  final String method; // Which resolution method succeeded

  StreamResolution.success(this.streamUrl, this.method) : error = null;
  StreamResolution.failure(this.error, this.method) : streamUrl = null;

  bool get isSuccess => streamUrl != null;
}

/// A service that manages the low-level audio playback using [just_audio].
/// 
/// Provides a multi-tier YouTube audio stream resolution pipeline:
/// 1. Direct manifest extraction (highest quality)
/// 2. Fallback search for alternative uploads
/// 3. Demo audio fallback (ensures playback always works)
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final yte.YoutubeExplode _yt = yte.YoutubeExplode();

  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  // Retry configuration
  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(milliseconds: 800);

  // Demo audio URL for fallback when all YouTube resolution fails
  static const String _demoAudioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  // A simple playlist containing all songs for demonstration
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    children: MusicLibrary.songs.map((song) {
      return AudioSource.uri(
        Uri.parse(_demoAudioUrl),
        tag: song, // Store the song object in the tag
      );
    }).toList(),
  );

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setAudioSource(_playlist);
    } catch (e) {
      debugPrint("Error initializing playlist: $e");
    }
  }

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  Future<void> loadAndPlay(int index) async {
    try {
      if (_player.audioSource != _playlist) {
        await _player.setAudioSource(_playlist);
      }
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    } catch (e) {
      debugPrint("Error playing song at index $index: $e");
    }
  }

  /// Resolves and plays a YouTube video as audio-only.
  /// 
  /// Resolution pipeline:
  /// 1. Try direct manifest extraction with the given video ID
  /// 2. If that fails, search for an alternative upload and try those
  /// 3. If all fail, use the demo audio fallback
  /// 
  /// Returns `true` only after playback has been confirmed to start.
  Future<bool> loadAndPlayUrl(String url, Song song) async {
    _lastErrorMessage = null;
    debugPrint('┌─ Audio Resolution Pipeline for: ${song.title}');
    debugPrint('│  Input: $url');

    // Step 1: Determine if this is a YouTube ID or a direct URL
    final bool isYouTube = _isYouTubeIdentifier(url);

    if (!isYouTube) {
      // Direct URL — validate and play with retry
      return _playDirectUrl(url, song);
    }

    // Step 2: Try direct manifest resolution + play with retry
    final played = await _resolveAndPlay(url, song, 'direct');
    if (played) {
      debugPrint('└─ ✓ Playback confirmed for: ${song.title}');
      return true;
    }

    // Step 3: Fallback — search for alternative uploads, resolve + play
    debugPrint('│  Attempting fallback search...');
    final fallbackPlayed = await _fallbackResolveAndPlay(song);
    if (fallbackPlayed) {
      debugPrint('└─ ✓ Playback confirmed via fallback for: ${song.title}');
      return true;
    }

    // All genuine API tiers exhausted — do NOT play demo audio
    _lastErrorMessage ??= "We're sorry, we couldn't resolve a playable stream for this track.";
    debugPrint('└─ ✗ $_lastErrorMessage for: ${song.title}');
    return false;
  }

  /// Resolve a manifest and immediately play. If playback fails with a
  /// transient "failed to fetch" error, re-resolve the manifest (URLs expire)
  /// and retry up to [_maxRetries] times.
  Future<bool> _resolveAndPlay(String videoId, Song song, String label) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        debugPrint('│  ↻ Retry $attempt/$_maxRetries ($label) — re-resolving manifest...');
        await Future.delayed(_retryDelay * attempt);
      }

      final resolution = await _resolveFromManifest(videoId);
      if (!resolution.isSuccess) {
        final err = resolution.error ?? "Something unexpected happened. We're sorry for the interruption – please try again.";
        _lastErrorMessage = err;
        debugPrint('│  ✗ Resolution failed ($label, attempt ${attempt + 1}): $err');
        
        // If it's a timeout, don't retry - it just frustrates the user
        final lowerErr = err.toLowerCase();
        if (lowerErr.contains('timeout') || lowerErr.contains('timed out')) break;
        
        if (!_isRetryableError(err)) break;
        continue;
      }

      debugPrint('│  ✓ Resolution succeeded ($label, attempt ${attempt + 1})');

      // Immediately pass to player and initiate playback
      final playResult = await _initiatePlayback(resolution.streamUrl!, song);
      if (playResult) return true;

      // Check if the playback failure is retryable (e.g., URL expired mid-flight)
      final lastError = _lastPlaybackError;
      debugPrint('│  ✗ Playback failed ($label, attempt ${attempt + 1}): $lastError');
      if (!_isRetryableError(lastError)) break;
    }
    return false;
  }

  /// Fallback: search for alternatives and try resolve+play on each.
  Future<bool> _fallbackResolveAndPlay(Song song) async {
    try {
      final query = '${song.title} ${song.artist} audio';
      debugPrint('│  Searching for: $query');

      final results = await _yt.search
          .search(query)
          .timeout(const Duration(seconds: 7));

      int attempts = 0;
      for (final video in results) {
        if (attempts >= 3) break;
        if (video.id.value == song.id) continue;

        attempts++;
        debugPrint('│  Trying alternative: ${video.title} (${video.id.value})');

        final played = await _resolveAndPlay(video.id.value, song, 'fallback-${video.id.value}');
        if (played) return true;
      }

      debugPrint('│  ✗ No playable streams from $attempts alternatives');
      return false;
    } catch (e) {
      debugPrint('│  ✗ Fallback search error: $e');
      return false;
    }
  }

  /// Check if the input is a YouTube video ID or URL (vs. a direct audio URL).
  bool _isYouTubeIdentifier(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) return true;
    // YouTube video IDs are 11 characters, alphanumeric + dash/underscore
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) return true;
    // If it doesn't contain a dot, it's likely an ID, not a URL
    if (!url.contains('.')) return true;
    return false;
  }

  /// Try to resolve audio stream directly from a YouTube video manifest.
  Future<StreamResolution> _resolveFromManifest(String videoId) async {
    try {
      debugPrint('│  Fetching manifest for ID: $videoId');
      
      final manifest = await _yt.videos.streamsClient
          .getManifest(videoId)
          .timeout(const Duration(seconds: 5));

      final audioStreams = manifest.audioOnly.sortByBitrate();

      if (audioStreams.isEmpty) {
        return StreamResolution.failure(
          'No audio-only streams in manifest', 'manifest',
        );
      }

      // Pick highest bitrate
      final best = audioStreams.last;
      final streamUrl = best.url;

      debugPrint('│  Stream found: ${best.bitrate.kiloBitsPerSecond} kbps, '
          'codec: ${best.audioCodec}');

      // Validate the URL is well-formed
      if (streamUrl.host.isEmpty) {
        return StreamResolution.failure(
          'Resolved URL has empty host', 'manifest',
        );
      }

      return StreamResolution.success(streamUrl, 'manifest-direct');
    } catch (e) {
      String errorMessage = '$e';
      final isWebError = kIsWeb && (errorMessage.contains('XMLHttpRequest') || errorMessage.contains('ClientException'));
      
      if (isWebError) {
        return StreamResolution.failure(
          "YouTube streaming is restricted on Web due to CORS. Please try the Desktop or Mobile version for full functionality.", 
          'manifest'
        );
      }
      
      if (errorMessage.toLowerCase().contains('timeout') || errorMessage.toLowerCase().contains('timed out')) {
        return StreamResolution.failure(
          "The request timed out. If you are on Web, this may be due to browser security restrictions.", 
          'manifest',
        );
      }
      return StreamResolution.failure(errorMessage, 'manifest');
    }
  }

  /// Play a direct (non-YouTube) URL.
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

  // Tracks the last playback error for retry decisions
  String _lastPlaybackError = '';

  /// Determines if an error message indicates a transient, retryable failure.
  bool _isRetryableError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('failed to fetch') ||
        lower.contains('connection closed') ||
        lower.contains('connection reset') ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('clientexception');
  }

  /// Core playback initiation — only called after successful resolution.
  /// Sets the audio source and starts playback. Returns true only if
  /// the player actually starts playing. Stores error details in
  /// [_lastPlaybackError] for retry decision-making.
  Future<bool> _initiatePlayback(Uri streamUrl, Song song) async {
    _lastPlaybackError = '';
    try {
      debugPrint('│  → Passing stream to player: ${streamUrl.host}...');
      final source = AudioSource.uri(streamUrl, tag: song);
      await _player.setAudioSource(source);
      await _player.play();

      // Confirm the player is in a valid state
      if (_player.processingState == ProcessingState.idle) {
        _lastPlaybackError = 'Player went idle after play()';
        debugPrint('│  ⚠ $_lastPlaybackError — stream may be invalid');
        return false;
      }

      debugPrint('│  ✓ Player state: ${_player.processingState}, playing: ${_player.playing}');
      return true;
    } catch (e) {
      _lastPlaybackError = '$e';
      debugPrint('│  ✗ Playback initiation error: $e');
      return false;
    }
  }

  /// Last-resort fallback using a demo audio URL — retries on transient errors.
  Future<bool> _playDemoFallback(Song song) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      if (attempt > 0) {
        debugPrint('│  ↻ Demo retry $attempt/$_maxRetries...');
        await Future.delayed(_retryDelay * attempt);
      }
      try {
        final source = AudioSource.uri(
          Uri.parse(_demoAudioUrl),
          tag: song,
        );
        await _player.setAudioSource(source);
        await _player.play();
        return true;
      } catch (e) {
        debugPrint('│  ✗ Demo fallback error (attempt ${attempt + 1}): $e');
        if (!_isRetryableError('$e')) break;
      }
    }
    return false;
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipNext() => _player.seekToNext();
  Future<void> skipPrevious() => _player.seekToPrevious();
  
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleMode(bool enabled) => _player.setShuffleModeEnabled(enabled);

  Future<void> stop() => _player.stop();

  void dispose() {
    _player.dispose();
    _yt.close();
  }
}
