class YouTubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String highResThumbnailUrl;
  final Duration? duration;
  final int? viewCount;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    this.thumbnailUrl = '',
    this.highResThumbnailUrl = '',
    this.duration,
    this.viewCount,
  });

  String get bestThumbnail =>
      highResThumbnailUrl.isNotEmpty ? highResThumbnailUrl : thumbnailUrl;

  factory YouTubeVideo.fromSearchJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] is Map ? Map<String, dynamic>.from(json['snippet'] as Map) : <String, dynamic>{};
    final id = json['id'] is Map ? Map<String, dynamic>.from(json['id'] as Map) : <String, dynamic>{};
    final thumbnails = snippet['thumbnails'] is Map ? Map<String, dynamic>.from(snippet['thumbnails'] as Map) : <String, dynamic>{};

    return YouTubeVideo(
      videoId: id['videoId']?.toString() ?? '',
      title: snippet['title']?.toString() ?? 'Unknown',
      channelTitle: snippet['channelTitle']?.toString() ?? 'Unknown',
      thumbnailUrl: _extractThumbnail(thumbnails, 'default'),
      highResThumbnailUrl: _extractThumbnail(thumbnails, 'high'),
    );
  }

  factory YouTubeVideo.fromDetailsJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] is Map ? Map<String, dynamic>.from(json['snippet'] as Map) : <String, dynamic>{};
    final contentDetails = json['contentDetails'] is Map ? Map<String, dynamic>.from(json['contentDetails'] as Map) : <String, dynamic>{};
    final statistics = json['statistics'] is Map ? Map<String, dynamic>.from(json['statistics'] as Map) : <String, dynamic>{};
    final thumbnails = snippet['thumbnails'] is Map ? Map<String, dynamic>.from(snippet['thumbnails'] as Map) : <String, dynamic>{};

    return YouTubeVideo(
      videoId: json['id']?.toString() ?? '',
      title: snippet['title']?.toString() ?? 'Unknown',
      channelTitle: snippet['channelTitle']?.toString() ?? 'Unknown',
      thumbnailUrl: _extractThumbnail(thumbnails, 'default'),
      highResThumbnailUrl: _extractBestThumbnail(thumbnails),
      duration: _parseISODuration(contentDetails['duration']?.toString()),
      viewCount: int.tryParse(statistics['viewCount']?.toString() ?? ''),
    );
  }

  static String _extractThumbnail(Map<String, dynamic> thumbnails, String key) {
    final data = thumbnails[key] is Map ? Map<String, dynamic>.from(thumbnails[key] as Map) : null;
    if (data == null) return '';
    return data['url']?.toString() ?? '';
  }

  static String _extractBestThumbnail(Map<String, dynamic> thumbnails) {
    const priorities = ['maxres', 'high', 'medium', 'standard', 'default'];
    for (final key in priorities) {
      final url = _extractThumbnail(thumbnails, key);
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  static Duration? _parseISODuration(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(iso);
      if (match == null) return null;
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    } catch (_) {
      return null;
    }
  }
}
