import 'package:flutter/material.dart';
import 'data/music_library.dart';

const Color kBackgroundColor = Color(0xFF0F172A); // Deep Navy/Dark Blue
const Color kCyanColor = Color(0xFF06B6D4); // Vibrant Teal/Cyan
const Color kVividBlueColor = Color(0xFF3B82F6); // Vivid Blue
const Color kOrangeColor = Color(0xFFFB923C); // Lively Accent (Orange)
const Color kTealColor = Color(0xFF14B8A6); // Peaceful Teal
const Color kBorderColor = Color(0xFF1E293B); // Subtle Dark Border
const Color kTextColor = Color(0xFFF8FAFC); // Off-white for text
const Color kVibrantYellowColor = Color(0xFFFFD700); // Bold Yellow
const Color kMinimalistBeigeColor = Color(0xFFD2CEC3); // Soft Beige
const String kYouTubeApiKey = 'AIzaSyCBzJhXM-IZbyqneKZcTMfwqlBxkbGOuk0';

final BorderRadius kBorderRadius = BorderRadius.circular(24.0);

BoxDecoration kCardDecoration = BoxDecoration(
  color: const Color(0xFF1E293B).withOpacity(0.7), // Glassmorphism-like
  borderRadius: kBorderRadius,
  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      offset: const Offset(0, 10),
      blurRadius: 20,
    )
  ],
);

BoxDecoration kCyanButtonDecoration = BoxDecoration(
  color: kCyanColor,
  borderRadius: BorderRadius.circular(16.0),
  border: Border.all(color: kBorderColor, width: 1.5),
);

BoxDecoration kOrangeButtonDecoration = BoxDecoration(
  color: kOrangeColor,
  borderRadius: BorderRadius.circular(16.0),
  border: Border.all(color: kBorderColor, width: 1.5),
);

TextStyle kHeadingTextStyle = const TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: kTextColor,
  letterSpacing: -0.5,
);

TextStyle kTitleTextStyle = const TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

TextStyle kSubtitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: kTextColor.withOpacity(0.6),
);

void showSongInfoDialog(BuildContext context, Song song) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(song.imageUrl, width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(song.title, style: kTitleTextStyle, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Singer', song.artist),
          _buildInfoRow('Album', song.album),
          _buildInfoRow('Genre', song.genre),
          const Divider(color: Colors.white10, height: 24),
          Text('License Info', style: kTitleTextStyle.copyWith(fontSize: 14, color: kCyanColor)),
          const SizedBox(height: 8),
          Text(song.license, style: kSubtitleTextStyle.copyWith(fontSize: 12, height: 1.5)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: kCyanColor)),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label: ', style: kSubtitleTextStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.white70)),
          TextSpan(text: value, style: kSubtitleTextStyle),
        ],
      ),
    ),
  );
}
