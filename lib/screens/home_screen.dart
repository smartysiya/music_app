import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../widgets/smooth_page_route.dart';
import '../providers/playback_provider.dart';
import '../data/music_library.dart';
import 'now_playing_screen.dart';
import 'my_music_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTab = 'Overview';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Song> get _filteredSongs {
    if (_searchQuery.isEmpty) return MusicLibrary.songs;
    return MusicLibrary.songs.where((song) {
      return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          Text('Listening Everyday', style: kHeadingTextStyle),
          const SizedBox(height: 8),
          Text(
            'Explore millions of music according to your taste',
            style: kSubtitleTextStyle,
          ),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 24),
          _buildTabs(),
          const SizedBox(height: 24),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    switch (_selectedTab) {
      case 'Songs':
        return _buildSongsList();
      case 'Album':
        return _buildAlbumsGrid();
      case 'Artist':
        return _buildArtistsGrid();
      case 'Overview':
      default:
        return Column(
          children: [
            _buildFeaturedCards(context),
            const SizedBox(height: 24),
            _buildRecentCard(context),
          ],
        );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TappableCard(
          onTap: () {
            Navigator.push(
                context, SmoothPageRoute(page: const MyMusicScreen()));
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kCyanColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Icon(Icons.grid_view_rounded, color: kTextColor),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            TappableCard(
              onTap: () {
                Navigator.push(
                    context, SmoothPageRoute(page: const NotificationScreen()));
              },
              child: const Icon(Icons.notifications_none, color: kTextColor),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: kTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: kTextColor),
              decoration: InputDecoration(
                hintText: 'Search Music',
                hintStyle: kSubtitleTextStyle,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: kTextColor, size: 20),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    List<String> tabs = ['Overview', 'Songs', 'Album', 'Artist'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: tabs.map((tab) {
        bool isSelected = tab == _selectedTab;
        return TappableCard(
          onTap: () {
            setState(() {
              _selectedTab = tab;
              _searchQuery = '';
              _searchController.clear();
            });
          },
          child: Column(
            children: [
              Text(
                tab,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? kTextColor : kTextColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 4),
              if (isSelected)
                Container(
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kCyanColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredSongs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text('No results found for "$_searchQuery"',
              style: kSubtitleTextStyle),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSongs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: MusicLibrary.songs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final song = MusicLibrary.songs[index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongItem(Song song) {
    return GestureDetector(
      onDoubleTap: () => showSongInfoDialog(context, song),
      child: TappableCard(
        onTap: () {
          context.read<PlaybackProvider>().playSong(song);
          Navigator.push(
              context, SmoothPageRoute(page: const NowPlayingScreen()));
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: kCardDecoration,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(song.imageUrl,
                    width: 50, height: 50, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title,
                        style: kTitleTextStyle.copyWith(fontSize: 16)),
                    Text(song.artist,
                        style: kSubtitleTextStyle.copyWith(fontSize: 12)),
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
                  if (isFav) return const SizedBox(width: 12);
                  return const SizedBox.shrink();
                },
              ),
              Text(song.duration, style: kSubtitleTextStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumsGrid() {
    final albums = MusicLibrary.albums;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final imageUrl = MusicLibrary.coverForAlbum(album);
        return TappableCard(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: kCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 12),
                Text(album,
                    style: kTitleTextStyle.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text('${MusicLibrary.songsByAlbum(album).length} Songs',
                    style: kSubtitleTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistsGrid() {
    final artists = MusicLibrary.artists;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final imageUrl = MusicLibrary.coverForArtist(artist);
        return TappableCard(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: kCardDecoration,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: NetworkImage(imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(artist, style: kTitleTextStyle.copyWith(fontSize: 14)),
                Text('Artist',
                    style: kSubtitleTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TappableCard(
            onTap: () {
              context.read<PlaybackProvider>().playSong(MusicLibrary.songs[0]);
              Navigator.push(
                context,
                SmoothPageRoute(page: const NowPlayingScreen()),
              );
            },
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(MusicLibrary.songs[0].imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('20 Song',
                      style: kSubtitleTextStyle.copyWith(
                          color: kCyanColor, fontSize: 12)),
                  Text(MusicLibrary.songs[0].artist,
                      style: kTitleTextStyle.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TappableCard(
            onTap: () {
              context.read<PlaybackProvider>().playSong(MusicLibrary.songs[1]);
              Navigator.push(
                context,
                SmoothPageRoute(page: const NowPlayingScreen()),
              );
            },
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(MusicLibrary.songs[1].imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('20 Song',
                      style: kSubtitleTextStyle.copyWith(
                          color: kCyanColor, fontSize: 12)),
                  Text(MusicLibrary.songs[1].artist,
                      style: kTitleTextStyle.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCard(BuildContext context) {
    final song = MusicLibrary.songs[3];
    return TappableCard(
      onTap: () {
        context.read<PlaybackProvider>().playSong(song);
        Navigator.push(
          context,
          SmoothPageRoute(page: const NowPlayingScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDecoration,
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(song.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.artist,
                      style: kTitleTextStyle.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(song.title, style: kSubtitleTextStyle),
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
                if (isFav) return const SizedBox(width: 12);
                return const SizedBox.shrink();
              },
            ),
            Text(song.duration, style: kTitleTextStyle.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
