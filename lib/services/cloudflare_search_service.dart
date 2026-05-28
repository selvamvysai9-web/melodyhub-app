import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

class WorkerSearchResult {
  final String videoId;
  final String title;
  final String artist;
  final String thumbnail;

  const WorkerSearchResult({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.thumbnail,
  });

  factory WorkerSearchResult.fromJson(Map<String, dynamic> json) {
    return WorkerSearchResult(
      videoId: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }
}

class CloudflareSearchService {
  static const String _cfEndpoint = 'https://melody-hub-ai.melody-hub-api.workers.dev';

  Future<List<WorkerSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // Try Render backend first
    try {
      final resp = await http.get(
        Uri.parse('${BackendConfig.search(query)}&maxResults=15'),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List<dynamic> items = data is List ? data : (data['results'] ?? []);
        return items
            .map((e) => WorkerSearchResult.fromJson(e is Map<String, dynamic> ? e : {}))
            .where((r) => r.videoId.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    // Fall back to Cloudflare Worker
    try {
      final response = await http.post(
        Uri.parse(_cfEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mode': 'search', 'query': query, 'maxResults': 15}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          final resultsRaw = data['results'] as List<dynamic>? ?? [];
          return resultsRaw
              .map((item) => WorkerSearchResult.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
