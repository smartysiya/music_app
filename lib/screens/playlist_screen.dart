import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../data/music_library.dart';
import '../providers/playback_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/now_playing_navigator.dart';

class PlaylistScreen extends StatelessWidget {
  final String title;
  const PlaylistScreen({super.key, this.title = 'My Playlist'});

  @override
  Widget build(BuildContext context) {
    final songs = MusicLibrary.songs;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.8),
            kBackgroundColor,
            kTealColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildHeader(context),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: songs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return _buildPlaylistItem(context, song);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
        Text(title, style: kTitleTextStyle),
        const Icon(Icons.share_outlined, color: kTextColor),
      ],
    );
  }

  Widget _buildPlaylistItem(BuildContext context, Song song) {
    final playback = context.watch<PlaybackProvider>();
    final isCurrentSong = playback.currentSong?.id == song.id;

    return GestureDetector(
      onDoubleTap: () => showSongInfoDialog(context, song),
      child: TappableCard(
        onTap: () async {
          final settings = context.read<SettingsProvider>();
          final downloads = context.read<DownloadProvider>();
          
          bool success = await playback.playSong(
            song,
            isOffline: settings.isOfflineMode,
            isDownloaded: downloads.isDownloaded(song.id),
          );

          if (success) {
            context.read<HistoryProvider>().addToHistory(song);
            NowPlayingNavigator.open(context);
          } else {
            final isInLibrary = MusicLibrary.songs.any((s) => s.id == song.id);
            String message = playback.lastErrorMessage ?? 
                ((settings.isOfflineMode && isInLibrary) 
                    ? "We're sorry, this song is not available offline." 
                    : "We're sorry, we couldn't stream this song. Please check your connection.");
                
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: kCardDecoration.copyWith(
            border: isCurrentSong 
                ? Border.all(color: kCyanColor.withOpacity(0.5), width: 1.5)
                : Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  song.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.white10,
                    child: const Icon(Icons.music_note, color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title, 
                      style: kTitleTextStyle.copyWith(
                        fontSize: 16,
                        color: isCurrentSong ? kCyanColor : kTextColor,
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(song.artist, style: kSubtitleTextStyle),
                  ],
                ),
              ),
              Consumer<PlaybackProvider>(
                builder: (context, playback, _) {
                  final isFav = playback.isFavorite(song.id);
                  if (!isFav) return const SizedBox.shrink();
                  return TappableCard(
                    onTap: () => playback.toggleFavorite(song.id),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  );
                },
              ),
              Consumer<PlaybackProvider>(
                builder: (context, playback, _) {
                  final isFav = playback.isFavorite(song.id);
                  if (isFav) return const SizedBox(width: 16);
                  return const SizedBox.shrink();
                },
              ),
              Consumer<DownloadProvider>(
                builder: (context, downloads, _) {
                  if (downloads.isDownloaded(song.id)) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Icon(Icons.download_done, color: kCyanColor.withOpacity(0.5), size: 16),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrentSong ? kCyanColor : Colors.white.withOpacity(0.05),
                ),
                child: Icon(
                  isCurrentSong && playback.isPlaying ? Icons.pause : Icons.play_arrow, 
                  color: isCurrentSong ? Colors.white : kTextColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
