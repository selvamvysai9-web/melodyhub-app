import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/music_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../providers/admin_provider.dart';
import '../services/download_service.dart';
import '../theme/aurora_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/glowing_orb.dart';
import '../widgets/sleep_timer_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthProvider);
    final profile = authState.profile;
    final adminState = ref.watch(adminProvider);
    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackground(),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
          const Text('ACCOUNT', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 24,
            color: AuroraTheme.glassLight,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.account_circle_rounded, color: AuroraTheme.textSecondary, size: 24),
              title: Text(profile?.displayName ?? 'Guest User', style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(profile?.email ?? 'Offline Session', style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AuroraTheme.textMuted, size: 18),
            ),
          ),
          const SizedBox(height: 24),
              const Text('LIBRARY', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 4),
                borderRadius: 24,
                color: AuroraTheme.glassLight,
                child: Column(
                  children: [
                    _buildStatsTile(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    ),
                    _buildTile(
                      Icons.download_rounded,
                      'Downloads',
                      'Manage offline songs',
                      onTap: () => _showDownloadsDialog(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    ),
                    _buildTile(
                      Icons.delete_outline_rounded,
                      'Clear cache',
                      'Free up storage space',
                      onTap: () => _confirmClearCache(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('PREFERENCES', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 4),
                borderRadius: 24,
                color: AuroraTheme.glassLight,
                child: Consumer<MusicProvider>(
                  builder: (context, music, _) {
                    final currentLang = music.language;
                    final langName = MusicProvider.availableLanguages.firstWhere(
                      (l) => l['code'] == currentLang,
                      orElse: () => {'code': 'all', 'name': 'All Languages'},
                    )['name']!;
                    return _buildTile(
                      Icons.language_rounded,
                      'Language',
                      langName,
                      onTap: () => _showLanguagePicker(context, music),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('PLAYBACK', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 4),
                borderRadius: 24,
                color: AuroraTheme.glassLight,
                child: Column(
                  children: [
                    _buildTile(
                      Icons.volume_up_rounded,
                      'Volume',
                      'Adjusted in full-screen player',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    ),
                    _buildTile(
                      Icons.timer_rounded,
                      'Sleep Timer',
                      'Auto-stop playback',
                      onTap: () => _showSleepTimerFromSettings(context),
                    ),
                  ],
                ),
              ),
              if (adminState.isAdmin)
                ...[
                  const SizedBox(height: 24),
                  const Text('DEVELOPER', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    borderRadius: 24,
                    color: AuroraTheme.glassLight,
                    child: _buildTile(
                      Icons.admin_panel_settings_rounded,
                      'Admin Panel',
                      'Manage songs & backend',
                      onTap: () => context.push('/admin'),
                    ),
                  ),
                ],
              const SizedBox(height: 24),
              const Text('ABOUT', style: TextStyle(color: AuroraTheme.accentCyan, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: const EdgeInsets.symmetric(vertical: 4),
                borderRadius: 24,
                color: AuroraTheme.glassLight,
                child: Column(
                  children: [
                    _buildTile(
                      Icons.info_outline_rounded,
                      'About',
                      'Melody Hub v1.0.0',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    ),
                    _buildTile(
                      Icons.music_note_rounded,
                      'Audio Sources',
                      'YouTube Music + SoundHelix',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.all(4),
                borderRadius: 20,
                color: AuroraTheme.accentPink.withValues(alpha: 0.1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AuroraTheme.accentPink.withValues(alpha: 0.3), width: 1.0),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AuroraTheme.accentPink, size: 22),
                  title: const Text('Sign Out', style: TextStyle(color: AuroraTheme.accentPink, fontSize: 15, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    await ref.read(firebaseAuthProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
              const SizedBox(height: 24),
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
          top: -100,
          right: -40,
          child: GlowingOrb(
            size: 260,
            color: AuroraTheme.accentCyan.withValues(alpha: 0.12),
            blurRadius: 100,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -40,
          child: GlowingOrb(
            size: 200,
            color: AuroraTheme.accentPurple.withValues(alpha: 0.1),
            blurRadius: 80,
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context, MusicProvider music) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraTheme.darkSurface,
        title: const Text('Select Language', style: TextStyle(color: AuroraTheme.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: MusicProvider.availableLanguages.map((lang) {
              final code = lang['code']!;
              final name = lang['name']!;
              final isSelected = music.language == code;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.textMuted,
                  size: 20,
                ),
                title: Text(name, style: TextStyle(color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.textPrimary, fontSize: 14)),
                onTap: () {
                  music.setLanguage(code);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AuroraTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTile(BuildContext context) {
    return Consumer3<MusicProvider, FavoritesProvider, PlaylistProvider>(
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
    );
  }

  Widget _buildTile(IconData icon, String title, String? subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: AuroraTheme.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 11)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AuroraTheme.textMuted, size: 18),
      onTap: onTap,
    );
  }

  Future<void> _showDownloadsDialog(BuildContext context) async {
    final count = await DownloadService.getDownloadCount();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraTheme.darkSurface,
        title: const Text('Downloads', style: TextStyle(color: AuroraTheme.textPrimary)),
        content: Text('$count song(s) stored offline', style: const TextStyle(color: AuroraTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AuroraTheme.textMuted))),
          if (count > 0)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _confirmDeleteAllDownloads(context);
              },
              child: const Text('Delete All', style: TextStyle(color: AuroraTheme.accentPink)),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAllDownloads(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraTheme.darkSurface,
        title: const Text('Delete All Downloads', style: TextStyle(color: AuroraTheme.textPrimary)),
        content: const Text('This will remove all offline songs. Continue?', style: TextStyle(color: AuroraTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AuroraTheme.textMuted))),
          TextButton(
            onPressed: () async {
              try {
                final dir = await getApplicationDocumentsDirectory();
                final songDir = Directory('${dir.path}/melody_hub/downloads');
                if (await songDir.exists()) await songDir.delete(recursive: true);
                if (context.mounted) {
                  context.read<MusicProvider>().refreshDownloadCount();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All downloads deleted'), backgroundColor: AuroraTheme.accentCyan));
                }
              } catch (_) {}
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AuroraTheme.accentPink)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraTheme.darkSurface,
        title: const Text('Clear Cache', style: TextStyle(color: AuroraTheme.textPrimary)),
        content: const Text('This will clear cached images. Continue?', style: TextStyle(color: AuroraTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AuroraTheme.textMuted))),
          TextButton(
            onPressed: () async {
              try {
                await context.read<MusicProvider>().clearAllCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared'), backgroundColor: AuroraTheme.accentCyan));
                  Navigator.pop(ctx);
                }
              } catch (_) {}
            },
            child: const Text('Clear', style: TextStyle(color: AuroraTheme.accentCyan)),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerFromSettings(BuildContext context) {
    showDialog(context: context, builder: (_) => const SleepTimerDialog());
  }
}

