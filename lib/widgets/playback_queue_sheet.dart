import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../theme/aurora_theme.dart';

void showPlaybackQueueSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const PlaybackQueueSheet(),
  );
}

class PlaybackQueueSheet extends StatelessWidget {
  const PlaybackQueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Consumer<MusicProvider>(
          builder: (context, provider, _) {
            final playlist = provider.playlist;
            return Container(
              decoration: const BoxDecoration(
                color: AuroraTheme.darkSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AuroraTheme.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Text(
                          'Queue',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AuroraTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${playlist.length} tracks',
                          style: const TextStyle(fontSize: 13, color: AuroraTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (playlist.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Queue is empty',
                          style: TextStyle(color: AuroraTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
                        itemCount: playlist.length,
                        itemBuilder: (context, index) {
                          final song = playlist[index];
                          final isCurrent = index == provider.currentIndex;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.effectiveAlbumArt.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: song.effectiveAlbumArt,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => _artPlaceholder(),
                                    )
                                  : _artPlaceholder(),
                            ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCurrent ? AuroraTheme.accentCyan : AuroraTheme.textPrimary,
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
                            trailing: isCurrent
                                ? const Icon(Icons.equalizer_rounded, color: AuroraTheme.accentCyan, size: 22)
                                : null,
                            onTap: () {
                              provider.playSong(index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Widget _artPlaceholder() {
  return Container(
    width: 48,
    height: 48,
    color: AuroraTheme.glassLight,
    child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22),
  );
}
