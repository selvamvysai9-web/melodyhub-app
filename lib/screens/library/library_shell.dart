import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/music_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../models/library_track.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/add_to_playlist_sheet.dart';

class LibraryShell extends riverpod.ConsumerStatefulWidget {
  const LibraryShell({super.key});

  @override
  riverpod.ConsumerState<LibraryShell> createState() => _LibraryShellState();
}

class _LibraryShellState extends riverpod.ConsumerState<LibraryShell> {
  int _selectedTab = 0;
  static const _tabLabels = ['My Library', 'Playlists', 'Songs', 'Liked', 'Downloads'];

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();
    final songs = musicProvider.playlist;

    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(playlistProvider),
                const SizedBox(height: 16),
                _buildStats(songs.length, favoritesProvider.count, musicProvider.downloadCount),
                const SizedBox(height: 20),
                _buildSectionTabs(),
                const SizedBox(height: 12),
                Expanded(child: _buildTabContent(songs, favoritesProvider, musicProvider, playlistProvider)),
              ],
            ),
          ),
          // MiniPlayer at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MiniPlayer(onTap: () => context.push('/player')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PlaylistProvider playlistProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          const Text('Your Library', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary)),
          if (playlistProvider.cloudSyncEnabled) ...[
            const SizedBox(width: 8),
            if (playlistProvider.isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.accentCyan),
              )
            else
              Icon(
                playlistProvider.syncError ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                size: 18,
                color: playlistProvider.syncError ? AuroraTheme.accentOrange : AuroraTheme.accentGreen,
              ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Cycle sort mode
              final musicProvider = context.read<MusicProvider>();
              final modes = SongSortMode.values;
              final nextIndex = (musicProvider.sortMode.index + 1) % modes.length;
              musicProvider.setSortMode(modes[nextIndex]);
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AuroraTheme.glassLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.sort_rounded, color: AuroraTheme.textSecondary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int totalSongs, int totalFavorites, int totalDownloads) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _statCard('$totalSongs', 'Songs', AuroraTheme.accentCyan),
          const SizedBox(width: 12),
          _statCard('$totalFavorites', 'Favorites', AuroraTheme.accentPink),
          const SizedBox(width: 12),
          _statCard('$totalDownloads', 'Downloads', AuroraTheme.accentGreen),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      color: AuroraTheme.glassLight,
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AuroraTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _tabLabels.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedTab == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.glassLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _tabLabels[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AuroraTheme.oledBlack : AuroraTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(
    List songs,
    FavoritesProvider favoritesProvider,
    MusicProvider musicProvider,
    PlaylistProvider playlistProvider,
  ) {
    final authState = ref.watch(firebaseAuthProvider);
    final uid = authState.profile?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    switch (_selectedTab) {
      case 0:
        return _buildMyLibraryList(uid, musicProvider);
      case 1:
        return _buildPlaylistsList(playlistProvider);
      case 2:
        return _buildSongsList(musicProvider.sortedPlaylist, favoritesProvider, musicProvider);
      case 3:
        return _buildFavoritesList(favoritesProvider, musicProvider);
      case 4:
        return _buildDownloadsList(musicProvider);
      default:
        return _buildMyLibraryList(uid, musicProvider);
    }
  }

  Widget _buildMyLibraryList(String uid, MusicProvider musicProvider) {
    if (uid == 'guest' || uid.isEmpty) {
      return _buildEmptyState(
        Icons.cloud_off_rounded,
        'Offline library',
        'Sign in to sync your personalized library across devices.',
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('my_library')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AuroraTheme.accentCyan),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            Icons.error_outline_rounded,
            'Could not load My Library',
            'Please verify your connection and try again.',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(
            Icons.headphones_rounded,
            'Your library is empty',
            'Songs you search and play in the Discover tab will appear here!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final track = LibraryTrack.fromFirestore(data);
            final isPlaying = musicProvider.currentSong.youtubeId == track.videoId && musicProvider.isPlaying;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GlassContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: 16,
                color: AuroraTheme.glassLight,
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: track.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: track.thumbnail,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 48,
                              height: 48,
                              color: AuroraTheme.glassLight,
                              child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: AuroraTheme.glassMedium,
                              child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: AuroraTheme.glassMedium,
                            child: const Icon(Icons.music_note, color: AuroraTheme.textMuted),
                          ),
                  ),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? AuroraTheme.accentCyan : AuroraTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.artist,
                    style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                          color: AuroraTheme.accentCyan,
                          size: 28,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            musicProvider.playPause();
                          } else {
                            musicProvider.playSong(track.videoId);
                            context.push('/player');
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    musicProvider.playSong(track.videoId);
                    context.push('/player');
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistsList(PlaylistProvider playlistProvider) {
    final playlists = playlistProvider.playlists;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _createPlaylist(context, playlistProvider),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderRadius: 16,
                    color: AuroraTheme.glassLight,
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, color: AuroraTheme.accentCyan, size: 22),
                        SizedBox(width: 12),
                        Text('Create playlist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: playlists.isEmpty
              ? _buildEmptyState(
                  Icons.playlist_play_rounded,
                  'No playlists yet',
                  playlistProvider.cloudSyncEnabled
                      ? 'Create one — it will sync to your account'
                      : 'Sign in to sync playlists across devices',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 16,
                        color: AuroraTheme.glassLight,
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple],
                              ),
                            ),
                          ),
                          title: Text(pl.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${pl.songs.length} songs', style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted)),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle_rounded, color: AuroraTheme.accentCyan, size: 28),
                            onPressed: pl.songs.isEmpty
                                ? null
                                : () {
                                    context.read<MusicProvider>().playQueue(pl.songs);
                                    context.push('/player');
                                  },
                          ),
                          onTap: () => context.push('/playlist/$index'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context, PlaylistProvider provider) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraTheme.darkSurface,
        title: const Text('New playlist', style: TextStyle(color: AuroraTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AuroraTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'My playlist'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      provider.createPlaylist(name);
    }
    controller.dispose();
  }

  Widget _buildSongsList(List songs, FavoritesProvider favoritesProvider, MusicProvider musicProvider) {
    if (songs.isEmpty) {
      return _buildEmptyState(Icons.library_music_rounded, 'No songs yet', 'Songs will appear here as you listen');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isFav = favoritesProvider.isLiked(song.youtubeId);
        final isPlaying = musicProvider.isSongPlaying(song);
        return _buildSongTile(song, isFav, isPlaying, favoritesProvider, musicProvider);
      },
    );
  }

  Widget _buildFavoritesList(FavoritesProvider favoritesProvider, MusicProvider musicProvider) {
    final likedSongs = favoritesProvider.likedSongs;
    if (likedSongs.isEmpty) {
      return _buildEmptyState(Icons.favorite_rounded, 'No favorites yet', 'Tap the heart icon to save songs');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      itemCount: likedSongs.length,
      itemBuilder: (context, index) {
        final song = likedSongs[index];
        return _buildSongTile(
          song,
          true,
          musicProvider.isSongPlaying(song),
          favoritesProvider,
          musicProvider,
          onPlay: () => musicProvider.playSongByReference(song),
        );
      },
    );
  }

  Widget _buildDownloadsList(MusicProvider musicProvider) {
    final downloadedSongs = musicProvider.playlist.where((s) => musicProvider.isDownloaded(s.youtubeId)).toList();
    if (downloadedSongs.isEmpty) {
      return _buildEmptyState(Icons.download_rounded, 'No downloads yet', 'Download songs for offline listening');
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
      itemCount: downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadedSongs[index];
        final isPlaying = musicProvider.isSongPlaying(song);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 16,
            color: AuroraTheme.glassLight,
            child: ListTile(
              leading: _buildAlbumArt(song),
              title: Text(song.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isPlaying ? AuroraTheme.accentCyan : AuroraTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist, style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download_done_rounded, color: AuroraTheme.accentGreen, size: 20),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                      color: AuroraTheme.accentCyan,
                      size: 28,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        musicProvider.playPause();
                      } else {
                        musicProvider.playSongByReference(song);
                      }
                    },
                  ),
                ],
              ),
              onTap: () => musicProvider.playSongByReference(song),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongTile(Song song, bool isFav, bool isPlaying, FavoritesProvider favoritesProvider, MusicProvider musicProvider, {VoidCallback? onPlay}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassContainer(
        padding: const EdgeInsets.all(8),
        borderRadius: 16,
        color: AuroraTheme.glassLight,
        child: ListTile(
          leading: _buildAlbumArt(song),
          title: Text(
            song.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPlaying ? AuroraTheme.accentCyan : AuroraTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(song.artist, style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: isFav ? AuroraTheme.accentPink : AuroraTheme.textMuted, size: 22),
                onPressed: () => favoritesProvider.toggleLike(song),
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded, color: AuroraTheme.textMuted, size: 22),
                onPressed: () => showAddToPlaylistSheet(context, song),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: AuroraTheme.accentCyan,
                  size: 28,
                ),
                onPressed: onPlay ?? () {
                  if (isPlaying) {
                    musicProvider.playPause();
                  } else {
                    musicProvider.playSongByReference(song);
                  }
                },
              ),
            ],
          ),
          onTap: onPlay ?? () => musicProvider.playSongByReference(song),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: song.effectiveAlbumArt.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: song.effectiveAlbumArt,
              width: 48, height: 48, fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 48, height: 48, color: AuroraTheme.glassLight, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22)),
              errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AuroraTheme.glassMedium, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22)),
            )
          : Container(width: 48, height: 48, color: AuroraTheme.glassMedium, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted)),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AuroraTheme.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textSecondary)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AuroraTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
