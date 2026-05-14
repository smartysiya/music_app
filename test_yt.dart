import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final videoId = 'Tm8LGxDN9qw'; // Linkin Park One More Light
  final query = 'One More Light Linkin Park audio';

  try {
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    print("Original video works: " + manifest.audioOnly.length.toString());
  } catch (e) {
    print("Original video failed: $e");
    print("Trying fallback search...");
    try {
      final searchResults = await yt.search.search(query);
      for (var video in searchResults) {
        print("Trying fallback video: ${video.title} (${video.id.value})");
        try {
          final manifest = await yt.videos.streamsClient.getManifest(video.id);
          print("Fallback video works! Found streams: " + manifest.audioOnly.length.toString());
          break;
        } catch (_) {
          print("Fallback video ${video.id.value} failed too.");
          continue;
        }
      }
    } catch (fallbackError) {
      print("Fallback search failed: $fallbackError");
    }
  } finally {
    yt.close();
  }
}
