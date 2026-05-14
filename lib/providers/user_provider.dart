import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _name = 'John Doe';
  String? _profileImagePath;
  String _email = 'john.doe@example.com';
  String _bio = 'Music enthusiast & developer';
  String _phone = '+1 234 567 8900';

  UserProvider() {
    _loadFromPrefs();
  }

  String get name => _name;
  String? get profileImagePath => _profileImagePath;
  String get email => _email;
  String get bio => _bio;
  String get phone => _phone;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if data is still valid (within 30 mins)
    final lastSaved = prefs.getInt('user_data_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastSaved < 30 * 60 * 1000) {
      _name = prefs.getString('user_name') ?? _name;
      _email = prefs.getString('user_email') ?? _email;
      _bio = prefs.getString('user_bio') ?? _bio;
      _phone = prefs.getString('user_phone') ?? _phone;
      _profileImagePath = prefs.getString('user_profile_path');
      notifyListeners();
    } else {
      // Data expired or never saved, keep defaults or clear
      debugPrint('User data expired or not found');
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_email', _email);
    await prefs.setString('user_bio', _bio);
    await prefs.setString('user_phone', _phone);
    if (_profileImagePath != null) {
      await prefs.setString('user_profile_path', _profileImagePath!);
    }
    await prefs.setInt(
        'user_data_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  void updateName(String newName) {
    _name = newName;
    _saveToPrefs();
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    _email = newEmail;
    _saveToPrefs();
    notifyListeners();
  }

  void updateProfileImage(String path) {
    _profileImagePath = path;
    _saveToPrefs();
    notifyListeners();
  }

  void updateBio(String newBio) {
    _bio = newBio;
    _saveToPrefs();
    notifyListeners();
  }

  void updatePhone(String newPhone) {
    _phone = newPhone;
    _saveToPrefs();
    notifyListeners();
  }
}
