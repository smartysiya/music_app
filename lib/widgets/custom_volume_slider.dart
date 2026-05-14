import 'package:flutter/material.dart';
import '../constants.dart';

class CustomVolumeSlider extends StatelessWidget {
  final double volume; // 0.0 to 1.0
  final ValueChanged<double> onChanged;

  const CustomVolumeSlider({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Speaker', style: kTitleTextStyle.copyWith(fontSize: 14)),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              _handleUpdate(context, details.localPosition.dx);
            },
            onTapDown: (details) {
              _handleUpdate(context, details.localPosition.dx);
            },
            child: Container(
              height: 20, // Larger hit area
              color: Colors.transparent, // Make hit area visible for debugging if needed
              child: Center(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth * volume,
                            height: 4,
                            decoration: BoxDecoration(
                              color: kCyanColor,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: kCyanColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 0),
                                )
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 40,
          child: Text(
            '${(volume * 100).toInt()}%',
            style: kSubtitleTextStyle.copyWith(color: kTextColor),
          ),
        ),
      ],
    );
  }

  void _handleUpdate(BuildContext context, double dx) {
    // We need the width of the container. 
    // Since we're in a stateless widget without a context-based size, 
    // we rely on the constraints in the builder or just use a RenderBox.
    final box = context.findRenderObject() as RenderBox;
    // This is a bit tricky since 'dx' is local to the GestureDetector.
    // The GestureDetector is inside an Expanded, so it takes most of the width.
    // We'll calculate the volume based on the local dx and the total width of the gesture area.
    double newVolume = (dx / box.size.width).clamp(0.0, 1.0);
    onChanged(newVolume);
  }
}
