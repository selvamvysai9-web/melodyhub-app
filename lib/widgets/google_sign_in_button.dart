import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/firebase_auth_provider.dart';
import '../theme/aurora_theme.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _handleSignIn(context, ref),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AuroraTheme.accentCyan,
                ),
              )
            : const Text(
                'G',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AuroraTheme.textPrimary,
                ),
              ),
        label: Text(
          isLoading ? 'Signing in...' : 'Continue with Google',
          style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AuroraTheme.textMuted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  VoidCallback _handleSignIn(BuildContext context, WidgetRef ref) {
    return () async {
      await ref.read(firebaseAuthProvider.notifier).signInWithGoogle();
      final state = ref.read(firebaseAuthProvider);

      if (!context.mounted) return;

      if (state.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (state.status == AuthStatus.error && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AuroraTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    };
  }
}
