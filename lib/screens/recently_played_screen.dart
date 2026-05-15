import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../providers/history_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/download_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/now_playing_navigator.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  State<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers = [];
  late List<Animation<double>> _scaleAnimations = [];
  late List<Animation<double>> _fadeAnimations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    final history = context.read<HistoryProvider>().history;
    for (var controller in _controllers) {
      controller.dispose();
    }
    
    _controllers = List.generate(
      history.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350 + (index * 60)),
      ),
    );
    _scaleAnimations = _controllers.map((c) {
      return Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();
    _fadeAnimations = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final history = historyProvider.history;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text("Your listening journey hasn't started yet. Let's find some beautiful music to play!", 
              style: kSubtitleTextStyle, textAlign: TextAlign.center),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, historyProvider),
          const SizedBox(height: 24),
          Text('Recently Played', style: kHeadingTextStyle),
          const SizedBox(height: 4),
          Text(
            'Your listening history',
            style: kSubtitleTextStyle,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= _controllers.length) return const SizedBox.shrink();
                return AnimatedBuilder(
                  animation: _controllers[index],
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimations[index].value,
                      child: Transform.scale(
                        scale: _scaleAnimations[index].value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildRecentItem(context, history[index], historyProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HistoryProvider historyProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TappableCard(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: kTextColor),
        ),
        Text('History', style: kTitleTextStyle),
        TappableCard(
          onTap: () => historyProvider.clearHistory(),
          child: const Icon(Icons.delete_outline, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRecentItem(BuildContext context, HistoryItem item, HistoryProvider historyProvider) {
    final song = item.song;
    final timeAgo = historyProvider.formatTimeAgo(item.playedAt);

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
          historyProvider.addToHistory(song);
          if (context.mounted) {
            NowPlayingNavigator.open(context);
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(playback.lastErrorMessage ?? "We're sorry, we couldn't play this song."),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: kCardDecoration,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
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
                      style: kTitleTextStyle.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(song.artist, style: kSubtitleTextStyle),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(song.duration,
                    style: kSubtitleTextStyle.copyWith(fontSize: 13)),
                const SizedBox(height: 4),
                Text(timeAgo,
                    style: kSubtitleTextStyle.copyWith(
                        fontSize: 11, color: kCyanColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
