import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/playback_provider.dart';

class SongArtwork extends StatelessWidget {
  final String songId;
  final String fallbackImageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData icon;

  const SongArtwork({
    super.key,
    required this.songId,
    required this.fallbackImageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.icon = Icons.music_note,
  });

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();
    final artworkUrl = playback.getArtworkForTrack(songId).isNotEmpty
        ? playback.getArtworkForTrack(songId)
        : fallbackImageUrl;

    final double effectiveRadius = borderRadius != null ? 0 : 8;

    final Widget placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(effectiveRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: kCyanColor.withOpacity(0.5),
          size: width != null ? width! * 0.4 : 24,
        ),
      ),
    );

    if (artworkUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(effectiveRadius),
      child: Image.network(
        artworkUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class AlbumArtwork extends StatelessWidget {
  final String album;
  final String fallbackImageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AlbumArtwork({
    super.key,
    required this.album,
    required this.fallbackImageUrl,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();
    final artworkUrl = playback.getArtworkForAlbum(album).isNotEmpty
        ? playback.getArtworkForAlbum(album)
        : fallbackImageUrl;

    final double effectiveRadius = borderRadius != null ? 0 : 12;

    final Widget placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(effectiveRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album,
          color: kCyanColor.withOpacity(0.5),
          size: width != null ? width! * 0.4 : 48,
        ),
      ),
    );

    if (artworkUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(effectiveRadius),
      child: Image.network(
        artworkUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
