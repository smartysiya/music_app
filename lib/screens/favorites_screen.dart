import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final List<Map<String, String>> _favorites = [
    {
      'title': 'Faded',
      'artist': 'Alan Walker',
      'duration': '3:32',
      'image': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=200',
    },
    {
      'title': 'Alone',
      'artist': 'Alan Walker',
      'duration': '2:57',
      'image': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200',
    },
    {
      'title': 'Happier',
      'artist': 'Marshmello',
      'duration': '4:38',
      'image': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200',
    },
    {
      'title': 'Levels',
      'artist': 'Avicii',
      'duration': '3:18',
      'image': 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200',
    },
    {
      'title': 'Titanium',
      'artist': 'David Guetta',
      'duration': '4:05',
      'image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200',
    },
    {
      'title': 'Wake Me Up',
      'artist': 'Avicii',
      'duration': '4:07',
      'image': 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=200',
    },
  ];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _favorites.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 80)),
      ),
    );
    _scaleAnimations = _controllers.map((c) {
      return Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOutBack),
      );
    }).toList();
    _fadeAnimations = _controllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeOut),
      );
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 60), () {
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
          Text('Your Favorites', style: kHeadingTextStyle),
          const SizedBox(height: 4),
          Text(
            '${_favorites.length} songs you love',
            style: kSubtitleTextStyle,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _favorites.length,
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
                  child: _buildFavoriteItem(_favorites[index]),
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
            color: Colors.redAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor, width: 1.5),
          ),
          child: const Icon(Icons.favorite, color: Colors.redAccent),
        ),
        Text('Favorites', style: kTitleTextStyle),
        Row(
          children: [
            const Icon(Icons.sort, color: Colors.black),
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

  Widget _buildFavoriteItem(Map<String, String> song) {
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
            Text(song['duration']!,
                style: kSubtitleTextStyle.copyWith(fontSize: 13)),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.1),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Icon(Icons.favorite,
                  color: Colors.redAccent, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
