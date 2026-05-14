import 'dart:async';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
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

  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Simulate auto-check every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _addServerNotification();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    // Simulate server delay
    await Future.delayed(const Duration(seconds: 1));
    _addServerNotification();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _addServerNotification() {
    if (!mounted) return;
    setState(() {
      _notifications.insert(0, {
        'type': 'app',
        'title': 'Live Update!',
        'body': 'New content has been pushed to the server. Refresh to explore!',
        'time': 'Just now',
        'icon': Icons.bolt_rounded,
        'color': kCyanColor,
      });
    });
  }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: kTextColor),
              onPressed: () {
                setState(() => _notifications.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications cleared')),
                );
              },
            ),
            if (_isRefreshing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: kCyanColor),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, color: kTextColor),
                onPressed: _handleRefresh,
              ),
          ],
        ),
        body: RefreshIndicator(
          color: kCyanColor,
          backgroundColor: const Color(0xFF1E293B),
          onRefresh: _handleRefresh,
          child: _notifications.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      Text('No notifications', style: kSubtitleTextStyle),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Dismissible(
                      key: Key(item['title']! + item['time']!),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                      onDismissed: (direction) {
                        setState(() => _notifications.removeAt(index));
                      },
                      child: _buildNotificationItem(index),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _onNotificationTap(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(item['icon'] as IconData, color: item['color'] as Color),
            const SizedBox(width: 12),
            Expanded(child: Text(item['title']!, style: kTitleTextStyle)),
          ],
        ),
        content: Text(item['body']!, style: kSubtitleTextStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: Colors.white38)),
          ),
          if (item['title'].contains('Release') || item['title'].contains('Playlist'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kCyanColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Open', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    final item = _notifications[index];
    final bool isEmail = item['type'] == 'email';

    return TappableCard(
      onTap: () => _onNotificationTap(item),
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
