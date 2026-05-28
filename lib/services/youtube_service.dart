import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';
import 'backend_config.dart';

sealed class YouTubeResult {
  const YouTubeResult();
}

class YouTubeSearchSuccess extends YouTubeResult {
  final List<YouTubeVideo> videos;
  final String? nextPageToken;
  const YouTubeSearchSuccess(this.videos, {this.nextPageToken});
}

class YouTubeDetailsSuccess extends YouTubeResult {
  final List<YouTubeVideo> videos;
  const YouTubeDetailsSuccess(this.videos);
}

class YouTubeQuotaExceeded extends YouTubeResult {
  final String message;
  const YouTubeQuotaExceeded([this.message = 'YouTube API quota exceeded.']);
}

class YouTubeNetworkError extends YouTubeResult {
  final String message;
  const YouTubeNetworkError(this.message);
}

class YouTubeApiError extends YouTubeResult {
  final int statusCode;
  final String message;
  const YouTubeApiError(this.statusCode, this.message);
}

class YouTubeService {
  final String _apiKey;
  final http.Client _client;

  // =========================================================
  // THE BACKEND CONNECTION GATEWAY
  // Pointed directly at your Windows PC on your local Wi-Fi network
  // =========================================================
  static const String backendUrl = 'http://192.168.1.13:3000';

  YouTubeService({
    required String apiKey,
    http.Client? client,
  })  : _apiKey = apiKey,
        _client = client ?? http.Client();

  static const Map<String, String> languageMap = {
    'en': 'en', 'hi': 'hi', 'ta': 'ta', 'te': 'te',
    'ml': 'ml', 'kn': 'kn', 'es': 'es', 'ko': 'ko',
    'ja': 'ja', 'fr': 'fr', 'ar': 'ar',
  };

  Future<YouTubeResult> search({
    required String query,
    String language = 'en',
    int maxResults = 15,
    String? pageToken,
  }) async {
    // Try Render backend first
    if (pageToken == null) {
      try {
        final resp = await _client.get(
          Uri.parse('${BackendConfig.search(query)}&maxResults=$maxResults'),
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body) as List<dynamic>? ?? [];
          final videos = body
              .map((e) {
                final m = e as Map<String, dynamic>? ?? {};
                return YouTubeVideo(
                  videoId: m['videoId']?.toString() ?? '',
                  title: m['title']?.toString() ?? 'Unknown',
                  channelTitle: m['artist']?.toString() ?? m['channelTitle']?.toString() ?? 'Unknown',
                  thumbnailUrl: m['thumbnail']?.toString() ?? '',
                  highResThumbnailUrl: m['thumbnail']?.toString() ?? '',
                );
              })
              .where((v) => v.videoId.isNotEmpty)
              .toList();
          return YouTubeSearchSuccess(videos);
        }
      } catch (_) {}
    }

    try {
      final lang = languageMap[language] ?? 'en';
      final params = {
        'part': 'snippet',
        'maxResults': maxResults.toString(),
        'q': query,
        'type': 'video',
        'videoCategoryId': '10',
        'relevanceLanguage': lang,
        'key': _apiKey,
      };
      if (pageToken != null) params['pageToken'] = pageToken;

      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', params);

      final response = await _client.get(uri);
      return _handleSearchResponse(response);
    } on http.ClientException catch (e) {
      return YouTubeNetworkError('Network error: ${e.message}');
    } catch (e) {
      return YouTubeNetworkError('Unexpected error: ${e.runtimeType}');
    }
  }

  Future<YouTubeResult> getVideoDetails(List<String> videoIds) async {
    try {
      final params = {
        'part': 'snippet,contentDetails,statistics',
        'id': videoIds.join(','),
        'key': _apiKey,
      };

      final uri = Uri.https('www.googleapis.com', '/youtube/v3/videos', params);

      final response = await _client.get(uri);
      return _handleDetailsResponse(response);
    } on http.ClientException catch (e) {
      return YouTubeNetworkError('Network error: ${e.message}');
    } catch (e) {
      return YouTubeNetworkError('Unexpected error: ${e.runtimeType}');
    }
  }

  // --- The Node.js Backend Connection ---
  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      print("🎧 Asking Node.js backend for audio stream...");
      
      // Connect to the /api/stream endpoint on your secure server
      final uri = Uri.parse('$backendUrl/api/stream?videoId=$videoId');

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Backend connection timed out'),
      );

      if (response.statusCode == 200) {
        // Parse the {"url": "..."} JSON from your server
        final data = jsonDecode(response.body);
        print("🎉 Backend successfully extracted URL!");
        return data['url']; 
      } else {
        print("❌ Backend returned an error: ${response.body}");
        return null;
      }
    } on TimeoutException {
      print("❌ Timeout: Make sure the Node server is running and your phone is on the same Wi-Fi!");
      return null;
    } catch (e) {
      print("❌ Critical error connecting to backend: $e");
      return null;
    }
  }

  YouTubeResult _handleSearchResponse(http.Response response) {
    if (response.statusCode == 403) {
      return const YouTubeQuotaExceeded();
    }
    if (response.statusCode != 200) {
      return YouTubeApiError(
        response.statusCode,
        'YouTube API returned status ${response.statusCode}',
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>? ?? [];
      final videos = items
          .map((e) => YouTubeVideo.fromSearchJson(e as Map<String, dynamic>))
          .where((v) => v.videoId.isNotEmpty)
          .toList();

      return YouTubeSearchSuccess(
        videos,
        nextPageToken: body['nextPageToken']?.toString(),
      );
    } catch (e) {
      return YouTubeApiError(0, 'Failed to parse response: $e');
    }
  }

  YouTubeResult _handleDetailsResponse(http.Response response) {
    if (response.statusCode == 403) {
      return const YouTubeQuotaExceeded();
    }
    if (response.statusCode != 200) {
      return YouTubeApiError(
        response.statusCode,
        'YouTube API returned status ${response.statusCode}',
      );
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>? ?? [];
      final videos = items
          .map((e) => YouTubeVideo.fromDetailsJson(e as Map<String, dynamic>))
          .where((v) => v.videoId.isNotEmpty)
          .toList();

      return YouTubeDetailsSuccess(videos);
    } catch (e) {
      return YouTubeApiError(0, 'Failed to parse response: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}