import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';
import 'profile_screen.dart';
import '../widgets/smooth_page_route.dart';
import '../providers/user_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/feature_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  String _downloadQuality = 'Minimum';
  bool _streamingWifiOnly = true;
  String _currentLanguage = 'English';
  bool _isEqualizerAuto = true;

  // Advanced Playback State
  String _crossfadeDuration = 'Off';
  bool _gaplessPlayback = true;
  bool _audioNormalization = true;
  bool _autoplay = true;
  String _outputMode = 'Default System';

  // Audio Quality State
  String _sampleRate = '44.1 kHz';
  String _bitDepth = '16-bit';
  bool _surroundSound = false;

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: kTitleTextStyle),
        content: Text(message, style: kSubtitleTextStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: kCyanColor)),
          ),
        ],
      ),
    );
  }

  void _showSelectionDialog(String title, List<String> options, String currentValue, ValueChanged<String> onSelected) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, style: kTitleTextStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final isSelected = currentValue == option;
              return TappableCard(
                onTap: () {
                  onSelected(option);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kCyanColor.withOpacity(0.1)
                        : const Color(0xFF0F172A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? kCyanColor.withOpacity(0.5)
                          : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? kCyanColor
                                : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: kCyanColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: kTitleTextStyle.copyWith(
                            fontSize: 15,
                            color: isSelected ? kCyanColor : kTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showEqualizerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Equalizer', style: kTitleTextStyle),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Auto/Manual Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => _isEqualizerAuto = true);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isEqualizerAuto
                                    ? kCyanColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Auto',
                                  style: TextStyle(
                                    color: _isEqualizerAuto
                                        ? Colors.white
                                        : kTextColor.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => _isEqualizerAuto = false);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isEqualizerAuto
                                    ? kCyanColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Manual',
                                  style: TextStyle(
                                    color: !_isEqualizerAuto
                                        ? Colors.white
                                        : kTextColor.withOpacity(0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isEqualizerAuto)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Audio equalization is automatically optimized for your device and current track.',
                        style: kSubtitleTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Column(
                      children: [
                        _buildEqSlider('Bass', 0.8),
                        _buildEqSlider('Mid', 0.5),
                        _buildEqSlider('Treble', 0.6),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEqSlider(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
              width: 50,
              child: Text(label,
                  style: kSubtitleTextStyle.copyWith(fontSize: 12))),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: kCyanColor,
                inactiveTrackColor: Colors.white10,
                thumbColor: kCyanColor,
              ),
              child: Slider(
                value: value,
                onChanged: (val) {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Text('Settings', style: kHeadingTextStyle),
          const SizedBox(height: 4),
          Text('Customize your experience', style: kSubtitleTextStyle),
          const SizedBox(height: 24),

          _buildSettingsGroup('Account', [
            _SettingItem(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Edit your profile',
              onTap: () => Navigator.push(
                  context, SmoothPageRoute(page: const ProfileScreen())),
            ),
            _SettingItem(
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Manage privacy settings',
              onTap: () => _showMessage('Privacy',
                  'Your data is secured with end-to-end encryption.'),
            ),
            _SettingItem(
              icon: Icons.notifications_active_outlined,
              title: 'Push Notifications',
              subtitle: _pushNotificationsEnabled
                  ? 'Enabled'
                  : 'Disabled',
              trailing: Switch(
                value: _pushNotificationsEnabled,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _pushNotificationsEnabled = val),
              ),
              onTap: () => setState(
                  () => _pushNotificationsEnabled = !_pushNotificationsEnabled),
            ),
            _SettingItem(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: _emailNotificationsEnabled
                  ? 'Enabled'
                  : 'Disabled',
              trailing: Switch(
                value: _emailNotificationsEnabled,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _emailNotificationsEnabled = val),
              ),
              onTap: () => setState(
                  () => _emailNotificationsEnabled = !_emailNotificationsEnabled),
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsGroup('Playback', [
            _SettingItem(
              icon: Icons.equalizer,
              title: 'Equalizer',
              subtitle: _isEqualizerAuto ? 'Auto Optimized' : 'Manual Mode',
              onTap: _showEqualizerDialog,
            ),
            _SettingItem(
              icon: Icons.download_outlined,
              title: 'Download Quality',
              subtitle: _downloadQuality,
              onTap: () => _showSelectionDialog(
                'Download Quality',
                ['Minimum', 'Normal', 'High'],
                _downloadQuality,
                (val) => setState(() => _downloadQuality = val),
              ),
            ),
            _SettingItem(
              icon: Icons.wifi_outlined,
              title: 'Streaming',
              subtitle: _streamingWifiOnly ? 'Wi-Fi only' : 'Cellular & Wi-Fi',
              trailing: Switch(
                value: _streamingWifiOnly,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _streamingWifiOnly = val),
              ),
              onTap: () =>
                  setState(() => _streamingWifiOnly = !_streamingWifiOnly),
            ),
            _SettingItem(
              icon: Icons.compare_arrows_outlined,
              title: 'Crossfade',
              subtitle: _crossfadeDuration,
              onTap: () => _showSelectionDialog(
                'Crossfade Duration',
                ['Off', '2s', '4s', '6s', '8s', '12s'],
                _crossfadeDuration,
                (val) => setState(() => _crossfadeDuration = val),
              ),
            ),
            _SettingItem(
              icon: Icons.skip_next_outlined,
              title: 'Gapless Playback',
              subtitle: _gaplessPlayback ? 'Enabled' : 'Disabled',
              trailing: Switch(
                value: _gaplessPlayback,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _gaplessPlayback = val),
              ),
              onTap: () => setState(() => _gaplessPlayback = !_gaplessPlayback),
            ),
            _SettingItem(
              icon: Icons.graphic_eq_rounded,
              title: 'Audio Normalization',
              subtitle: 'Set same volume for all tracks',
              trailing: Switch(
                value: _audioNormalization,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _audioNormalization = val),
              ),
              onTap: () => setState(() => _audioNormalization = !_audioNormalization),
            ),
            _SettingItem(
              icon: Icons.all_inclusive,
              title: 'Infinite Autoplay',
              subtitle: 'Play similar songs automatically',
              trailing: Switch(
                value: _autoplay,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _autoplay = val),
              ),
              onTap: () => setState(() => _autoplay = !_autoplay),
            ),
            _SettingItem(
              icon: Icons.speaker_group_outlined,
              title: 'Audio Output Mode',
              subtitle: _outputMode,
              onTap: () => _showSelectionDialog(
                'Output Mode',
                ['Default System', 'High-Res Audio Engine', 'Low Latency', 'Bluetooth Optimized'],
                _outputMode,
                (val) => setState(() => _outputMode = val),
              ),
            ),
          ]),

          const SizedBox(height: 20),

          _buildSettingsGroup('Appearance', [
            _SettingItem(
              icon: Icons.palette_outlined,
              title: 'Themes',
              subtitle: 'Vibrant Dark (Active)',
              onTap: _showThemeDialog,
            ),
          ]),

          const SizedBox(height: 20),

          // New Audio Quality Section
          _buildSettingsGroup('Audio Quality', [
            _SettingItem(
              icon: Icons.high_quality,
              title: 'Sample Rate',
              subtitle: _sampleRate,
              onTap: () => _showSelectionDialog(
                'Sample Rate',
                ['44.1 kHz', '48 kHz', '96 kHz'],
                _sampleRate,
                (val) => setState(() => _sampleRate = val),
              ),
            ),
            _SettingItem(
              icon: Icons.graphic_eq,
              title: 'Bit Depth',
              subtitle: _bitDepth,
              onTap: () => _showSelectionDialog(
                'Bit Depth',
                ['16-bit', '24-bit', '32-bit (Floating)'],
                _bitDepth,
                (val) => setState(() => _bitDepth = val),
              ),
            ),
            _SettingItem(
              icon: Icons.surround_sound,
              title: 'Surround Sound',
              subtitle: _surroundSound ? 'Immersive enabled' : 'Stereo only',
              trailing: Switch(
                value: _surroundSound,
                activeThumbColor: kCyanColor,
                onChanged: (val) => setState(() => _surroundSound = val),
              ),
              onTap: () => setState(() => _surroundSound = !_surroundSound),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.yellowAccent.withOpacity(0.7), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The selected rate or bit might not be available for all the songs',
                    style: TextStyle(
                      color: Colors.yellowAccent.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSettingsGroup('General', [
            _SettingItem(
              icon: Icons.language,
              title: 'Language',
              subtitle: _currentLanguage,
              onTap: () => _showMessage('Language',
                  'More languages will be added in the next update.'),
            ),
            _SettingItem(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Version 2.4.0 (Vibrant Dark)',
              onTap: () => _showMessage('About',
                  'Melme Music App\nCreated with ❤️ for a vibrant experience.'),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    final featureProvider = context.read<FeatureProvider>();
    final isPremium = featureProvider.isPremiumUnlocked;

    final List<Map<String, dynamic>> themes = [
      {'name': 'Vibrant Dark', 'color': kCyanColor, 'locked': false},
      {
        'name': 'Royal Purple',
        'color': Colors.purpleAccent,
        'locked': !isPremium
      },
      {
        'name': 'Forest Green',
        'color': Colors.greenAccent,
        'locked': !isPremium
      },
      {'name': 'Sunset Orange', 'color': kOrangeColor, 'locked': !isPremium},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Select Theme', style: kTitleTextStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: themes.map((theme) {
              return TappableCard(
                onTap: theme['locked']
                    ? () => _showMessage('Theme Locked',
                        'This premium theme is coming in the next update!')
                    : () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme['locked']
                          ? Colors.white.withOpacity(0.05)
                          : theme['color'].withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          theme['name'],
                          style: kTitleTextStyle.copyWith(
                            fontSize: 15,
                            color: theme['locked']
                                ? kTextColor.withOpacity(0.3)
                                : kTextColor,
                          ),
                        ),
                      ),
                      if (theme['locked'])
                        const Icon(Icons.lock_outline,
                            color: Colors.white24, size: 18)
                      else
                        const Icon(Icons.check_circle,
                            color: kCyanColor, size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text('Settings', style: kTitleTextStyle),
    );
  }

  Widget _buildSettingsGroup(String title, List<_SettingItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: kTitleTextStyle.copyWith(fontSize: 14, color: kCyanColor)),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                TappableCard(
                  onTap: item.onTap,
                  scaleDown: 0.98,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.05), width: 1),
                        ),
                        child: Icon(item.icon, color: kTextColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: kTitleTextStyle.copyWith(fontSize: 15)),
                            Text(item.subtitle,
                                style:
                                    kSubtitleTextStyle.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                      item.trailing ??
                          const Icon(Icons.chevron_right,
                              color: Colors.white24, size: 20),
                    ],
                  ),
                ),
                if (index < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                        height: 1, color: Colors.white.withOpacity(0.05)),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
}
