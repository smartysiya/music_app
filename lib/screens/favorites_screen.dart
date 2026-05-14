import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../providers/playback_provider.dart';
import '../data/music_library.dart';
import 'now_playing_screen.dart';
import '../widgets/smooth_page_route.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _currentSort = 'Default';

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sort Favorites', style: kTitleTextStyle),
              const SizedBox(height: 24),
              _buildSortOption('Default'),
              _buildSortOption('Name (A-Z)'),
              _buildSortOption('Artist (A-Z)'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label) {
    final isSelected = _currentSort == label;
    return TappableCard(
      onTap: () {
        setState(() => _currentSort = label);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? kCyanColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kCyanColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: kTitleTextStyle.copyWith(
                fontSize: 15,
                color: isSelected ? kCyanColor : kTextColor,
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: kCyanColor, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();
    List<Song> favoriteSongs = MusicLibrary.songs.where((song) => playback.isFavorite(song.id)).toList();

    // Apply sorting
    if (_currentSort == 'Name (A-Z)') {
      favoriteSongs.sort((a, b) => a.title.compareTo(b.title));
    } else if (_currentSort == 'Artist (A-Z)') {
      favoriteSongs.sort((a, b) => a.artist.compareTo(b.artist));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          Text('Your Favorites', style: kHeadingTextStyle),
          const SizedBox(height: 4),
          Text(
            '${favoriteSongs.length} songs you love',
            style: kSubtitleTextStyle,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: favoriteSongs.isEmpty 
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100), // Space for MiniPlayer
                  itemCount: favoriteSongs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final song = favoriteSongs[index];
                    return _buildFavoriteItem(context, song, playback);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: kTextColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No favorites yet', style: kTitleTextStyle.copyWith(color: kTextColor.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Songs you heart will appear here', style: kSubtitleTextStyle),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 24), // Placeholder to keep title centered
        Text('Favorites', style: kTitleTextStyle),
        IconButton(
          onPressed: _showSortDialog,
          icon: const Icon(Icons.sort, color: kTextColor),
        ),
      ],
    );
  }

  Widget _buildFavoriteItem(BuildContext context, Song song, PlaybackProvider playback) {
    return TappableCard(
      onTap: () {
        playback.playSong(song);
        Navigator.push(context, SmoothPageRoute(page: const NowPlayingScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: kCardDecoration,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(song.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title, style: kTitleTextStyle.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(song.artist, style: kSubtitleTextStyle),
                ],
              ),
            ),
            Text(song.duration, style: kSubtitleTextStyle.copyWith(fontSize: 13)),
            const SizedBox(width: 12),
            TappableCard(
              onTap: () => playback.toggleFavorite(song.id),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.15),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
