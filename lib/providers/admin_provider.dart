import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/firebase_auth_provider.dart';

class AdminState {
  final bool isAdmin;
  final bool isLoading;
  final String? errorMessage;
  final int songCount;
  final int userCount;

  const AdminState({
    this.isAdmin = false,
    this.isLoading = true,
    this.errorMessage,
    this.songCount = 0,
    this.userCount = 0,
  });

  AdminState copyWith({
    bool? isAdmin,
    bool? isLoading,
    String? errorMessage,
    int? songCount,
    int? userCount,
    bool clearError = false,
  }) {
    return AdminState(
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      songCount: songCount ?? this.songCount,
      userCount: userCount ?? this.userCount,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final Ref _ref;
  ProviderSubscription<FirebaseAuthState>? _authSub;

  AdminNotifier(this._ref) : super(const AdminState()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSub = _ref.listen<FirebaseAuthState>(firebaseAuthProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated || next.status == AuthStatus.unauthenticated) {
        checkAdminStatus();
      }
    });
  }

  Future<void> checkAdminStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        state = state.copyWith(isAdmin: false, isLoading: false);
        return;
      }

      // Check if UID exists in the admins collection
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      final isAdmin = doc.exists;

      state = state.copyWith(isAdmin: isAdmin, isLoading: false);

      if (isAdmin) {
        await _loadStats();
      }
    } catch (e) {
      state = state.copyWith(isAdmin: false, isLoading: false, errorMessage: '$e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final songsSnap = await firestore.collection('songs').count().get();
      final usersSnap = await firestore.collection('users').count().get();
      state = state.copyWith(
        songCount: songsSnap.count ?? 0,
        userCount: usersSnap.count ?? 0,
      );
    } catch (_) {}
  }

  /// Promote a user to admin by adding them to the admins collection
  Future<String?> promoteToAdmin(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('admins').doc(uid).set({
        'promotedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref);
});
