import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_song.dart';
import '../models/youtube_video.dart';

sealed class SongRepositoryResult {
  const SongRepositoryResult();
}

class SongRepositorySuccess extends SongRepositoryResult {
  final List<FirestoreSong> songs;
  const SongRepositorySuccess(this.songs);
}

class PaginatedSongResult extends SongRepositoryResult {
  final List<FirestoreSong> songs;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  const PaginatedSongResult(this.songs, {this.lastDocument, this.hasMore = false});
}

class SongRepositoryError extends SongRepositoryResult {
  final String message;
  const SongRepositoryError(this.message);
}

class SongRepository {
  final FirebaseFirestore _firestore;
  static const int _pageSize = 20;

  SongRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _songsRef => _firestore.collection('songs');

  Future<PaginatedSongResult> fetchPaginated({DocumentSnapshot? startAfter}) async {
    try {
      var query = _songsRef
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final snapshot = await query.get();
      final docs = snapshot.docs;
      final songs = docs
          .map((doc) => FirestoreSong.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      return PaginatedSongResult(
        songs,
        lastDocument: docs.isNotEmpty ? docs.last : null,
        hasMore: docs.length >= _pageSize,
      );
    } on FirebaseException {
      return PaginatedSongResult([], hasMore: false);
    } catch (_) {
      return PaginatedSongResult([], hasMore: false);
    }
  }

  Future<SongRepositoryResult> fetchAll() async {
    try {
      final snapshot = await _songsRef
          .orderBy('createdAt', descending: true)
          .get();
      final songs = snapshot.docs
          .map((doc) => FirestoreSong.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
      return SongRepositorySuccess(songs);
    } on FirebaseException catch (e) {
      return SongRepositoryError(e.message ?? 'Firestore error');
    } catch (e) {
      return SongRepositoryError('$e');
    }
  }

  Future<SongRepositoryResult> search(String query) async {
    if (query.trim().isEmpty) return const SongRepositorySuccess([]);
    try {
      final q = query.toLowerCase();
      final snapshot = await _songsRef.get();
      final songs = snapshot.docs
          .map((doc) => FirestoreSong.fromFirestore(doc.data() as Map<String, dynamic>))
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              s.artist.toLowerCase().contains(q))
          .toList();
      return SongRepositorySuccess(songs);
    } on FirebaseException catch (e) {
      return SongRepositoryError(e.message ?? 'Firestore error');
    } catch (e) {
      return SongRepositoryError('$e');
    }
  }

  Future<SongRepositoryResult> addFromYouTube(
    YouTubeVideo video, {
    String language = 'en',
    String addedBy = '',
  }) async {
    try {
      final docRef = _songsRef.doc();
      final song = FirestoreSong(
        id: docRef.id,
        title: video.title,
        artist: video.channelTitle,
        youtubeId: video.videoId,
        albumArt: video.bestThumbnail,
        durationSeconds: video.duration?.inSeconds ?? 0,
        language: language,
        createdAt: DateTime.now(),
        addedBy: addedBy,
      );
      await docRef.set(song.toFirestore());
      return SongRepositorySuccess([song]);
    } on FirebaseException catch (e) {
      return SongRepositoryError(e.message ?? 'Firestore error');
    } catch (e) {
      return SongRepositoryError('$e');
    }
  }

  Future<SongRepositoryResult> delete(String songId) async {
    try {
      await _songsRef.doc(songId).delete();
      return const SongRepositorySuccess([]);
    } on FirebaseException catch (e) {
      return SongRepositoryError(e.message ?? 'Firestore error');
    } catch (e) {
      return SongRepositoryError('$e');
    }
  }

  Stream<List<FirestoreSong>> streamAll() {
    return _songsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirestoreSong.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
