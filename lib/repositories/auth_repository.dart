import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  final UserProfile profile;
  const AuthSuccess(this.profile);
}

class AuthFailure extends AuthResult {
  final String code;
  final String message;
  const AuthFailure(this.code, this.message);
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('[AuthRepo] Starting Google Sign-In...');

      // Disconnect any previously signed-in user to force account picker
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AuthRepo] Google Sign-In cancelled by user.');
        return const AuthFailure('cancelled', 'Sign-in was cancelled.');
      }

      debugPrint('[AuthRepo] Google user: ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      debugPrint('[AuthRepo] Got Google Auth - idToken: ${googleAuth.idToken != null ? "present" : "NULL"}, accessToken: ${googleAuth.accessToken != null ? "present" : "NULL"}');

      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        debugPrint('[AuthRepo] CRITICAL: Both idToken and accessToken are null. '
            'This usually means the SHA-1 fingerprint is not registered in Firebase Console, '
            'or the google-services.json is missing oauth_client entries.');
        return const AuthFailure(
          'missing_token',
          'Google authentication tokens missing. Please ensure SHA-1 fingerprint is added to Firebase Console and google-services.json is updated.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('[AuthRepo] Signing in with Firebase credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthFailure('null_user', 'Sign-in completed but user data is missing.');
      }

      debugPrint('[AuthRepo] Firebase user: ${firebaseUser.email} (${firebaseUser.uid})');
      final profile = await _provisionUser(firebaseUser);
      debugPrint('[AuthRepo] User profile provisioned successfully.');
      return AuthSuccess(profile);
    } on PlatformException catch (e) {
      debugPrint('[AuthRepo] PlatformException: ${e.code} - ${e.message}');
      if (e.code == 'network_error') {
        return const AuthFailure('network', 'Network error. Check your connection.');
      }
      if (e.code == 'sign_in_aborted' || e.code == 'canceled' || e.code == 'sign_in_cancelled') {
        return const AuthFailure('cancelled', 'Sign-in was cancelled.');
      }
      // API exception code 10 = SHA-1 mismatch / missing OAuth config
      if (e.code == 'sign_in_failed' || e.message?.contains('10:') == true || e.message?.contains('ApiException: 10') == true) {
        return const AuthFailure(
          'config_error',
          'Google Sign-In configuration error (code 10). The SHA-1 fingerprint may not be registered in Firebase Console. Please add it and re-download google-services.json.',
        );
      }
      return AuthFailure('platform', e.message ?? 'A platform error occurred.');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthRepo] FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        return const AuthFailure('conflict', 'An account already exists with a different sign-in method.');
      }
      if (e.code == 'invalid-credential') {
        return const AuthFailure('invalid_credential', 'Invalid Google credentials. Try again.');
      }
      return AuthFailure(e.code, e.message ?? 'Authentication failed.');
    } on FirebaseException catch (e) {
      debugPrint('[AuthRepo] FirebaseException: ${e.code} - ${e.message}');
      return AuthFailure(e.code, e.message ?? 'A Firebase error occurred.');
    } catch (e, stack) {
      debugPrint('[AuthRepo] Unexpected error: $e');
      debugPrint('[AuthRepo] Stack: $stack');
      final msg = e.toString().toLowerCase();
      if (msg.contains('network') || msg.contains('timeout') || msg.contains('socket')) {
        return const AuthFailure('network', 'Network error. Check your connection.');
      }
      // Catch ApiException: 10 from google_sign_in
      if (msg.contains('apiexception: 10') || msg.contains('10:') || msg.contains('developer error')) {
        return const AuthFailure(
          'config_error',
          'Google Sign-In configuration error. The SHA-1 fingerprint is not registered in Firebase. Go to Firebase Console → Project Settings → Add fingerprint.',
        );
      }
      return AuthFailure('unknown', 'Something went wrong: ${e.toString()}');
    }
  }

  Future<UserProfile> _provisionUser(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      final data = Map<String, dynamic>.from(docSnapshot.data()!);
      data['uid'] = firebaseUser.uid;
      return UserProfile.fromFirestore(data);
    }

    final profile = UserProfile(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'User',
      email: firebaseUser.email ?? '',
      photoURL: firebaseUser.photoURL ?? '',
      createdAt: DateTime.now(),
      savedPlaylists: [],
    );

    await docRef.set(profile.toFirestore());
    return profile;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthFailure('null_user', 'Sign-in completed but user data is missing.');
      }
      final profile = await _provisionUser(firebaseUser);
      return AuthSuccess(profile);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(e.code, e.message ?? 'Authentication failed.');
    } catch (e) {
      return AuthFailure('unknown', e.toString());
    }
  }

  Future<AuthResult> signUpWithEmailAndPassword(String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const AuthFailure('null_user', 'Registration completed but user data is missing.');
      }
      try {
        await firebaseUser.updateDisplayName(displayName);
      } catch (_) {}
      final profile = await _provisionUser(firebaseUser);
      return AuthSuccess(profile);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(e.code, e.message ?? 'Registration failed.');
    } catch (e) {
      return AuthFailure('unknown', e.toString());
    }
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['uid'] = uid;
      return UserProfile.fromFirestore(data);
    } on FirebaseException {
      return null;
    }
  }
}
