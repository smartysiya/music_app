import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import '../widgets/smooth_page_route.dart';
import 'playlist_screen.dart';
import 'lyric_screen.dart';
import 'notification_screen.dart';

class MyMusicScreen extends StatelessWidget {
  const MyMusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kBackgroundColor,
            const Color(0xFF1E293B),
            kTealColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildGrid(context),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recommended for you', style: kTitleTextStyle),
                    const Icon(Icons.arrow_forward_rounded, color: kTextColor),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRecommendedCards(context),
              ],
            ),
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
              border:
                  Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: const Icon(Icons.arrow_back, color: kTextColor),
          ),
        ),
        Text('My Music', style: kTitleTextStyle),
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

  Widget _buildGrid(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.library_music_outlined,
        'color': kCyanColor,
        'title': 'All Song'
      },
      {
        'icon': Icons.download_outlined,
        'color': kCyanColor,
        'title': 'Download'
      },
      {
        'icon': Icons.collections_outlined,
        'color': kCyanColor,
        'title': 'Collections'
      },
      {
        'icon': Icons.shopping_cart_outlined,
        'color': kOrangeColor,
        'title': 'Purchase'
      },
      {
        'icon': Icons.video_library_outlined,
        'color': kCyanColor,
        'title': 'Videos'
      },
      {'icon': Icons.lyrics_outlined, 'color': kCyanColor, 'title': 'Lyric'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return TappableCard(
            onTap: () {
              if (item['title'] == 'Lyric') {
                Navigator.push(
                    context, SmoothPageRoute(page: const LyricScreen()));
              } else {
                // Navigate to PlaylistScreen with the correct category title
                Navigator.push(
                    context,
                    SmoothPageRoute(
                        page: PlaylistScreen(title: item['title'] as String)));
              }
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (items[index]['color'] as Color).withOpacity(0.3),
                        offset: const Offset(-2, 4),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Icon(items[index]['icon'], color: kTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  items[index]['title'],
                  style: kSubtitleTextStyle.copyWith(
                      color: kTextColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TappableCard(
            onTap: () {
              Navigator.push(
                  context,
                  SmoothPageRoute(
                      page: const PlaylistScreen(title: 'Alan Walker Mix')));
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
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=500'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('20 Song',
                      style: kSubtitleTextStyle.copyWith(
                          color: kCyanColor, fontSize: 12)),
                  Text('Alan Olav Walker',
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
              Navigator.push(
                  context,
                  SmoothPageRoute(
                      page: const PlaylistScreen(title: 'Avicii Mix')));
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
                        image: const DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('20 Song',
                      style: kSubtitleTextStyle.copyWith(
                          color: kCyanColor, fontSize: 12)),
                  Text('Tim Bergling',
                      style: kTitleTextStyle.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
