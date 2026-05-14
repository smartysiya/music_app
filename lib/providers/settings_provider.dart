import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isOfflineMode = false;
  String _sampleRate = '44.1 kHz';
  String _bitDepth = '16-bit';
  bool _surroundSound = false;

  bool get isOfflineMode => _isOfflineMode;
  String get sampleRate => _sampleRate;
  String get bitDepth => _bitDepth;
  bool get surroundSound => _surroundSound;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('is_offline_mode') ?? false;
    _sampleRate = prefs.getString('sample_rate') ?? '44.1 kHz';
    _bitDepth = prefs.getString('bit_depth') ?? '16-bit';
    _surroundSound = prefs.getBool('surround_sound') ?? false;
    notifyListeners();
  }

  Future<void> toggleOfflineMode(bool value) async {
    _isOfflineMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_offline_mode', value);
    notifyListeners();
  }

  Future<void> setSampleRate(String value) async {
    _sampleRate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sample_rate', value);
    notifyListeners();
  }

  Future<void> setBitDepth(String value) async {
    _bitDepth = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bit_depth', value);
    notifyListeners();
  }

  Future<void> toggleSurroundSound(bool value) async {
    _surroundSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('surround_sound', value);
    notifyListeners();
  }
}
