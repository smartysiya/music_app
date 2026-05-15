import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../providers/playback_provider.dart';
import '../../data/music_library.dart';
import 'dart:math' as math;

class VibrantPlayer extends StatelessWidget {
  final Song song;
  final PlaybackProvider playback;

  const VibrantPlayer({
    super.key,
    required this.song,
    required this.playback,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kVibrantYellowColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Mix',
                        style: kHeadingTextStyle.copyWith(color: Colors.black, fontSize: 32),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 32),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Speaker Pattern
            Center(
              child: CustomPaint(
                painter: SpeakerPatternPainter(),
                size: const Size(280, 280),
              ),
            ),
            const Spacer(),
            // Song Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.graphic_eq, color: Colors.black, size: 24),
                  const Icon(Icons.bookmark_border, color: Colors.black, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Control Wheel
            _buildControlWheel(),
            const SizedBox(height: 40),
            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.volume_up, color: Colors.black, size: 20),
                  const Icon(Icons.music_note, color: Colors.black, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlWheel() {
    return Container(
      width: 250,
      height: 250,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // Center Play/Pause button
          Center(
            child: GestureDetector(
              onTap: () {
                if (playback.isPlaying) {
                  playback.pause();
                } else {
                  playback.resume();
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: kVibrantYellowColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playback.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 40,
                ),
              ),
            ),
          ),
          // Navigation Icons
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Icon(Icons.menu, color: kVibrantYellowColor.withOpacity(0.8), size: 24),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => playback.toggleShuffle(),
              child: Icon(
                Icons.shuffle,
                color: playback.isShuffleEnabled ? kVibrantYellowColor : kVibrantYellowColor.withOpacity(0.5),
                size: 24,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => playback.skipPrevious(),
              child: const Icon(Icons.fast_rewind, color: kVibrantYellowColor, size: 32),
            ),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => playback.skipNext(),
              child: const Icon(Icons.fast_forward, color: kVibrantYellowColor, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class SpeakerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const double maxRadius = 130;
    const int rings = 8;
    const double dotRadius = 4;

    for (int i = 1; i <= rings; i++) {
      double ringRadius = (maxRadius / rings) * i;
      int dotsCount = (i * 8);
      for (int j = 0; j < dotsCount; j++) {
        double angle = (j / dotsCount) * 2 * math.pi;
        double x = center.dx + ringRadius * math.cos(angle);
        double y = center.dy + ringRadius * math.sin(angle);
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
    
    // Draw center circle
    canvas.drawCircle(center, 15, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
