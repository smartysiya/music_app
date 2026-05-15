import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../data/music_library.dart';
import '../providers/playback_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/now_playing_navigator.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final playlist = playlistProvider.getPlaylist(playlistId);

        if (playlist == null) {
          return Scaffold(
            backgroundColor: kBackgroundColor,
            body: SafeArea(
              child: Center(
                child: Text('Playlist not found', style: kSubtitleTextStyle),
              ),
            ),
          );
        }

        final songs = playlistProvider.getSongsForPlaylist(playlistId);

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
                  _buildHeader(context, playlist, songs.length),
                  const SizedBox(height: 8),
                  // Playlist Info Card
                  _buildPlaylistInfo(context, playlist, songs),
                  const SizedBox(height: 16),
                  // Songs List
                  Expanded(
                    child: songs.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: songs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildSongItem(context, songs[index], playlist.id);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, UserPlaylist playlist, int songCount) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
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
          Expanded(
            child: Column(
              children: [
                Text(playlist.name, style: kTitleTextStyle, overflow: TextOverflow.ellipsis),
                Text('$songCount songs', style: kSubtitleTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: kTextColor),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'rename') {
                _showRenameDialog(context, playlist);
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, playlist);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: kCyanColor, size: 20),
                    const SizedBox(width: 12),
                    Text('Rename', style: kTitleTextStyle.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text('Delete', style: kTitleTextStyle.copyWith(fontSize: 14, color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo(BuildContext context, UserPlaylist playlist, List<Song> songs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: kCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // Album Art Collage
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: kCyanColor.withOpacity(0.1),
              ),
              clipBehavior: Clip.antiAlias,
              child: songs.isEmpty
                  ? const Center(child: Icon(Icons.queue_music, color: kCyanColor, size: 36))
                  : songs.length < 4
                      ? Image.network(songs[0].imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white24))
                      : GridView.count(
                          crossAxisCount: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: songs.take(4).map((s) =>
                            Image.network(s.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.white10))
                          ).toList(),
                        ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name, style: kTitleTextStyle.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    '${songs.length} songs',
                    style: kSubtitleTextStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (songs.isNotEmpty)
              TappableCard(
                onTap: () async {
                  final playback = context.read<PlaybackProvider>();
                  final settings = context.read<SettingsProvider>();
                  final downloads = context.read<DownloadProvider>();

                  final success = await playback.playSong(
                    songs[0],
                    isOffline: settings.isOfflineMode,
                    isDownloaded: downloads.isDownloaded(songs[0].id),
                  );
                  if (success) {
                    context.read<HistoryProvider>().addToHistory(songs[0]);
                    NowPlayingNavigator.open(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(playback.lastErrorMessage ?? "We're sorry, we couldn't play this song."),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kCyanColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kCyanColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, color: kCyanColor.withOpacity(0.3), size: 72),
            const SizedBox(height: 16),
            Text('This playlist is currently quiet', style: kTitleTextStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Why not add some of your favorite tracks\nto bring this collection to life?',
              style: kSubtitleTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(BuildContext context, Song song, String playlistId) {
    return TappableCard(
      onTap: () async {
        final playback = context.read<PlaybackProvider>();
        final settings = context.read<SettingsProvider>();
        final downloads = context.read<DownloadProvider>();

        final success = await playback.playSong(
          song,
          isOffline: settings.isOfflineMode,
          isDownloaded: downloads.isDownloaded(song.id),
        );
        if (success) {
          context.read<HistoryProvider>().addToHistory(song);
          NowPlayingNavigator.open(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(playback.lastErrorMessage ?? "We're sorry, we couldn't play this song."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: kCardDecoration,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                song.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50, height: 50, color: Colors.white10,
                  child: const Icon(Icons.music_note, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: kTitleTextStyle.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(song.artist, style: kSubtitleTextStyle.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Text(song.duration, style: kSubtitleTextStyle.copyWith(fontSize: 12)),
            const SizedBox(width: 8),
            // Remove from playlist
            TappableCard(
              onTap: () {
                context.read<PlaylistProvider>().removeSongFromPlaylist(playlistId, song.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${song.title}" from playlist'),
                    backgroundColor: const Color(0xFF1E293B),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Icon(Icons.remove_circle_outline, color: Colors.redAccent.withOpacity(0.6), size: 22),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, UserPlaylist playlist) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Rename Playlist', style: kTitleTextStyle),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: kTextColor),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: kSubtitleTextStyle.copyWith(color: Colors.white24),
            filled: true,
            fillColor: kBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProvider>().renamePlaylist(playlist.id, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserPlaylist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            Text('Delete Playlist?', style: kTitleTextStyle),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
          style: kSubtitleTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              context.read<PlaylistProvider>().deletePlaylist(playlist.id);
              Navigator.pop(ctx);
              Navigator.pop(context); // Go back from detail screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
