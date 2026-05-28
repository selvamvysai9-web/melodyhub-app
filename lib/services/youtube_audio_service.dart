import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeAudioService {
  static final YoutubeExplode _yt = YoutubeExplode();
  
  /// Get a direct audio stream URL from YouTube video ID
  static Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      // Get audio-only streams, prefer higher bitrate
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isEmpty) return null;
      
      // Return the highest quality audio stream URL
      return audioStreams.last.url.toString();
    } catch (e) {
      print('Error getting YouTube audio stream: $e');
      return null;
    }
  }
  
  /// Get audio stream for multiple video IDs (batch optimization)
  static Future<Map<String, String>> getAudioStreamUrls(List<String> videoIds) async {
    final result = <String, String>{};
    for (final videoId in videoIds) {
      final url = await getAudioStreamUrl(videoId);
      if (url != null) {
        result[videoId] = url;
      }
    }
    return result;
  }
  
  /// Get video metadata
  static Future<Map<String, dynamic>?> getVideoMetadata(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      return {
        'title': video.title,
        'author': video.author,
        'duration': video.duration?.inSeconds ?? 0,
        'thumbnail': video.thumbnails.highResUrl,
      };
    } catch (e) {
      print('Error getting video metadata: $e');
      return null;
    }
  }
  
  /// Cleanup resources
  static void dispose() {
    _yt.close();
  }
}
