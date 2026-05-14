import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../widgets/smooth_page_route.dart';
import '../providers/playback_provider.dart';
import '../data/music_library.dart';
import '../services/youtube_service.dart';
import 'now_playing_screen.dart';
import 'my_music_screen.dart';
import 'notification_screen.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../services/lastfm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTab = 'Overview';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadTabData('Overview');
  }
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService();
  final LastFmService _lastFmService = LastFmService();
  List<Song> _youtubeResults = [];
  List<Song> _tabResults = [];
  bool _isSearching = false;
  bool _isLoadingTab = false;
  Timer? _debounce;

  List<Song> get _filteredSongs {
    if (_searchQuery.isEmpty) return MusicLibrary.songs;
    return MusicLibrary.songs.where((song) {
      return song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _loadTabData(String tab) async {
    setState(() => _isLoadingTab = true);
    List<Song> results = [];
    
    try {
      if (tab == 'Overview') {
        results = await _lastFmService.getTopTracks();
      } else if (tab == 'Songs') {
        results = await _lastFmService.getTopTracks(); // Or a specific chart
      } else if (tab == 'Album') {
        results = await _lastFmService.searchAlbums('Top hits 2024');
      } else if (tab == 'Artist') {
        results = await _lastFmService.getTopArtists();
      }
    } catch (e) {
      debugPrint('Error loading tab data: $e');
    }
    
    if (mounted) {
      setState(() {
        _tabResults = results;
        _isLoadingTab = false;
      });
    }
  }

  Future<void> _onAlbumTap(Song album) async {
    setState(() => _isLoadingTab = true);
    final tracks = await _lastFmService.getAlbumTracks(album.artist, album.title);
    if (mounted) {
      setState(() {
        // Carry over the album art to tracks since Last.fm track info often lacks it
        _tabResults = tracks.map((t) => t.copyWith(imageUrl: album.imageUrl)).toList();
        _selectedTab = 'Songs';
        _isLoadingTab = false;
      });
    }
  }

  Future<void> _onArtistTap(Song artist) async {
    setState(() => _isLoadingTab = true);
    // Search for the artist's top songs on YouTube
    final results = await _youtubeService.searchSongs('${artist.title} top songs');
    if (mounted) {
      setState(() {
        _tabResults = results;
        _selectedTab = 'Songs';
        _isLoadingTab = false;
      });
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _youtubeResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _lastFmService.searchTracks(query);
    if (mounted) {
      setState(() {
        _youtubeResults = results;
        _isSearching = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query;
      _searchSongs(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _youtubeService.dispose();
    _debounce?.cancel();
    super.dispose();
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

    if (_isLoadingTab) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(color: kCyanColor),
        ),
      );
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
              onChanged: _onSearchChanged,
              style: const TextStyle(color: kTextColor),
              decoration: InputDecoration(
                hintText: 'Search Music',
                hintStyle: kSubtitleTextStyle,
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: kCyanColor),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: kTextColor, size: 20),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _youtubeResults = [];
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
            _loadTabData(tab);
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
    if (_filteredSongs.isEmpty && _youtubeResults.isEmpty && !_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text('No results found for "$_searchQuery"',
              style: kSubtitleTextStyle),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_filteredSongs.isNotEmpty) ...[
          ..._filteredSongs.map((song) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSongItem(song),
          )),
          const SizedBox(height: 12),
        ],
        if (_youtubeResults.isNotEmpty) ...[
          ..._youtubeResults.map((song) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSongItem(song),
          )),
        ],
      ],
    );
  }

  Widget _buildSongsList() {
    final songs = _tabResults.isEmpty ? MusicLibrary.songs : _tabResults;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: songs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongItem(Song song) {
    return GestureDetector(
      onDoubleTap: () => showSongInfoDialog(context, song),
      child: TappableCard(
        onTap: () async {
          final settings = context.read<SettingsProvider>();
          final downloads = context.read<DownloadProvider>();
          final playback = context.read<PlaybackProvider>();
          
          bool success = await playback.playSong(
            song,
            isOffline: settings.isOfflineMode,
            isDownloaded: downloads.isDownloaded(song.id),
          );

          if (success) {
            if (mounted) {
              context.read<HistoryProvider>().addToHistory(song);
            }
            Navigator.push(
                context, SmoothPageRoute(page: const NowPlayingScreen()));
          } else {
            final isInLibrary = MusicLibrary.songs.any((s) => s.id == song.id);
            String message = (settings.isOfflineMode && isInLibrary) 
                ? 'This song is not available offline.' 
                : 'Failed to stream song. Please check your connection.';
                
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
          decoration: kCardDecoration,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
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
    final List<Song> sourceSongs = _tabResults.isEmpty ? MusicLibrary.songs : _tabResults;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: sourceSongs.length,
      itemBuilder: (context, index) {
        final song = sourceSongs[index];
        final album = song.album;
        final imageUrl = song.imageUrl;
        return TappableCard(
          onTap: () => _onAlbumTap(song),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: kCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.album, color: Colors.white24, size: 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(album,
                    style: kTitleTextStyle.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(song.artist,
                    style: kSubtitleTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistsGrid() {
    final sourceSongs = _tabResults.isEmpty ? MusicLibrary.songs : _tabResults;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: sourceSongs.length,
      itemBuilder: (context, index) {
        final song = sourceSongs[index];
        final artist = song.artist;
        final imageUrl = song.imageUrl;
        return TappableCard(
          onTap: () => _onArtistTap(song),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: kCardDecoration,
            child: Column(
              children: [
                Expanded(
                  child: ClipOval(
                    child: Image.network(
                      imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=200&auto=format&fit=crop', // Fallback for artists
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.person, color: Colors.white24, size: 48),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(artist, 
                    style: kTitleTextStyle.copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
            onTap: () async {
              final song = MusicLibrary.songs[0];
              final settings = context.read<SettingsProvider>();
              final downloads = context.read<DownloadProvider>();
              final playback = context.read<PlaybackProvider>();
              
              bool success = await playback.playSong(
                song,
                isOffline: settings.isOfflineMode,
                isDownloaded: downloads.isDownloaded(song.id),
              );

              if (success) {
                if (mounted) {
                  context.read<HistoryProvider>().addToHistory(song);
                }
                Navigator.push(
                  context,
                  SmoothPageRoute(page: const NowPlayingScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This song is not available offline.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: kCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _tabResults.isNotEmpty ? _tabResults[0].imageUrl : MusicLibrary.songs[0].imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.star, color: Colors.white24, size: 48),
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
            onTap: () async {
              final song = MusicLibrary.songs[1];
              final settings = context.read<SettingsProvider>();
              final downloads = context.read<DownloadProvider>();
              final playback = context.read<PlaybackProvider>();
              
              bool success = await playback.playSong(
                song,
                isOffline: settings.isOfflineMode,
                isDownloaded: downloads.isDownloaded(song.id),
              );

              if (success) {
                Navigator.push(
                  context,
                  SmoothPageRoute(page: const NowPlayingScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This song is not available offline.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
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
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, _) {
        final history = historyProvider.history;
        if (history.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final lastItem = history.first;
        final song = lastItem.song;
        final timeAgo = historyProvider.formatTimeAgo(lastItem.playedAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recently Played', style: kTitleTextStyle),
                TappableCard(
                  onTap: () {
                    // Navigate to history if needed
                  },
                  child: Text('See All', style: kSubtitleTextStyle.copyWith(color: kCyanColor)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TappableCard(
              onTap: () async {
                final settings = context.read<SettingsProvider>();
                final downloads = context.read<DownloadProvider>();
                final playback = context.read<PlaybackProvider>();
                
                bool success = await playback.playSong(
                  song,
                  isOffline: settings.isOfflineMode,
                  isDownloaded: downloads.isDownloaded(song.id),
                );

                if (success) {
                  Navigator.push(
                    context,
                    SmoothPageRoute(page: const NowPlayingScreen()),
                  );
                }
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
                          Text(song.title,
                              style: kTitleTextStyle.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(song.artist, style: kSubtitleTextStyle),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(song.duration, style: kSubtitleTextStyle.copyWith(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(timeAgo, style: kSubtitleTextStyle.copyWith(fontSize: 11, color: kCyanColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
