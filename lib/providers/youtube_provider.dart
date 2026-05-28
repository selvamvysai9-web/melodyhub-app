import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';

final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  final service = YouTubeService(apiKey: dotenv.get('YOUTUBE_API_KEY'));
  ref.onDispose(() => service.dispose());
  return service;
});

class YouTubeSearchState {
  final List<YouTubeVideo> videos;
  final bool isLoading;
  final String? errorMessage;
  final String? nextPageToken;
  final String currentQuery;
  final bool hasMorePages;

  const YouTubeSearchState({
    this.videos = const [],
    this.isLoading = false,
    this.errorMessage,
    this.nextPageToken,
    this.currentQuery = '',
    this.hasMorePages = false,
  });

  YouTubeSearchState copyWith({
    List<YouTubeVideo>? videos,
    bool? isLoading,
    String? errorMessage,
    String? nextPageToken,
    String? currentQuery,
    bool? hasMorePages,
    bool clearError = false,
  }) {
    return YouTubeSearchState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      nextPageToken: nextPageToken ?? this.nextPageToken,
      currentQuery: currentQuery ?? this.currentQuery,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }
}

class YouTubeSearchNotifier extends StateNotifier<YouTubeSearchState> {
  final YouTubeService _service;

  YouTubeSearchNotifier(this._service) : super(const YouTubeSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const YouTubeSearchState();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      currentQuery: query,
      clearError: true,
      videos: [],
      nextPageToken: null,
    );

    final result = await _service.search(query: query);
    _processResult(result);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.nextPageToken == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _service.search(
      query: state.currentQuery,
      pageToken: state.nextPageToken,
    );
    _processResult(result, append: true);
  }

  void _processResult(YouTubeResult result, {bool append = false}) {
    switch (result) {
      case YouTubeSearchSuccess(videos: final newVideos, nextPageToken: final token):
        state = state.copyWith(
          videos: append ? [...state.videos, ...newVideos] : newVideos,
          isLoading: false,
          nextPageToken: token,
          hasMorePages: token != null,
        );
      case YouTubeQuotaExceeded():
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'YouTube quota exceeded. Try again later.',
        );
      case YouTubeNetworkError(message: final msg):
        state = state.copyWith(isLoading: false, errorMessage: msg);
      case YouTubeApiError(message: final msg):
        state = state.copyWith(isLoading: false, errorMessage: msg);
      default:
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unexpected error occurred.',
        );
    }
  }

  Future<YouTubeVideo?> getVideoDetails(String videoId) async {
    final result = await _service.getVideoDetails([videoId]);
    return switch (result) {
      YouTubeDetailsSuccess(videos: final videos) => videos.isNotEmpty ? videos.first : null,
      _ => null,
    };
  }

  void clear() {
    state = const YouTubeSearchState();
  }
}

final youtubeSearchProvider =
    StateNotifierProvider<YouTubeSearchNotifier, YouTubeSearchState>(
  (ref) {
    final service = ref.watch(youtubeServiceProvider);
    return YouTubeSearchNotifier(service);
  },
);
