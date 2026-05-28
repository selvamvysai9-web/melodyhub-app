import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'music_provider.dart';
import 'favorites_provider.dart';
import 'playlist_provider.dart';
import 'firebase_auth_provider.dart';

final musicProviderProvider = ChangeNotifierProvider<MusicProvider>((ref) {
  final provider = MusicProvider();
  provider.init();
  return provider;
});

final favoritesProvider = ChangeNotifierProvider<FavoritesProvider>((ref) {
  return FavoritesProvider();
});

final playlistProvider = ChangeNotifierProvider<PlaylistProvider>((ref) {
  final provider = PlaylistProvider();
  ref.listen<FirebaseAuthState>(firebaseAuthProvider, (previous, next) {
    final isCloudUser = next.status == AuthStatus.authenticated &&
        next.profile != null &&
        next.profile!.uid != 'guest' &&
        FirebaseAuth.instance.currentUser != null;
    provider.onAuthChanged(isCloudUser ? FirebaseAuth.instance.currentUser : null);
  }, fireImmediately: true);
  return provider;
});

final musicProvider = musicProviderProvider;
