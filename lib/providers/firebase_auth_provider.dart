import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class FirebaseAuthState {
  final AuthStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  const FirebaseAuthState({
    this.status = AuthStatus.initial,
    this.profile,
    this.errorMessage,
  });

  FirebaseAuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return FirebaseAuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class FirebaseAuthNotifier extends StateNotifier<FirebaseAuthState> {
  final AuthRepository _repository;
  StreamSubscription<User?>? _authSub;

  FirebaseAuthNotifier(this._repository) : super(const FirebaseAuthState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = _repository.authStateChanges.listen((user) async {
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearProfile: true,
          clearError: true,
        );
        return;
      }

      state = state.copyWith(status: AuthStatus.loading);

      try {
        if (user.email == 'selvamvysai9@gmail.com') {
          await FirebaseFirestore.instance.collection('admins').doc(user.uid).set({
            'promotedAt': FieldValue.serverTimestamp(),
            'email': user.email,
          }, SetOptions(merge: true));
        }

        final profile = await _repository.fetchUserProfile(user.uid);
        if (profile != null) {
          state = FirebaseAuthState(status: AuthStatus.authenticated, profile: profile);
        } else {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            errorMessage: 'Profile not found. Some features may be limited.',
          );
        }
      } catch (e) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: 'Could not load profile data: $e',
        );
      }
    });
  }

  Future<void> signInWithGoogle() async {
    if (state.status == AuthStatus.loading) return;

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    final result = await _repository.signInWithGoogle();
    switch (result) {
      case AuthSuccess(profile: final profile):
        state = FirebaseAuthState(status: AuthStatus.authenticated, profile: profile);
      case AuthFailure(code: final code, message: final message):
        state = state.copyWith(
          status: code == 'cancelled' ? AuthStatus.unauthenticated : AuthStatus.error,
          errorMessage: code == 'cancelled' ? null : message,
        );
    }
  }

  void continueAsGuest() {
    state = FirebaseAuthState(
      status: AuthStatus.authenticated,
      profile: UserProfile(
        uid: 'guest',
        displayName: 'Guest User',
        email: 'guest@melodyhub.online',
        photoURL: '',
        createdAt: DateTime.now(),
        savedPlaylists: const [],
      ),
    );
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    if (state.status == AuthStatus.loading) return;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final result = await _repository.signInWithEmailAndPassword(email, password);
    switch (result) {
      case AuthSuccess(profile: final profile):
        state = FirebaseAuthState(status: AuthStatus.authenticated, profile: profile);
      case AuthFailure(message: final message):
        state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    if (state.status == AuthStatus.loading) return;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    final result = await _repository.signUpWithEmailAndPassword(email, password, displayName);
    switch (result) {
      case AuthSuccess(profile: final profile):
        state = FirebaseAuthState(status: AuthStatus.authenticated, profile: profile);
      case AuthFailure(message: final message):
        state = state.copyWith(status: AuthStatus.error, errorMessage: message);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }


  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final firebaseAuthProvider = StateNotifierProvider<FirebaseAuthNotifier, FirebaseAuthState>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    return FirebaseAuthNotifier(repository);
  },
);
