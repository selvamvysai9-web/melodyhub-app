import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  GoogleSignInAccount? _account;
  bool _isSigningIn = false;
  String? _error;
  GoogleSignInAccount? get account => _account;
  bool get isSigningIn => _isSigningIn;
  String? get error => _error;
  bool get isSignedIn => _account != null;
  final GoogleSignIn _googleSignIn;
  AuthProvider()
    : _googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId:
                  '656877572942-tcp17e7809i4jhfpuf4ni9l07eat88r5.apps.googleusercontent.com',
            )
          : GoogleSignIn();
  Future<bool> signInWithGoogle() async {
    _isSigningIn = true;
    _error = null;
    notifyListeners();
    try {
      _account = await _googleSignIn.signIn();
      _isSigningIn = false;
      notifyListeners();
      return _account != null;
    } on Exception catch (e) {
      _account = null;
      _isSigningIn = false;
      _error = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _account = null;
    notifyListeners();
  }

  String _getErrorMessage(Exception e) {
    final msg = e.toString();
    if (msg.contains('network')) return 'Network error. Check your connection.';
    if (msg.contains('cancel') || msg.contains('abort')) return '';
    if (msg.contains('platform_exception') ||
        msg.contains('configuration') ||
        msg.contains('not_configured')) {
      return 'Google Sign-In not configured. Set up Google Cloud project.';
    }
    return 'Google Sign-In failed. Try again.';
  }
}
