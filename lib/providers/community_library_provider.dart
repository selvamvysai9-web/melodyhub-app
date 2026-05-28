import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudflare_search_service.dart';
import '../models/library_track.dart';
import '../providers/legacy_providers.dart';
import '../providers/firebase_auth_provider.dart';
import 'music_provider.dart';

class CommunityLibraryNotifier extends StateNotifier<AsyncValue<void>> {
  CommunityLibraryNotifier() : super(const AsyncValue.data(null));

  Future<void> playAndDualSave({
    required WorkerSearchResult track,
    required WidgetRef ref,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 1. Play the track immediately with full metadata in the audio provider
      final song = Song(
        id: 'yt_${track.videoId}',
        title: track.title,
        artist: track.artist,
        youtubeId: track.videoId,
        albumArt: track.thumbnail,
      );
      ref.read(musicProvider.notifier).playSongByReference(song);

      // 2. Fetch authenticated user details or fall back to Melody Hub User
      final authState = ref.read(firebaseAuthProvider);
      final profile = authState.profile;
      final uid = profile?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
      final displayName = (profile?.displayName != null && profile!.displayName.trim().isNotEmpty)
          ? profile.displayName
          : (FirebaseAuth.instance.currentUser?.displayName ?? 'Melody Hub User');

      // 3. Create track metadata representation
      final libraryTrack = LibraryTrack(
        title: track.title,
        artist: track.artist,
        videoId: track.videoId,
        thumbnail: track.thumbnail,
        addedBy: displayName,
      );

      final firestore = FirebaseFirestore.instance;

      // 4. Save concurrently to Personal and Community libraries in Firestore
      await Future.wait([
        // Personal save: users/{uid}/my_library/{videoId}
        firestore
            .collection('users')
            .doc(uid)
            .collection('my_library')
            .doc(track.videoId)
            .set(libraryTrack.toFirestore()),
        
        // Community save: global_library/{videoId}
        firestore
            .collection('global_library')
            .doc(track.videoId)
            .set(libraryTrack.toFirestore()),
      ]);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error during play & dual-save: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

final communityLibraryProvider = StateNotifierProvider<CommunityLibraryNotifier, AsyncValue<void>>((ref) {
  return CommunityLibraryNotifier();
});
