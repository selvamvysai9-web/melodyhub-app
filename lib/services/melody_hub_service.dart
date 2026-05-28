import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

class SongData {
  final String id;
  final String title;
  final String artist;
  final String youtubeId;
  final String albumArt;
  final String audioPath;
  final String filePath;
  final String lyrics;
  final String language;

  SongData({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeId,
    required this.albumArt,
    this.audioPath = '',
    this.filePath = '',
    this.lyrics = '',
    this.language = 'en',
  });
}

class MelodyHubService {
  static String _customUrl = '';

  /// Backend URL — uses BackendConfig.baseUrl unless overridden at runtime.
  static String get baseUrl {
    if (_customUrl.isNotEmpty) return _customUrl;
    final envUrl = dotenv.env['RENDER_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return BackendConfig.baseUrl;
  }

  static set baseUrl(String url) => _customUrl = url;

  static String get youtubeApiKey {
    final key = dotenv.env['YOUTUBE_API_KEY']?.trim();
    if (key != null && key.isNotEmpty) return key;
    return '';
  }

  /// Fallback songs that work without any backend server.
  /// These are YouTube-based songs that stream via youtube_explode_dart.
  static const List<Map<String, String>> fallbackSongs = [
    {'id': 'f1', 'title': 'Blinding Lights', 'artist': 'The Weeknd', 'yt': '4NRXx6U8ABQ'},
    {'id': 'f2', 'title': 'Shape of You', 'artist': 'Ed Sheeran', 'yt': 'JGwWNGJdvx8'},
    {'id': 'f3', 'title': 'Bohemian Rhapsody', 'artist': 'Queen', 'yt': 'fJ9rUzIMcZQ'},
    {'id': 'f4', 'title': 'Believer', 'artist': 'Imagine Dragons', 'yt': '7wtfhZwyrcc'},
    {'id': 'f5', 'title': 'Sugar', 'artist': 'Maroon 5', 'yt': '09R8_2nJtjg'},
    {'id': 'f6', 'title': 'Let Me Love You', 'artist': 'DJ Snake', 'yt': 'S3JvF2JxbRU'},
    {'id': 'f7', 'title': 'See You Again', 'artist': 'Wiz Khalifa', 'yt': 'RgKAFK5djSk'},
    {'id': 'f8', 'title': 'Counting Stars', 'artist': 'OneRepublic', 'yt': 'hT_nvWreIhg'},
  ];

  /// Returns the YouTube video ID for fallback by index.
  static String getFallbackYtId(int index) {
    final i = index % fallbackSongs.length;
    return fallbackSongs[i]['yt']!;
  }

  /// Stable YouTube ID per track key.
  static String getFallbackYtIdForKey(String key) {
    if (key.isEmpty) return fallbackSongs[0]['yt']!;
    final i = key.hashCode.abs() % fallbackSongs.length;
    return fallbackSongs[i]['yt']!;
  }

  /// Stable demo MP3 URL per track key (uses a public domain audio sample).
  static String getFallbackMp3UrlForKey(String key) {
    // Deterministic hash-based URL using a public sample
    final samples = [
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    ];
    if (key.isEmpty) return samples[0];
    return samples[key.hashCode.abs() % samples.length];
  }

  static String fallbackAlbumArt(int index) {
    final ytId = getFallbackYtId(index);
    return 'https://i.ytimg.com/vi/$ytId/hqdefault.jpg';
  }

  /// Fetch playlist from local backend. Returns empty list if backend is unreachable.
  Future<List<SongData>> fetchPlaylist() async {
    try {
      final res = await http.get(Uri.parse(BackendConfig.songs));
      if (res.statusCode == 200) {
        final List<dynamic> items = jsonDecode(res.body);
        return items.map((item) {
          final id = item['id']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Unknown';
          final artist = item['singerName']?.toString() ?? 'Unknown';
          final ytId = item['youtube_id']?.toString() ?? '';
          final img = item['imagePath']?.toString() ?? '';
          final audioPath = item['audioPath']?.toString() ?? '';
          final filePath = item['filePath']?.toString() ?? '';
          final lyrics = item['lyrics']?.toString() ?? '';
          final language = item['language']?.toString() ?? 'en';
          final albumArt = img.isNotEmpty
              ? img
              : (ytId.isNotEmpty
                  ? 'https://i.ytimg.com/vi/$ytId/hqdefault.jpg'
                  : 'https://picsum.photos/seed/$id/300');
          return SongData(
            id: id,
            title: title.trim(),
            artist: artist.trim(),
            youtubeId: ytId,
            albumArt: albumArt,
            audioPath: audioPath,
            filePath: filePath,
            lyrics: lyrics,
            language: language,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<SongData>> searchYouTube(String query, {String language = 'en'}) async {
    try {
      final langMap = {
        'en': 'en', 'hi': 'hi', 'ta': 'ta', 'te': 'te',
        'ml': 'ml', 'kn': 'kn', 'es': 'es', 'ko': 'ko',
        'ja': 'ja', 'fr': 'fr', 'ar': 'ar',
      };
      final lang = langMap[language] ?? 'en';
      final url = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet&maxResults=15&q=$query&type=video'
        '&videoCategoryId=10&relevanceLanguage=$lang&key=$youtubeApiKey',
      );
      final res = await http.get(url);
      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      final items = data['items'] as List? ?? [];
      return items.map<SongData?>((item) {
        final snippet = item['snippet'];
        final videoId = item['id']?['videoId']?.toString();
        if (snippet == null || videoId == null) return null;
        return SongData(
          id: 'yt_$videoId',
          title: snippet['title']?.toString() ?? 'Unknown',
          artist: snippet['channelTitle']?.toString() ?? 'Unknown',
          youtubeId: videoId,
          albumArt: snippet['thumbnails']?['high']?['url']?.toString() ??
              'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
        );
      }).whereType<SongData>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> toggleLike(String songId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/index.php'),
        body: {'action': 'toggle_like', 'song_id': songId},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addToPlaylist(String songId, String playlistName) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/index.php'),
        body: {'action': 'add_to_playlist', 'song_id': songId, 'playlist': playlistName},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> savePreferences(String volume, String sortMode, String theme) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/index.php'),
        body: {'action': 'save_preferences', 'volume': volume, 'sort_mode': sortMode, 'theme': theme},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reportSong(String songId, String reason) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/index.php'),
        body: {'action': 'report_song', 'song_id': songId, 'reason': reason},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> autoSaveYt(String songId, String youtubeId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/index.php'),
        body: {'action': 'auto_save_yt', 'song_id': songId, 'youtube_id': youtubeId},
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> trackPlay(String title, String singerName, String youtubeId, String imagePath, {String language = 'en'}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/songs/track-play'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'singerName': singerName,
          'youtube_id': youtubeId,
          'imagePath': imagePath,
          'language': language,
        }),
      );
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> searchYouTubeVideos(String query, {String language = 'en'}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/youtube/search?q=${Uri.encodeComponent(query)}&lang=$language'));
      if (res.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(res.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addYoutubeVideo(String videoId, String title, String channelTitle, String thumbnail, {String language = 'en'}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/youtube/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'videoId': videoId,
          'title': title,
          'channelTitle': channelTitle,
          'thumbnail': thumbnail,
          'language': language,
        }),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
