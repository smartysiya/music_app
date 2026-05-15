import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../providers/playback_provider.dart';
import '../../data/music_library.dart';
import 'dart:math' as math;

class MinimalistPlayer extends StatefulWidget {
  final Song song;
  final PlaybackProvider playback;

  const MinimalistPlayer({
    super.key,
    required this.song,
    required this.playback,
  });

  @override
  State<MinimalistPlayer> createState() => _MinimalistPlayerState();
}

class _MinimalistPlayerState extends State<MinimalistPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _reelController;

  @override
  void initState() {
    super.initState();
    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.playback.isPlaying) {
      _reelController.repeat();
    }
  }

  @override
  void didUpdateWidget(MinimalistPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playback.isPlaying) {
      _reelController.repeat();
    } else {
      _reelController.stop();
    }
  }

  @override
  void dispose() {
    _reelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMinimalistBeigeColor,
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
                        'Organic',
                        style: kHeadingTextStyle.copyWith(color: Colors.black, fontSize: 32),
                      ),
                      Text(
                        'Features',
                        style: kSubtitleTextStyle.copyWith(color: Colors.black54),
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
            const SizedBox(height: 20),
            // Vintage Reels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReel(),
                _buildReel(),
              ],
            ),
            const Spacer(),
            // Song Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 20),
                      Column(
                        children: [
                          Text(
                            widget.song.title,
                            style: kTitleTextStyle.copyWith(color: Colors.black),
                          ),
                          Text(
                            widget.song.artist,
                            style: kSubtitleTextStyle.copyWith(color: Colors.black54),
                          ),
                        ],
                      ),
                      const Icon(Icons.favorite_border, color: Colors.black, size: 20),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Waveform (Mock)
                  SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: WaveformPainter(isPlaying: widget.playback.isPlaying),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('00:08', style: kSubtitleTextStyle.copyWith(color: Colors.black, fontSize: 10)),
                      Row(
                        children: [
                          const Icon(Icons.headphones, size: 12, color: Colors.black),
                          const SizedBox(width: 4),
                          Text('airpods', style: kSubtitleTextStyle.copyWith(color: Colors.black, fontSize: 10)),
                        ],
                      ),
                      Text('1:34', style: kSubtitleTextStyle.copyWith(color: Colors.black, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Sleek Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlCircle(Icons.fast_rewind, () => widget.playback.skipPrevious()),
                  const SizedBox(width: 20),
                  _buildControlCircle(
                    widget.playback.isPlaying ? Icons.pause : Icons.play_arrow,
                    () {
                      if (widget.playback.isPlaying) {
                        widget.playback.pause();
                      } else {
                        widget.playback.resume();
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildControlCircle(Icons.fast_forward, () => widget.playback.skipNext()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReel() {
    return AnimatedBuilder(
      animation: _reelController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _reelController.value * 2 * math.pi,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.black12,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Reel spokes
                Center(
                  child: CustomPaint(
                    painter: ReelPainter(),
                    size: const Size(100, 100),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}

class ReelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 3; i++) {
      double angle = (i * 2 * math.pi / 3);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      // Draw a "wing" or "spoke"
      final path = Path()
        ..moveTo(0, -10)
        ..lineTo(40, -15)
        ..quadraticBezierTo(50, 0, 40, 15)
        ..lineTo(0, 10)
        ..close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // Center hole
    canvas.drawCircle(center, 8, paint);
    paint.color = kMinimalistBeigeColor;
    canvas.drawCircle(center, 4, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WaveformPainter extends CustomPainter {
  final bool isPlaying;
  WaveformPainter({required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final barCount = 40;
    final spacing = size.width / barCount;
    final random = math.Random(42);

    for (int i = 0; i < barCount; i++) {
      double height = random.nextDouble() * size.height;
      if (!isPlaying) height *= 0.3; // Static waveform
      
      canvas.drawLine(
        Offset(i * spacing, size.height / 2 - height / 2),
        Offset(i * spacing, size.height / 2 + height / 2),
        paint,
      );
    }
    
    // Playhead line
    paint.color = Colors.black26;
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.4, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
