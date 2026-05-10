import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/custom_bottom_nav.dart';
import 'now_playing_screen.dart';
import 'my_music_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;

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
                  _buildFeaturedCards(context),
                  const SizedBox(height: 24),
                  _buildRecentCard(),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const MyMusicScreen()));
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kCyanColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorderColor, width: 1.5),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Colors.black),
          ),
        ),
        Text('Home', style: kTitleTextStyle),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorderColor, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black),
          const SizedBox(width: 12),
          Text('Search Music', style: kTitleTextStyle.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    List<String> tabs = ['Overview', 'Songs', 'Album', 'Artist'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: tabs.map((tab) {
        bool isSelected = tab == 'Overview';
        return Column(
          children: [
            Text(
              tab,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 30,
                height: 4,
                decoration: BoxDecoration(
                  color: kOrangeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
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
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500'),
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

  Widget _buildRecentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kCardDecoration,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marshmello', style: kTitleTextStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Hate the Other Side', style: kSubtitleTextStyle),
              ],
            ),
          ),
          Text('3:40', style: kTitleTextStyle.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
