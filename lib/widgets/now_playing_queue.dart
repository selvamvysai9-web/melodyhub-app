import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../theme.dart';

class NowPlayingQueue extends StatelessWidget {
  const NowPlayingQueue({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final playlist = provider.playlist;
        if (playlist.isEmpty) {
          return DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.7,
            builder: (_, scrollController) => const Center(
                child: Text('Queue is empty',
                    style: TextStyle(color: AppTheme.textMuted))),
          );
        }
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Playing Next',
                          style: TextStyle(
                            color: AppTheme.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${playlist.length} songs',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: playlist.length,
                      itemBuilder: (context, index) {
                        final song = playlist[index];
                        final isCurrent = index == provider.currentIndex;
                        return _QueueItem(
                          song: song,
                          index: index,
                          isCurrent: isCurrent,
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

class _QueueItem extends StatelessWidget {
  final Song song;
  final int index;
  final bool isCurrent;
  const _QueueItem(
      {required this.song, required this.index, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MusicProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: song.effectiveAlbumArt,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (ctx, url) => Container(
                  color: AppTheme.surfaceHighlight,
                  child: const Icon(Icons.music_note,
                      color: AppTheme.textMuted, size: 20)),
              errorWidget: (ctx, url, err) => Container(
                  color: AppTheme.surfaceHighlight,
                  child: const Icon(Icons.music_note,
                      color: AppTheme.textMuted, size: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    color: isCurrent ? AppTheme.accent : AppTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => provider.playSong(index),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHighlight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: isCurrent ? AppTheme.accent : AppTheme.text,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
