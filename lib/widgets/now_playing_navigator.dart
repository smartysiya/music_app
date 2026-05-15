import 'package:flutter/material.dart';
import '../screens/now_playing_screen.dart';
import 'smooth_page_route.dart';

/// Centralized navigator for NowPlayingScreen.
/// Ensures only one instance is ever on the stack at a time.
class NowPlayingNavigator {
  static const String routeName = '/now_playing';

  // Track whether a NowPlayingScreen is currently in the stack
  static bool _isOpen = false;

  /// Navigate to NowPlayingScreen, ensuring only a single instance exists.
  ///
  /// - If NowPlayingScreen is already open, pops everything above it
  ///   so it becomes the top route (provider updates the song data).
  /// - Otherwise, pushes a fresh instance.
  static void open(BuildContext context) {
    if (_isOpen) {
      // NowPlayingScreen is already in the stack.
      // Pop until we find it, so it becomes visible again with updated data.
      Navigator.of(context).popUntil((route) {
        return route.settings.name == routeName || route.isFirst;
      });
      return;
    }

    // No existing instance — push a new one
    _isOpen = true;
    Navigator.of(context).push(
      SmoothPageRoute(
        page: const NowPlayingScreen(),
        settings: const RouteSettings(name: routeName),
      ),
    ).then((_) {
      // When the screen is popped, mark it as closed
      _isOpen = false;
    });
  }
}
