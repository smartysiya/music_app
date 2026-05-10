import 'package:flutter/material.dart';
import '../constants.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Left circular background decoration
            Positioned(
              left: -150,
              top: 150,
              bottom: 150,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kCyanColor, width: 20),
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kOrangeColor, width: 10),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildHeader(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    children: [
                      _buildPlaylistItem('Happier', '04:38', 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200', true),
                      const SizedBox(height: 24),
                      _buildPlaylistItem('Sad Song', '03:24', 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=200', false, isPlaying: true),
                      const SizedBox(height: 24),
                      _buildPlaylistItem('Put Your Hands', '04:10', 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200', false),
                      const SizedBox(height: 24),
                      _buildPlaylistItem('Hate the Other Side', '03:40', 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200', false),
                    ],
                  ),
                ),
                _buildBottomPlayer(),
              ],
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
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: kOrangeButtonDecoration.copyWith(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        Text('My Playlist', style: kTitleTextStyle),
        const Icon(Icons.share_outlined, color: Colors.black),
      ],
    );
  }

  Widget _buildPlaylistItem(String title, String time, String imageUrl, bool isFirst, {bool isPlaying = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: kCardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kTitleTextStyle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(time, style: kSubtitleTextStyle),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kBorderColor, width: 1.5),
            ),
            child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorderColor, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(Icons.repeat, color: Colors.black),
          const Icon(Icons.skip_previous, color: Colors.black, size: 32),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kOrangeColor,
              shape: BoxShape.circle,
              border: Border.all(color: kBorderColor, width: 2),
            ),
            child: const Icon(Icons.pause, color: Colors.black, size: 28),
          ),
          const Icon(Icons.skip_next, color: Colors.black, size: 32),
          const Icon(Icons.shuffle, color: Colors.black),
        ],
      ),
    );
  }
}
