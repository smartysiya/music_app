import 'package:flutter/material.dart';
import '../constants.dart';

/// Animated background with drifting colour orbs.
/// Reacts to [accentColor] changes with a smooth colour transition.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color accentColor;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.accentColor = kCyanColor,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  // Orb 1 — slow diagonal drift
  late AnimationController _orb1Controller;
  late Animation<Offset> _orb1Position;
  late Animation<double> _orb1Scale;

  // Orb 2 — medium counter-drift
  late AnimationController _orb2Controller;
  late Animation<Offset> _orb2Position;

  // Orb 3 — fast pulse
  late AnimationController _orb3Controller;
  late Animation<double> _orb3Scale;

  // Colour transition when accent changes
  late AnimationController _colorController;
  Color _prevAccent = kCyanColor;

  @override
  void initState() {
    super.initState();
    _prevAccent = widget.accentColor;

    _orb1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _orb1Position = Tween<Offset>(
      begin: const Offset(-0.15, -0.10),
      end: const Offset(0.15, 0.12),
    ).animate(CurvedAnimation(parent: _orb1Controller, curve: Curves.easeInOut));

    _orb1Scale = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _orb1Controller, curve: Curves.easeInOut),
    );

    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _orb2Position = Tween<Offset>(
      begin: const Offset(0.10, 0.05),
      end: const Offset(-0.12, -0.08),
    ).animate(CurvedAnimation(parent: _orb2Controller, curve: Curves.easeInOut));

    _orb3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _orb3Scale = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _orb3Controller, curve: Curves.easeInOut),
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(AnimatedBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accentColor != widget.accentColor) {
      _prevAccent = oldWidget.accentColor;
      _colorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _orb1Controller,
        _orb2Controller,
        _orb3Controller,
        _colorController,
      ]),
      builder: (context, child) {
        final accent = Color.lerp(
          _prevAccent,
          widget.accentColor,
          CurvedAnimation(
            parent: _colorController,
            curve: Curves.easeOut,
          ).value,
        )!;

        return Stack(
          children: [
            // Background image layer
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg_home.png',
                fit: BoxFit.cover,
              ),
            ),

            // Dark overlay so content is readable
            Positioned.fill(
              child: Container(
                color: kBackgroundColor.withValues(alpha: 0.82),
              ),
            ),

            // Orb 1 — cyan/accent top-left
            Positioned(
              left: MediaQuery.of(context).size.width * (0.1 + _orb1Position.value.dx),
              top: MediaQuery.of(context).size.height * (0.05 + _orb1Position.value.dy),
              child: Transform.scale(
                scale: _orb1Scale.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.28),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Orb 2 — orange bottom-right
            Positioned(
              right: MediaQuery.of(context).size.width * (0.05 + _orb2Position.value.dx),
              bottom: MediaQuery.of(context).size.height * (0.15 + _orb2Position.value.dy),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kOrangeColor.withValues(alpha: 0.22),
                      kOrangeColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Orb 3 — small accent pulse center-right
            Positioned(
              right: MediaQuery.of(context).size.width * 0.05,
              top: MediaQuery.of(context).size.height * 0.35,
              child: Transform.scale(
                scale: _orb3Scale.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Actual content
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
