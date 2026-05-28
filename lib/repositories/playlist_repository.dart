import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/discover_track.dart';

class PlaylistRepository {
  final FirebaseFirestore _firestore;

  PlaylistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveMixToLibrary({
    required String uid,
    required String playlistTitle,
    required String summary,
    required List<DiscoverTrack> tracks,
  }) async {
    final playable = tracks.where((t) => t.song != null).toList();
    if (playable.isEmpty) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('playlist_library')
        .doc('data');

    final existing = await docRef.get();
    final existingPlaylists = existing.exists
        ? List<Map<String, dynamic>>.from(
            (existing.data()?['playlists'] as List<dynamic>?) ?? [])
        : <Map<String, dynamic>>[];

    final newPlaylist = {
      'id': 'discover_${DateTime.now().millisecondsSinceEpoch}',
      'title': playlistTitle,
      'summary': summary,
      'createdAt': FieldValue.serverTimestamp(),
      'tracks': playable
          .map((t) => {
                'title': t.title,
                'artist': t.artist,
                'reason': t.reason,
                'videoId': t.song!.youtubeId,
                'thumbnail': t.song!.albumArt,
              })
          .toList(),
    };

    existingPlaylists.insert(0, newPlaylist);

    await docRef.set({
      'playlists': existingPlaylists,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetch user's playlist library document (used by PlaylistProvider for sync).
  Future<Map<String, dynamic>?> fetch(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('playlist_library')
          .doc('data')
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Save user's playlist library document (used by PlaylistProvider for sync).
  Future<void> save(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('playlist_library')
        .doc('data')
        .set(data, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> loadUserPlaylists(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('playlist_library')
          .doc('data')
          .get();

      if (!doc.exists) return [];
      return List<Map<String, dynamic>>.from(
          (doc.data()?['playlists'] as List<dynamic>?) ?? []);
    } catch (_) {
      return [];
    }
  }
}
