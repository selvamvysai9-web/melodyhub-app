import '../providers/music_provider.dart';

/// AI-suggested track before/after YouTube resolution.
class DiscoverTrack {
  final String title;
  final String artist;
  final String reason;
  final Song? song;

  const DiscoverTrack({
    required this.title,
    required this.artist,
    this.reason = '',
    this.song,
  });

  DiscoverTrack copyWith({Song? song}) => DiscoverTrack(
        title: title,
        artist: artist,
        reason: reason,
        song: song ?? this.song,
      );

  bool get isResolved => song != null;
}
