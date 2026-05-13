import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/tappable_card.dart';

class LyricScreen extends StatelessWidget {
  const LyricScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background blur effect
            Positioned(
              left: -50,
              top: 200,
              child: Container(
                width: 150,
                height: 300,
                decoration: BoxDecoration(
                  color: kCyanColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Positioned(
              right: -50,
              bottom: 100,
              child: Container(
                width: 150,
                height: 300,
                decoration: BoxDecoration(
                  color: kOrangeColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _buildLyricCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TappableCard(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: kOrangeButtonDecoration.copyWith(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        Text('Lyric', style: kTitleTextStyle),
        const Icon(Icons.share_outlined, color: Colors.black),
      ],
    );
  }

  Widget _buildLyricCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: kCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text('The Spectre', style: kTitleTextStyle),
              const Spacer(),
              const Icon(Icons.info_outline, color: Colors.black),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildLyricLine('These are the better days', false),
                  _buildLyricLine('If not today must be tomorrow', false),
                  _buildLyricLine('If not today must be', false),
                  _buildLyricLine('These are the better days', false),
                  _buildLyricLine('If not today must be tomorrow', true),
                  _buildLyricLine('If not today must be', false),
                  _buildLyricLine('They said I\'m getting old', false),
                  // Add some extra lines for scrolling
                  _buildLyricLine('And I need to grow up', false),
                  _buildLyricLine('But what do they know', false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Binder holes placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBorderColor, width: 1.5),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBorderColor, width: 1.5),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLyricLine(String text, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isCurrent ? 18 : 16,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          color: isCurrent ? kCyanColor : Colors.grey.shade600,
        ),
      ),
    );
  }
}
