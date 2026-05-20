import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../widgets/smooth_page_route.dart';
import '../providers/playback_provider.dart';
import '../data/music_library.dart';
import '../services/youtube_service.dart';
import 'my_music_screen.dart';
import 'notification_screen.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import '../providers/playlist_provider.dart';
import 'playlist_detail_screen.dart';
import '../widgets/now_playing_navigator.dart';

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
        results = MusicLibrary.songs.take(10).toList();
      } else if (tab == 'Songs') {
        results = MusicLibrary.songs;
      } else if (tab == 'Albums') {
        results = MusicLibrary.songs;
      } else if (tab == 'Artists') {
        results = MusicLibrary.songs;
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
    if (mounted) {
      setState(() {
        _tabResults = MusicLibrary.songs.where((s) => s.album == album.album).toList();
        _selectedTab = 'Songs';
        _isLoadingTab = false;
      });
    }
  }

  Future<void> _onArtistTap(Song artist) async {
    setState(() => _isLoadingTab = true);
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
    final results = await _youtubeService.searchSongs(query);
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
          Text('Listening Every Day', style: kHeadingTextStyle),
          const SizedBox(height: 8),
          Text(
            'Explore millions of songs tailored to your taste',
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
      case 'Albums':
        return _buildAlbumsGrid();
      case 'Artists':
        return _buildArtistsGrid();
      case 'Overview':
      default:
        return Column(
          children: [
            if (context.watch<PlaylistProvider>().playlists.isNotEmpty) ...[
              _buildPlaylistsSection(context),
              const SizedBox(height: 24),
            ],
            _buildFeaturedCards(context),
            const SizedBox(height: 24),
            _buildRecentCard(context),
            const SizedBox(height: 24),
            _buildSectionHeader('Trending Songs', () {
              setState(() => _selectedTab = 'Songs');
            }),
            const SizedBox(height: 16),
            _buildSongsList(),
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
    List<String> tabs = ['Overview', 'Songs', 'Albums', 'Artists'];
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
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text("We couldn't find any matches for \"$_searchQuery\". Maybe try a different keyword or check the spelling?",
                style: kSubtitleTextStyle, textAlign: TextAlign.center),
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
      onLongPress: () => _showAddToPlaylistDialog(context, song),
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
              NowPlayingNavigator.open(context);
            }
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
              Consumer<PlaybackProvider>(
                builder: (context, playback, _) {
                  if (playback.loadingSongId == song.id) {
                    return const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kCyanColor),
                    );
                  }
                  return Text(song.duration, style: kSubtitleTextStyle);
                },
              ),
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
                      imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=200&auto=format&fit=crop',
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
    final song = MusicLibrary.songs[1];
    return TappableCard(
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
            NowPlayingNavigator.open(context);
          }
        }
      },
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: kCardDecoration,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(song.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (song.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kCyanColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('LIVE',
                          style: kSubtitleTextStyle.copyWith(
                              color: kCyanColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(song.title,
                      style: kTitleTextStyle.copyWith(fontSize: 18)),
                  Text(song.artist,
                      style: kSubtitleTextStyle.copyWith(fontSize: 14)),
                  const SizedBox(height: 16),
                  Consumer<PlaybackProvider>(
                    builder: (context, playback, _) {
                      if (playback.loadingSongId == song.id) {
                        return const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(color: kCyanColor),
                        );
                      }
                      return const Icon(Icons.play_circle_fill, color: kCyanColor, size: 32);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: kTitleTextStyle),
        TappableCard(
          onTap: onTap,
          child: Text('See All', style: kSubtitleTextStyle.copyWith(color: kCyanColor)),
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
                  NowPlayingNavigator.open(context);
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
                        Consumer<PlaybackProvider>(
                          builder: (context, playback, _) {
                            if (playback.loadingSongId == song.id) {
                              return const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: kCyanColor),
                              );
                            }
                            return Text(song.duration, style: kSubtitleTextStyle.copyWith(fontSize: 12));
                          },
                        ),
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

  Widget _buildPlaylistsSection(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final playlists = playlistProvider.playlists;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Playlists', style: kTitleTextStyle),
                TappableCard(
                  onTap: () => _showCreatePlaylistDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kCyanColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kCyanColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, color: kCyanColor, size: 18),
                        const SizedBox(width: 6),
                        Text('New', style: kSubtitleTextStyle.copyWith(color: kCyanColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (playlists.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: kCardDecoration,
                child: Column(
                  children: [
                    Icon(Icons.queue_music, color: kCyanColor.withOpacity(0.3), size: 40),
                    const SizedBox(height: 12),
                    Text("You haven't created any playlists yet. Start building your own musical collections!", 
                        style: kSubtitleTextStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Tap "+ New" to create one', style: kSubtitleTextStyle.copyWith(fontSize: 11)),
                  ],
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: playlists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    final songs = playlistProvider.getSongsForPlaylist(playlist.id);
                    return TappableCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: PlaylistDetailScreen(playlistId: playlist.id)),
                        );
                      },
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: kCardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: kCyanColor.withOpacity(0.08),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: songs.isEmpty
                                    ? const Center(child: Icon(Icons.queue_music, color: kCyanColor, size: 32))
                                    : Image.network(songs[0].imageUrl, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.music_note, color: Colors.white24, size: 32),
                                        )),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              playlist.name,
                              style: kTitleTextStyle.copyWith(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${songs.length} songs',
                              style: kSubtitleTextStyle.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Create Playlist', style: kTitleTextStyle),
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
            onPressed: () async {
              final playlist = await context.read<PlaylistProvider>().createPlaylist(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playlist "${playlist.name}" created!'),
                  backgroundColor: const Color(0xFF1E293B),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Create', style: TextStyle(color: kCyanColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    final playlistProvider = context.read<PlaylistProvider>();
    final playlists = playlistProvider.playlists;

    if (playlists.isEmpty) {
      _showCreatePlaylistDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add to Playlist', style: kTitleTextStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...playlists.map((playlist) {
              final alreadyAdded = playlist.songIds.contains(song.id);
              return TappableCard(
                onTap: alreadyAdded
                    ? null
                    : () {
                        playlistProvider.addSongToPlaylist(playlist.id, song.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${song.title}" to ${playlist.name}'),
                            backgroundColor: const Color(0xFF1E293B),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: alreadyAdded
                        ? Colors.white.withOpacity(0.03)
                        : kCyanColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: alreadyAdded
                          ? Colors.white.withOpacity(0.05)
                          : kCyanColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.queue_music, color: alreadyAdded ? Colors.white24 : kCyanColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          playlist.name,
                          style: kTitleTextStyle.copyWith(
                            fontSize: 14,
                            color: alreadyAdded ? Colors.white38 : kTextColor,
                          ),
                        ),
                      ),
                      if (alreadyAdded)
                        const Icon(Icons.check, color: Colors.white24, size: 18)
                      else
                        const Icon(Icons.add, color: kCyanColor, size: 18),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            TappableCard(
              onTap: () {
                Navigator.pop(ctx);
                _showCreatePlaylistDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kOrangeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kOrangeColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: kOrangeColor, size: 22),
                    const SizedBox(width: 12),
                    Text('Create new playlist', style: kTitleTextStyle.copyWith(fontSize: 14, color: kOrangeColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
