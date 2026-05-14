import 'package:just_audio/just_audio.dart';
import '../data/music_library.dart';

/// A service that manages the low-level audio playback using [just_audio].
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  
  // A simple playlist containing all songs for demonstration
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(
    children: MusicLibrary.songs.map((song) {
      return AudioSource.uri(
        Uri.parse('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
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
      print("Error initializing playlist: $e");
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
      print("Error playing song at index $index: $e");
    }
  }

  Future<void> loadAndPlayUrl(String url, Song song) async {
    try {
      final source = AudioSource.uri(
        Uri.parse(url),
        tag: song,
      );
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      // Error is handled silently to avoid annoying logs
    }
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
  }
}
