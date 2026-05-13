import 'package:flutter/material.dart';

/// Custom page route with smooth scale + fade transition.
/// The outgoing page shrinks slightly while the incoming page expands in.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Incoming page: scale up from 0.92 to 1.0 + fade in
            final scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );
            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
            );

            // Outgoing page: scale down slightly
            final scaleOut = Tween<double>(begin: 1.0, end: 0.95).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOut,
              ),
            );
            final fadeOut = Tween<double>(begin: 1.0, end: 0.7).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOut,
              ),
            );

            return ScaleTransition(
              scale: scaleOut,
              child: FadeTransition(
                opacity: fadeOut,
                child: ScaleTransition(
                  scale: scaleIn,
                  child: FadeTransition(
                    opacity: fadeIn,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
}
