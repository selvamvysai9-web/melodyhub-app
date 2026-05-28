import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/music_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/playlist_provider.dart';
import '../theme/aurora_theme.dart';
import '../widgets/glowing_orb.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthProvider);
    final profile = authState.profile;
    final photoUrl = profile?.photoURL;

    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AuroraTheme.oledBlack,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AuroraTheme.textSecondary),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AuroraTheme.glassLight,
                    backgroundImage: photoUrl != null
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person_rounded, size: 48, color: AuroraTheme.textMuted)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile?.displayName ?? 'Guest',
                    style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.email ?? 'Not signed in',
                    style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 14),
                  ),
                  if (authState.status != AuthStatus.authenticated) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign In'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 32),
              const Text('YOUR LIBRARY', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Consumer3<MusicProvider, FavoritesProvider, PlaylistProvider>(
                builder: (context, music, fav, playlists, _) {
                  final totalSongs = music.playlist.length;
                  final liked = fav.count;
                  final plCount = playlists.playlists.length;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: const Icon(Icons.library_music_rounded, color: AuroraTheme.textSecondary, size: 22),
                    title: const Text('Library Stats', style: TextStyle(color: AuroraTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text('$totalSongs songs · $liked liked · $plCount playlists', style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 11)),
                  );
                },
              ),
              const Divider(color: AuroraTheme.textMuted, height: 1),
              Consumer<FavoritesProvider>(
                builder: (_, fav, __) => _buildStatRow(Icons.favorite_rounded, 'Liked Songs', '${fav.count}', iconColor: AuroraTheme.accentPink),
              ),
              const Divider(color: AuroraTheme.textMuted, height: 1),
              Consumer<PlaylistProvider>(
                builder: (_, pl, __) => _buildStatRow(Icons.playlist_play_rounded, 'Playlists', '${pl.playlists.length}'),
              ),
              const SizedBox(height: 32),
              const Text('MORE', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              _buildTile(Icons.settings_rounded, 'Settings', 'App preferences', onTap: () => context.push('/settings')),
              const Divider(color: AuroraTheme.textMuted, height: 1),
              _buildTile(Icons.info_outline_rounded, 'About', 'Melody Hub v1.0.0'),
              const Divider(color: AuroraTheme.textMuted, height: 1),
              if (authState.status == AuthStatus.authenticated)
                _buildTile(Icons.logout_rounded, 'Sign Out', null, onTap: () async {
                  await ref.read(firebaseAuthProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -30,
          child: GlowingOrb(
            size: 150,
            color: AuroraTheme.accentPurple.withValues(alpha: 0.1),
            blurRadius: 50,
          ),
        ),
        Positioned(
          bottom: -50,
          left: -30,
          child: GlowingOrb(
            size: 150,
            color: AuroraTheme.accentCyan.withValues(alpha: 0.1),
            blurRadius: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, {Color? iconColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: iconColor ?? AuroraTheme.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 15)),
      trailing: Text(value, style: const TextStyle(color: AuroraTheme.accentCyan, fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTile(IconData icon, String title, String? subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: AuroraTheme.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AuroraTheme.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
