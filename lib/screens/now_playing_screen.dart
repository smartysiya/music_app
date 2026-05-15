import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/music_library.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../providers/playback_provider.dart';
import 'package:just_audio/just_audio.dart';
import '../providers/feature_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/player/vibrant_player.dart';
import '../widgets/player/minimalist_player.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showUnlockShareDialog(BuildContext context, dynamic song) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: kCyanColor),
              const SizedBox(width: 12),
              Text('Premium Sharing', style: kTitleTextStyle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the safe word to unlock cross-platform sharing.',
                style: kSubtitleTextStyle,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: kTextColor),
                decoration: InputDecoration(
                  hintText: 'Safe Word',
                  hintStyle: kSubtitleTextStyle.copyWith(color: Colors.white24),
                  filled: true,
                  fillColor: kBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().toLowerCase() == 'potato') {
                  Navigator.pop(context);
                  context.read<FeatureProvider>().unlockEverything();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sharing Unlocked! Click share again.')),
                  );
                  _shareSong(song);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incorrect safe word!')),
                  );
                }
              },
              child: const Text('Unlock', style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _shareSong(dynamic song) {
    final String shareText = "Listening to '${song.title}' by ${song.artist} on MELME! 🎵\n\n"
        "${song.album == 'YouTube' ? 'Check it out here: https://youtu.be/${song.id}' : 'Stream it on MELME!'}";
    
    Share.share(shareText, subject: 'Share Song');
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();
    final song = playback.currentSong;
    final featureProvider = context.watch<FeatureProvider>();

    if (song == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text("No music is playing at the moment. Pick a song and let the rhythm take over!", 
                style: kSubtitleTextStyle, textAlign: TextAlign.center),
          ),
        )
      );
    }

    final settings = context.watch<SettingsProvider>();
    
    if (settings.playerTheme == 'vibrant') {
      return VibrantPlayer(song: song, playback: playback);
    } else if (settings.playerTheme == 'minimalist') {
      return MinimalistPlayer(song: song, playback: playback);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.8), // Vivid Blue
            kBackgroundColor,
            kTealColor.withOpacity(0.4), // Peaceful Teal
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, featureProvider, playback, song),
                  const SizedBox(height: 32),
                  _buildTitleInfo(song),
                  const SizedBox(height: 32),
                  _buildAlbumArt(song, playback),
                  const SizedBox(height: 24),
                  _buildPlayerControls(context, playback),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FeatureProvider featureProvider, PlaybackProvider playback, dynamic song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TappableCard(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kOrangeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Icon(Icons.arrow_back, color: kTextColor),
          ),
        ),
        Text('Now Playing', style: kTitleTextStyle),
        TappableCard(
          onTap: () => featureProvider.isPremiumUnlocked 
              ? _shareSong(song) 
              : _showUnlockShareDialog(context, song),
          child: const Icon(Icons.share_outlined, color: kTextColor),
        ),
      ],
    );
  }

  Widget _buildTitleInfo(dynamic song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title, style: kHeadingTextStyle.copyWith(fontSize: 24), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(song.artist, style: kSubtitleTextStyle),
            ],
          ),
        ),
        Consumer<PlaybackProvider>(
          builder: (context, playback, _) {
            final isFav = playback.isFavorite(song.id);
            return TappableCard(
              onTap: () => playback.toggleFavorite(song.id),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.redAccent : kTextColor.withOpacity(0.4),
                size: 24,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumArt(dynamic song, PlaybackProvider playback) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: kCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background/Base image
          Image.network(
            song.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.music_note, color: Colors.white24, size: 64),
            ),
          ),
          
          // Glass overlay for Audio mode
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Hero(
                  tag: 'album_art_${song.id}',
                  child: Container(
                    height: 220,
                    width: 220,
                    decoration: kCardDecoration.copyWith(
                      image: DecorationImage(
                        image: NetworkImage(song.imageUrl),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(BuildContext context, PlaybackProvider playback) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: kCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(playback.position), style: kSubtitleTextStyle.copyWith(color: kTextColor)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: kCyanColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: kCyanColor,
                    ),
                    child: Slider(
                      value: _dragValue ?? playback.position.inSeconds.toDouble(),
                      max: playback.duration.inSeconds.toDouble() > 0 
                          ? playback.duration.inSeconds.toDouble() 
                          : 1.0,
                      onChanged: (value) {
                        setState(() {
                          _dragValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        playback.seek(Duration(seconds: value.toInt()));
                        setState(() {
                          _dragValue = null;
                        });
                      },
                    ),
                  ),
                ),
                Text(_formatDuration(playback.duration), style: kSubtitleTextStyle.copyWith(color: kTextColor)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TappableCard(
                  onTap: () => playback.toggleLoopMode(),
                  child: Icon(
                    playback.loopMode == LoopMode.one 
                        ? Icons.repeat_one 
                        : Icons.repeat, 
                    color: playback.loopMode != LoopMode.off ? kCyanColor : kTextColor,
                    size: 24,
                  ),
                ),
                TappableCard(
                  onTap: () => playback.skipPrevious(),
                  child: const Icon(Icons.skip_previous, color: kTextColor, size: 32),
                ),
                TappableCard(
                  onTap: () {
                    if (playback.isPlaying) {
                      playback.pause();
                    } else {
                      playback.resume();
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kCyanColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kCyanColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Icon(
                      playback.isPlaying ? Icons.pause : Icons.play_arrow, 
                      color: Colors.white, 
                      size: 32
                    ),
                  ),
                ),
                TappableCard(
                  onTap: () => playback.skipNext(),
                  child: const Icon(Icons.skip_next, color: kTextColor, size: 32),
                ),
                TappableCard(
                  onTap: () => playback.toggleShuffle(),
                  child: Icon(
                    Icons.shuffle, 
                    color: playback.isShuffleEnabled ? kCyanColor : kTextColor,
                    size: 24,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Speaker', style: kTitleTextStyle.copyWith(fontSize: 14)),
                const SizedBox(width: 16),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: SliderComponentShape.noThumb, 
                      overlayShape: SliderComponentShape.noOverlay,
                      activeTrackColor: kCyanColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: playback.volume,
                      onChanged: (value) {
                        playback.setVolume(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(playback.volume * 100).toInt()}%',
                    style: kSubtitleTextStyle.copyWith(color: kTextColor),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
