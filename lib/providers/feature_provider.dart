import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureProvider extends ChangeNotifier {
  bool _isPremiumUnlocked = true; // Permanently unlocked via safe word

  FeatureProvider() {
    _loadStatus();
  }

  bool get isPremiumUnlocked => _isPremiumUnlocked;

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Check if data is still valid (using the 30-min logic like others)
    final lastSaved = prefs.getInt('feature_unlock_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - lastSaved < 30 * 60 * 1000) {
      _isPremiumUnlocked = prefs.getBool('is_premium_unlocked') ?? false;
      notifyListeners();
    }
  }

  Future<void> unlockEverything() async {
    _isPremiumUnlocked = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_unlocked', true);
    await prefs.setInt('feature_unlock_timestamp', DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> lockEverything() async {
    _isPremiumUnlocked = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_unlocked', false);
    notifyListeners();
  }
}
