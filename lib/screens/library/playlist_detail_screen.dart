import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/music_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mini_player.dart';
class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistIndex});

  final int playlistIndex;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, plProvider, _) {
        if (playlistIndex < 0 || playlistIndex >= plProvider.playlists.length) {
          return Scaffold(
            backgroundColor: AuroraTheme.oledBlack,
            appBar: AppBar(backgroundColor: AuroraTheme.oledBlack),
            body: const Center(child: Text('Playlist not found', style: TextStyle(color: AuroraTheme.textMuted))),
          );
        }
        final playlist = plProvider.playlists[playlistIndex];
        final songs = playlist.songs;

        return Scaffold(
          backgroundColor: AuroraTheme.oledBlack,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor: AuroraTheme.oledBlack,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        playlist.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AuroraTheme.accentPurple.withValues(alpha: 0.35),
                              AuroraTheme.oledBlack,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.queue_music_rounded, size: 72, color: Colors.white24),
                        ),
                      ),
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AuroraTheme.textSecondary),
                        color: AuroraTheme.darkSurface,
                        onSelected: (value) {
                          if (value == 'rename') _renamePlaylist(context, plProvider, playlist.name);
                          if (value == 'delete') {
                            plProvider.deletePlaylist(playlistIndex);
                            context.pop();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: AuroraTheme.textPrimary))),
                          const PopupMenuItem(value: 'delete', child: Text('Delete playlist', style: TextStyle(color: AuroraTheme.accentPink))),
                        ],
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            '${songs.length} songs',
                            style: const TextStyle(color: AuroraTheme.textMuted, fontSize: 13),
                          ),
                          const Spacer(),
                          if (songs.isNotEmpty)
                            FilledButton.icon(
                              onPressed: () {
                                context.read<MusicProvider>().playQueue(songs);
                                context.push('/player');
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 22),
                              label: const Text('Play'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AuroraTheme.accentCyan,
                                foregroundColor: AuroraTheme.oledBlack,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (songs.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'Add songs from search or the player menu',
                          style: TextStyle(color: AuroraTheme.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = songs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(8),
                              borderRadius: 16,
                              color: AuroraTheme.glassLight,
                              child: ListTile(
                                leading: _albumArt(song),
                                title: Text(
                                  song.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AuroraTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  song.artist,
                                  style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_horiz_rounded, color: AuroraTheme.textMuted),
                                  color: AuroraTheme.darkSurface,
                                  onSelected: (v) {
                                    if (v == 'play') {
                                      context.read<MusicProvider>().playQueue(songs, startIndex: index);
                                      context.push('/player');
                                    }
                                    if (v == 'remove') {
                                      plProvider.removeSongFromPlaylist(playlistIndex, index);
                                    }
                                    if (v == 'like') {
                                      context.read<FavoritesProvider>().toggleLike(song);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'play', child: Text('Play', style: TextStyle(color: AuroraTheme.textPrimary))),
                                    PopupMenuItem(value: 'like', child: Text('Like', style: TextStyle(color: AuroraTheme.textPrimary))),
                                    PopupMenuItem(value: 'remove', child: Text('Remove from playlist', style: TextStyle(color: AuroraTheme.accentPink))),
                                  ],
                                ),
                                onTap: () {
                                  context.read<MusicProvider>().playQueue(songs, startIndex: index);
                                  context.push('/player');
                                },
                              ),
                            ),
                          );
                        },
                        childCount: songs.length,
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MiniPlayer(onTap: () => context.push('/player')),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renamePlaylist(BuildContext context, PlaylistProvider pl, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuroraTheme.darkSurface,
        title: const Text('Rename playlist', style: TextStyle(color: AuroraTheme.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AuroraTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && context.mounted) {
      pl.renamePlaylist(playlistIndex, newName);
    }
    controller.dispose();
  }

  Widget _albumArt(Song song) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: song.effectiveAlbumArt.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: song.effectiveAlbumArt,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: AuroraTheme.glassMedium,
      child: const Icon(Icons.music_note, color: AuroraTheme.textMuted),
    );
  }
}
