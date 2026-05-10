import 'package:flutter/material.dart';
import '../constants.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: kCyanButtonDecoration.copyWith(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, 0),
          _buildNavItem(Icons.favorite_border, 1),
          _buildNavItem(Icons.play_circle_fill, 2), // Special center icon
          _buildNavItem(Icons.settings_outlined, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = currentIndex == index;
    // The design has an orange square for the selected home icon
    if (index == 0 && isSelected) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kOrangeColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor, width: 1.5),
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      );
    }
    
    // The play button is special (looks like a camera or play button in the image, wait, it's actually an app icon or play? Let's use an album-like icon or generic.)
    if (index == 2) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor, width: 1.5),
        ),
        child: Icon(icon, color: Colors.black, size: 24),
      );
    }

    return GestureDetector(
      onTap: () => onTap(index),
      child: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.white,
        size: 28,
      ),
    );
  }
}
