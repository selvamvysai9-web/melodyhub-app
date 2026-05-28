import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/discover_track.dart';

class GeminiResult {
  const GeminiResult();
}

class GeminiReply extends GeminiResult {
  final String text;
  const GeminiReply(this.text);
}

class GeminiMoodReply extends GeminiResult {
  final String mood;
  final String rationale;
  final String primaryHex;
  final String secondaryHex;
  const GeminiMoodReply({
    required this.mood,
    required this.rationale,
    required this.primaryHex,
    required this.secondaryHex,
  });
}

class GeminiEnrichReply extends GeminiResult {
  final String lyrics;
  final String genre;
  final String mood;
  final int year;
  final List<String> tags;
  const GeminiEnrichReply({
    required this.lyrics,
    required this.genre,
    required this.mood,
    required this.year,
    required this.tags,
  });
}

class GeminiError extends GeminiResult {
  final String message;
  const GeminiError(this.message);
}

class GeminiDiscoverReply extends GeminiResult {
  final String playlistTitle;
  final String summary;
  final List<DiscoverTrack> tracks;

  const GeminiDiscoverReply({
    required this.playlistTitle,
    required this.summary,
    required this.tracks,
  });
}

class GeminiRepository {
  String get _workerUrl =>
      dotenv.env['GEMINI_WORKER_URL']?.trim().isNotEmpty == true
          ? dotenv.env['GEMINI_WORKER_URL']!.trim()
          : 'https://melody-hub-ai.your-username.workers.dev';

  /// Search YouTube videos via Cloudflare Worker backend
  Future<List<Map<String, dynamic>>> searchYouTube(String query, {String language = 'en', int maxResults = 15}) async {
    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mode': 'search',
          'query': query,
          'maxResults': maxResults,
          'lang': language,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        return results.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<GeminiResult> chat(String prompt) async {
    return _post({'prompt': prompt, 'mode': 'chat'}, (data) {
      final reply = data['reply']?.toString();
      if (reply != null && reply.isNotEmpty) {
        return GeminiReply(reply);
      }
      return const GeminiError('Empty response from server.');
    });
  }

  Future<GeminiResult> analyzeMood(String prompt) async {
    return _post({'prompt': prompt, 'mode': 'mood'}, (data) {
      return GeminiMoodReply(
        mood: data['mood'] ?? 'neutral',
        rationale: data['rationale'] ?? '',
        primaryHex: data['primary_hex'] ?? '#050505',
        secondaryHex: data['secondary_hex'] ?? '#0A0A0F',
      );
    });
  }

  /// Discover Weekly–style recommendations from listening history.
  Future<GeminiResult> discoverRecommendations(List<String> recentlyPlayed) async {
    final lines = recentlyPlayed
        .where((s) => s.trim().isNotEmpty)
        .take(20)
        .toList();

    return _post(
      {
        'mode': 'discover',
        'prompt': lines.isEmpty
            ? 'Suggest a diverse starter mix for a new listener.'
            : 'Build my Discover playlist from my recent listening.',
        'recently_played': lines,
      },
      (data) {
        final rawTracks = data['tracks'] as List<dynamic>? ?? [];
        final tracks = rawTracks
            .whereType<Map>()
            .map((e) {
              final map = Map<String, dynamic>.from(e);
              return DiscoverTrack(
                title: map['title']?.toString() ?? '',
                artist: map['artist']?.toString() ?? '',
                reason: map['reason']?.toString() ?? '',
              );
            })
            .where((t) => t.title.isNotEmpty)
            .take(10)
            .toList();

        return GeminiDiscoverReply(
          playlistTitle: data['playlist_title']?.toString() ?? 'Made for You',
          summary: data['summary']?.toString() ?? '',
          tracks: tracks,
        );
      },
    );
  }

  Future<GeminiResult> enrichSong(String title, String artist) async {
    return _post(
        {'prompt': 'Enrich song: $title by $artist', 'mode': 'enrich'},
        (data) {
      return GeminiEnrichReply(
        lyrics: data['lyrics'] ?? '',
        genre: data['genre'] ?? '',
        mood: data['mood'] ?? 'neutral',
        year: data['year'] ?? 2024,
        tags: List<String>.from(data['tags'] ?? []),
      );
    });
  }

  Future<GeminiResult> _post(
    Map<String, dynamic> body,
    GeminiResult Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('error')) {
          return GeminiError(data['error'].toString());
        }
        return parser(data);
      } else {
        return GeminiError('Server error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      return GeminiError('Network error: ${e.message}');
    } catch (e) {
      return GeminiError('Unexpected error: $e');
    }
  }
}
