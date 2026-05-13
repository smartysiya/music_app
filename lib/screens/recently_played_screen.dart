import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';

class RecentlyPlayedScreen extends StatefulWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  State<RecentlyPlayedScreen> createState() => _RecentlyPlayedScreenState();
}

class _RecentlyPlayedScreenState extends State<RecentlyPlayedScreen>
    with TickerProviderStateMixin {
  final List<Map<String, String>> _recentSongs = [
    {
      'title': 'Hate the Other Side',
      'artist': 'Marshmello',
      'duration': '3:40',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200',
      'time': '2 min ago',
    },
    {
      'title': 'The Spectre',
      'artist': 'Alan Walker',
      'duration': '3:15',
      'image': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=200',
      'time': '15 min ago',
    },
    {
      'title': 'Sad Song',
      'artist': 'Marshmello',
      'duration': '3:24',
      'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200',
      'time': '1 hr ago',
    },
    {
      'title': 'Without You',
      'artist': 'Avicii',
      'duration': '3:46',
      'image': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200',
      'time': '2 hrs ago',
    },
    {
      'title': 'Put Your Hands Up',
      'artist': 'Marshmello',
      'duration': '4:10',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200',
      'time': '3 hrs ago',
    },
    {
      'title': 'Faded',
      'artist': 'Alan Walker',
      'duration': '3:32',
      'image': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=200',
      'time': 'Yesterday',
    },
    {
      'title': 'Levels',
      'artist': 'Avicii',
      'duration': '3:18',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200',
      'time': 'Yesterday',
    },
  ];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _recentSongs.length,
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
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
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
              itemCount: _recentSongs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
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
                  child: _buildRecentItem(_recentSongs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kCyanColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor, width: 1.5),
          ),
          child: const Icon(Icons.history, color: Colors.black),
        ),
        Text('History', style: kTitleTextStyle),
        Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.black),
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kBorderColor, width: 1.5),
                image: const DecorationImage(
                  image: NetworkImage('https://i.pravatar.cc/150?img=32'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRecentItem(Map<String, String> song) {
    return TappableCard(
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
                  image: NetworkImage(song['image']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song['title']!,
                      style: kTitleTextStyle.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(song['artist']!, style: kSubtitleTextStyle),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(song['duration']!,
                    style: kSubtitleTextStyle.copyWith(fontSize: 13)),
                const SizedBox(height: 4),
                Text(song['time']!,
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
