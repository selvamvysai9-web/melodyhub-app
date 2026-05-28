import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discover_track.dart';
import '../models/youtube_video.dart';
import '../providers/music_provider.dart';
import '../repositories/gemini_repository.dart';
import '../services/youtube_service.dart';
import 'ai_provider.dart';
import 'youtube_provider.dart';

class DiscoverState {
  final bool isLoadingAi;
  final bool isResolvingTracks;
  final String? errorMessage;
  final String playlistTitle;
  final String summary;
  final List<DiscoverTrack> tracks;
  final DateTime? generatedAt;

  const DiscoverState({
    this.isLoadingAi = false,
    this.isResolvingTracks = false,
    this.errorMessage,
    this.playlistTitle = 'Made for You',
    this.summary = '',
    this.tracks = const [],
    this.generatedAt,
  });

  List<Song> get playableSongs =>
      tracks.where((t) => t.song != null).map((t) => t.song!).toList();

  bool get hasPlayableTracks => playableSongs.isNotEmpty;

  DiscoverState copyWith({
    bool? isLoadingAi,
    bool? isResolvingTracks,
    String? errorMessage,
    String? playlistTitle,
    String? summary,
    List<DiscoverTrack>? tracks,
    DateTime? generatedAt,
    bool clearError = false,
  }) {
    return DiscoverState(
      isLoadingAi: isLoadingAi ?? this.isLoadingAi,
      isResolvingTracks: isResolvingTracks ?? this.isResolvingTracks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      playlistTitle: playlistTitle ?? this.playlistTitle,
      summary: summary ?? this.summary,
      tracks: tracks ?? this.tracks,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  DiscoverNotifier(this._gemini, this._youtube) : super(const DiscoverState());

  final GeminiRepository _gemini;
  final YouTubeService _youtube;

  static const _cacheKey = 'discover_cache_v1';
  static const _cacheTtl = Duration(hours: 24);

  Future<void> load({
    required List<Song> recentlyPlayed,
    required List<Song> catalogFallback,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _loadCache();
      if (cached != null) {
        state = cached;
        return;
      }
    }

    final seeds = _buildSeedList(recentlyPlayed, catalogFallback);
    if (seeds.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Listen to a few songs first, then come back for personalized picks.',
      );
      return;
    }

    state = state.copyWith(isLoadingAi: true, clearError: true);
    final recentLabels = seeds.map((s) => '${s.title} — ${s.artist}').toList();

    final aiResult = await _gemini.discoverRecommendations(recentLabels);
    if (aiResult is GeminiDiscoverReply) {
      state = state.copyWith(
        isLoadingAi: false,
        isResolvingTracks: true,
        playlistTitle: aiResult.playlistTitle,
        summary: aiResult.summary,
        tracks: aiResult.tracks,
        generatedAt: DateTime.now(),
      );

      final resolved = await _resolveTracksOnYouTube(aiResult.tracks);
      state = state.copyWith(
        isResolvingTracks: false,
        tracks: resolved,
        generatedAt: DateTime.now(),
      );
      await _saveCache(state);
    } else {
      // Fallback: use YouTube search from listening history
      await _fallbackDiscover(seeds);
    }
  }

  List<Song> _buildSeedList(List<Song> recent, List<Song> fallback) {
    if (recent.isNotEmpty) return recent.take(15).toList();
    if (fallback.isNotEmpty) return fallback.take(8).toList();
    return const [];
  }

  Future<List<DiscoverTrack>> _resolveTracksOnYouTube(List<DiscoverTrack> tracks) async {
    final resolved = <DiscoverTrack>[];

    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final query = '${track.title} ${track.artist}'.trim();
      if (query.isEmpty) {
        resolved.add(track);
        continue;
      }

      final result = await _youtube.search(query: query, maxResults: 3);
      Song? song;
      if (result is YouTubeSearchSuccess && result.videos.isNotEmpty) {
        final video = _pickBestMatch(track, result.videos);
        song = _songFromVideo(video);
      }

      resolved.add(track.copyWith(song: song));

      // Gentle pacing for YouTube API quota
      if (i < tracks.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    return resolved;
  }

  Future<void> _fallbackDiscover(List<Song> seeds) async {
    final random = Random();
    final pickCount = min(seeds.length, 4);
    final picked = List.from(seeds)..shuffle(random);
    final used = picked.take(pickCount).toList();

    final fallbackTracks = <DiscoverTrack>[];
    for (final seed in used) {
      final terms = '${seed.title} ${seed.artist}'.trim();
      final result = await _youtube.search(query: terms, maxResults: 5);
      if (result is YouTubeSearchSuccess && result.videos.length > 1) {
        for (var j = 1; j < result.videos.length && fallbackTracks.length < 10; j++) {
          final v = result.videos[j];
          fallbackTracks.add(DiscoverTrack(
            title: v.title,
            artist: v.channelTitle,
            reason: 'Because you listened to ${seed.title}',
            song: _songFromVideo(v),
          ));
        }
      }
      if (fallbackTracks.length >= 10) break;
    }

    if (fallbackTracks.isEmpty) {
      state = state.copyWith(
        isLoadingAi: false,
        errorMessage: 'Could not find recommendations right now. Try again later.',
      );
      return;
    }

    state = state.copyWith(
      isLoadingAi: false,
      isResolvingTracks: false,
      playlistTitle: 'Similar to Your Favorites',
      summary: 'Tracks picked from your listening history',
      tracks: fallbackTracks.take(10).toList(),
      generatedAt: DateTime.now(),
    );
    await _saveCache(state);
  }

  YouTubeVideo _pickBestMatch(DiscoverTrack track, List<YouTubeVideo> videos) {
    final titleLower = track.title.toLowerCase();
    for (final v in videos) {
      if (v.title.toLowerCase().contains(titleLower)) return v;
    }
    return videos.first;
  }

  Song _songFromVideo(YouTubeVideo video) => Song(
        id: 'discover_${video.videoId}',
        title: video.title,
        artist: video.channelTitle,
        youtubeId: video.videoId,
        albumArt: video.bestThumbnail,
        duration: video.duration ?? Duration.zero,
      );

  Future<DiscoverState?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(map['cachedAt'] as String? ?? '');
      if (cachedAt == null || DateTime.now().difference(cachedAt) > _cacheTtl) {
        return null;
      }

      final tracks = (map['tracks'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) {
            final m = Map<String, dynamic>.from(e);
            Song? song;
            final songMap = m['song'] as Map<String, dynamic>?;
            if (songMap != null) {
              song = Song.fromJson(songMap);
            }
            return DiscoverTrack(
              title: m['title'] as String? ?? '',
              artist: m['artist'] as String? ?? '',
              reason: m['reason'] as String? ?? '',
              song: song,
            );
          })
          .toList();

      return DiscoverState(
        playlistTitle: map['playlistTitle'] as String? ?? 'Made for You',
        summary: map['summary'] as String? ?? '',
        tracks: tracks,
        generatedAt: cachedAt,
      );
    } catch (e) {
      debugPrint('Discover cache load failed: $e');
      return null;
    }
  }

  Future<void> _saveCache(DiscoverState snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'cachedAt': DateTime.now().toIso8601String(),
        'playlistTitle': snapshot.playlistTitle,
        'summary': snapshot.summary,
        'tracks': snapshot.tracks
            .map((t) => {
                  'title': t.title,
                  'artist': t.artist,
                  'reason': t.reason,
                  if (t.song != null) 'song': t.song!.toJson(),
                })
            .toList(),
      };
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Discover cache save failed: $e');
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}

final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier(
    ref.watch(geminiRepositoryProvider),
    ref.watch(youtubeServiceProvider),
  );
});
