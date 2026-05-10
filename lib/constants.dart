import 'package:flutter/material.dart';

const Color kBackgroundColor = Color(0xFFF2F5F9);
const Color kCyanColor = Color(0xFF4AC4B8);
const Color kOrangeColor = Color(0xFFFFBE76);
const Color kBorderColor = Colors.black;

final BorderRadius kBorderRadius = BorderRadius.circular(24.0);

BoxDecoration kCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: kBorderRadius,
  border: Border.all(color: kBorderColor, width: 1.5),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
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
  color: Colors.black,
  letterSpacing: -0.5,
);

TextStyle kTitleTextStyle = const TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

TextStyle kSubtitleTextStyle = const TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Colors.grey,
);
