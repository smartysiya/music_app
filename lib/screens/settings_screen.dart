import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Text('Settings', style: kHeadingTextStyle),
          const SizedBox(height: 4),
          Text('Customize your experience', style: kSubtitleTextStyle),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _buildSettingsGroup('Account', [
                  _SettingItem(Icons.person_outline, 'Profile', 'Edit your profile'),
                  _SettingItem(Icons.lock_outline, 'Privacy', 'Manage privacy settings'),
                  _SettingItem(Icons.notifications_none, 'Notifications', 'Push & email'),
                ]),
                const SizedBox(height: 20),
                _buildSettingsGroup('Playback', [
                  _SettingItem(Icons.equalizer, 'Equalizer', 'Adjust audio'),
                  _SettingItem(Icons.download_outlined, 'Download Quality', 'High quality'),
                  _SettingItem(Icons.wifi_outlined, 'Streaming', 'Wi-Fi only'),
                ]),
                const SizedBox(height: 20),
                _buildSettingsGroup('General', [
                  _SettingItem(Icons.palette_outlined, 'Theme', 'Light mode'),
                  _SettingItem(Icons.language, 'Language', 'English'),
                  _SettingItem(Icons.info_outline, 'About', 'Version 1.0.0'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kOrangeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor, width: 1.5),
          ),
          child: const Icon(Icons.settings, color: Colors.black),
        ),
        Text('Settings', style: kTitleTextStyle),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kBorderColor, width: 1.5),
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150?img=32'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<_SettingItem> items) {
    return TappableCard(
      scaleDown: 0.98,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: kCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: kTitleTextStyle.copyWith(
                    fontSize: 14, color: kCyanColor)),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style:
                                    kTitleTextStyle.copyWith(fontSize: 15)),
                            Text(item.subtitle, style: kSubtitleTextStyle.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 20),
                    ],
                  ),
                  if (index < items.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                          height: 1, color: Colors.grey.shade200),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _SettingItem(this.icon, this.title, this.subtitle);
}
