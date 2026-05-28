import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firestore_song.dart';
import '../models/youtube_video.dart';
import '../repositories/song_repository.dart';

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository();
});

class SongLibraryState {
  final List<FirestoreSong> songs;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String currentQuery;
  final DocumentSnapshot? lastDocument;

  const SongLibraryState({
    this.songs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.currentQuery = '',
    this.lastDocument,
  });

  SongLibraryState copyWith({
    List<FirestoreSong>? songs,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    String? currentQuery,
    DocumentSnapshot? lastDocument,
    bool clearError = false,
  }) {
    return SongLibraryState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentQuery: currentQuery ?? this.currentQuery,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }

  List<FirestoreSong> get filteredByQuery {
    if (currentQuery.isEmpty) return songs;
    final q = currentQuery.toLowerCase();
    return songs.where((s) =>
        s.title.toLowerCase().contains(q) ||
        s.artist.toLowerCase().contains(q)).toList();
  }
}

class SongLibraryNotifier extends StateNotifier<SongLibraryState> {
  final SongRepository _repository;

  SongLibraryNotifier(this._repository) : super(const SongLibraryState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.fetchPaginated();
    state = state.copyWith(
      songs: result.songs,
      isLoading: false,
      hasMore: result.hasMore,
      lastDocument: result.lastDocument,
      errorMessage: result.songs.isEmpty ? 'No songs found' : null,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final result = await _repository.fetchPaginated(
      startAfter: state.lastDocument,
    );
    state = state.copyWith(
      songs: [...state.songs, ...result.songs],
      isLoadingMore: false,
      hasMore: result.hasMore,
      lastDocument: result.lastDocument,
    );
  }

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, currentQuery: query);
    if (query.trim().isEmpty) {
      await fetchAll();
      return;
    }
    final result = await _repository.search(query);
    if (result is SongRepositorySuccess) {
      state = state.copyWith(songs: result.songs, isLoading: false, hasMore: false);
    } else if (result is SongRepositoryError) {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
    }
  }

  Future<bool> addFromYouTube(YouTubeVideo video, {String language = 'en'}) async {
    final result = await _repository.addFromYouTube(video, language: language);
    return result is SongRepositorySuccess;
  }

  Future<bool> delete(String songId) async {
    final result = await _repository.delete(songId);
    if (result is SongRepositorySuccess) {
      state = state.copyWith(
        songs: state.songs.where((s) => s.id != songId).toList(),
      );
      return true;
    }
    return false;
  }

  void setQuery(String query) {
    state = state.copyWith(currentQuery: query);
  }
}

final songLibraryProvider =
    StateNotifierProvider<SongLibraryNotifier, SongLibraryState>(
  (ref) {
    final repository = ref.watch(songRepositoryProvider);
    return SongLibraryNotifier(repository);
  },
);

final songStreamProvider = StreamProvider<List<FirestoreSong>>((ref) {
  final repo = ref.watch(songRepositoryProvider);
  return repo.streamAll();
});
