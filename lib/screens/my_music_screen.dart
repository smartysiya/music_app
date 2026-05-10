import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_bottom_nav.dart';
import 'playlist_screen.dart';
import 'lyric_screen.dart';

class MyMusicScreen extends StatefulWidget {
  const MyMusicScreen({super.key});

  @override
  State<MyMusicScreen> createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  int _bottomNavIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildGrid(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recommended for you', style: kTitleTextStyle),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.black),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendedCards(),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNav(
                currentIndex: _bottomNavIndex,
                onTap: (index) {
                  setState(() => _bottomNavIndex = index);
                  if (index == 0) {
                     Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
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
          child: const Icon(Icons.grid_view_rounded, color: Colors.black),
        ),
        Text('My Music', style: kTitleTextStyle),
        Row(
          children: [
            const Icon(Icons.notifications_none, color: Colors.black),
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

  Widget _buildGrid() {
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.location_on_outlined, 'color': kCyanColor, 'title': 'All Song'},
      {'icon': Icons.download_outlined, 'color': kCyanColor, 'title': 'Download'},
      {'icon': Icons.collections_outlined, 'color': kCyanColor, 'title': 'Collections'},
      {'icon': Icons.shopping_cart_outlined, 'color': kOrangeColor, 'title': 'Purchase'},
      {'icon': Icons.video_library_outlined, 'color': kCyanColor, 'title': 'Videos'},
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
          return GestureDetector(
            onTap: () {
              if (items[index]['title'] == 'Lyric') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LyricScreen()));
              }
            },
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: items[index]['color'].withOpacity(0.5),
                        offset: const Offset(-2, 4),
                        blurRadius: 0,
                      )
                    ]
                  ),
                  child: Icon(items[index]['icon'], color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  items[index]['title'],
                  style: kSubtitleTextStyle.copyWith(color: Colors.black, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaylistScreen()));
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
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=500'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('20 Song', style: kSubtitleTextStyle.copyWith(color: kOrangeColor, fontSize: 12)),
                  Text('Alan Olav Walker', style: kTitleTextStyle.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
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
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('20 Song', style: kSubtitleTextStyle.copyWith(color: kOrangeColor, fontSize: 12)),
                Text('Tim Bergling', style: kTitleTextStyle.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
