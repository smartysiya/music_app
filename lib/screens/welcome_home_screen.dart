import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class WelcomeHomeScreen extends StatefulWidget {
  const WelcomeHomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeHomeScreen> createState() => _WelcomeHomeScreenState();
}

class _WelcomeHomeScreenState extends State<WelcomeHomeScreen> {
  // Mock image URLs (can be replaced with your local 'assets/...' paths)
  final List<String> _images = [
    'https://picsum.photos/id/1018/400/400', // Nature
    'https://picsum.photos/id/1015/400/400', // River
    'https://picsum.photos/id/1019/400/400', // Sunset
    'https://picsum.photos/id/1016/400/400', // Canyon
    'https://picsum.photos/id/1025/400/400', // Pug
    'https://picsum.photos/id/1020/400/400', // Bear
  ];

  late String _selectedImage;
  Color _dominantColor = const Color(0xFF1A1A2E); // Fallback color

  @override
  void initState() {
    super.initState();
    _selectedImage = _images.first;
    // Extract color immediately on screen load
    _extractDominantColor(_selectedImage);
  }

  /// Extracts the dominant color from the given image asynchronously.
  /// Downscales the image to 100x100 for incredibly fast performance 
  /// so the UI never drops frames or janks.
  Future<void> _extractDominantColor(String imageUrl) async {
    try {
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl), // Use AssetImage(imageUrl) if using local assets
        size: const Size(100, 100), 
        maximumColorCount: 10,
      );

      // Safe state update
      if (mounted) {
        setState(() {
          // If extraction fails or is null, fallback to the default dark color
          _dominantColor = paletteGenerator.dominantColor?.color ?? const Color(0xFF1A1A2E);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dominantColor = const Color(0xFF1A1A2E);
        });
      }
    }
  }

  /// Triggered when the user taps one of the small circular options
  void _onImageTapped(String imageUrl) {
    if (_selectedImage == imageUrl) return; // Ignore if already selected
    
    setState(() {
      _selectedImage = imageUrl;
    });
    
    // Trigger live re-theming
    _extractDominantColor(imageUrl);
  }

  /// Helper function: Evaluates the background color's luminance and returns 
  /// either white or black to guarantee WCAG-safe text contrast.
  Color getContrastColor(Color bg) {
    // 0.179 is the WCAG 2.0 standard threshold for contrast calculation
    return bg.computeLuminance() > 0.179 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        // Animated gradient background: fades from a soft wash of the dominant color down to the default theme color
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _dominantColor.withOpacity(0.85), // Top wash
              Theme.of(context).scaffoldBackgroundColor, // Fades to white/dark
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Animated Title Text
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  // Auto-switch to white or black based on the top gradient color
                  color: getContrastColor(_dominantColor), 
                ),
                child: const Text('Welcome Home'),
              ),
              
              const SizedBox(height: 40),
              
              // Large Circular Hero Image
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Glowing colored shadow ring
                  boxShadow: [
                    BoxShadow(
                      color: _dominantColor.withOpacity(0.6),
                      blurRadius: 35,
                      spreadRadius: 10,
                    ),
                  ],
                  // Colored border ring
                  border: Border.all(
                    color: _dominantColor,
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    _selectedImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Grid of 6 smaller circular images
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _images.map((img) {
                    final isSelected = img == _selectedImage;
                    
                    return GestureDetector(
                      onTap: () => _onImageTapped(img),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // Highlighted ring border for the active item
                          border: Border.all(
                            color: isSelected ? _dominantColor : Colors.transparent,
                            width: isSelected ? 4 : 0,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: _dominantColor.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            img,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // "Continue" Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: GestureDetector(
                  onTap: () {
                    // Add routing logic here
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // Button background morphs to dominant color
                      color: _dominantColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _dominantColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          // Button text contrasts against the button background
                          color: getContrastColor(_dominantColor),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
