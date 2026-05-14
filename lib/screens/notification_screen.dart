import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E3A8A).withOpacity(0.8),
            kBackgroundColor,
            kTealColor.withOpacity(0.2),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kTextColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Notifications', style: kTitleTextStyle),
          centerTitle: true,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: 5,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildNotificationItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final List<Map<String, dynamic>> notifications = [
      {
        'type': 'app',
        'title': 'New Release!',
        'body': 'Alan Walker just dropped a new single. Listen now!',
        'time': '2m ago',
        'icon': Icons.music_note_rounded,
        'color': kCyanColor,
      },
      {
        'type': 'email',
        'title': 'Security Alert',
        'body': 'A new login was detected on your account from a Windows device.',
        'time': '15m ago',
        'icon': Icons.email_outlined,
        'color': Colors.blueAccent,
      },
      {
        'type': 'app',
        'title': 'Playlist Updated',
        'body': 'Your "Daily Mix" has been updated with new tracks.',
        'time': '1h ago',
        'icon': Icons.update_rounded,
        'color': kTealColor,
      },
      {
        'type': 'email',
        'title': 'Weekly Wrap-up',
        'body': 'Check out your listening stats for this week in your inbox.',
        'time': '4h ago',
        'icon': Icons.alternate_email_rounded,
        'color': Colors.indigoAccent,
      },
      {
        'type': 'app',
        'title': 'System Update',
        'body': 'Melme version 2.4.0 is now available with Hi-Fi controls!',
        'time': '2d ago',
        'icon': Icons.system_update_rounded,
        'color': kOrangeColor,
      },
    ];

    final item = notifications[index % notifications.length];
    final bool isEmail = item['type'] == 'email';

    return TappableCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: kCardDecoration.copyWith(
          border: Border.all(
            color: (item['color'] as Color).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(item['title']!, style: kTitleTextStyle.copyWith(fontSize: 16)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isEmail ? 'EMAIL' : 'APP',
                              style: TextStyle(
                                color: item['color'] as Color,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(item['time']!, style: kSubtitleTextStyle.copyWith(fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['body']!,
                    style: kSubtitleTextStyle.copyWith(fontSize: 13, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
