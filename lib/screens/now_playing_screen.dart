import 'package:flutter/material.dart';
import '../constants.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildTitleInfo(),
              const SizedBox(height: 32),
              _buildAlbumArt(),
              const SizedBox(height: 24), // Space for strings
              _buildPlayerControls(),
            ],
          ),
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
        Text('Now Playing', style: kTitleTextStyle),
        const Icon(Icons.share_outlined, color: Colors.black),
      ],
    );
  }

  Widget _buildTitleInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hate the Other Side', style: kHeadingTextStyle.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text('Marshmello', style: kSubtitleTextStyle),
          ],
        ),
        const Icon(Icons.favorite, color: Colors.redAccent),
      ],
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: kCardDecoration.copyWith(
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=800'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: kCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            // Waveform area placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('01:13', style: kSubtitleTextStyle.copyWith(color: Colors.black)),
                Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        30,
                        (index) => Container(
                          width: 3,
                          height: index % 2 == 0 ? 20 : 40 * (index % 3 + 1) / 4,
                          decoration: BoxDecoration(
                            color: index < 10 ? kCyanColor : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text('03:40', style: kSubtitleTextStyle.copyWith(color: Colors.black)),
              ],
            ),
            const Spacer(),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.repeat, color: Colors.black),
                const Icon(Icons.skip_previous, color: Colors.black, size: 32),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kOrangeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorderColor, width: 2),
                  ),
                  child: const Icon(Icons.pause, color: Colors.black, size: 32),
                ),
                const Icon(Icons.skip_next, color: Colors.black, size: 32),
                const Icon(Icons.shuffle, color: Colors.black),
              ],
            ),
            const Spacer(),
            // Volume
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Speaker', style: kTitleTextStyle.copyWith(fontSize: 14)),
                const SizedBox(width: 16),
                Container(
                  width: 100,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kCyanColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text('40%', style: kSubtitleTextStyle),
              ],
            )
          ],
        ),
      ),
    );
  }
}
