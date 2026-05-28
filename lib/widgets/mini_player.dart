import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../theme/aurora_theme.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        if (provider.isPlaylistEmpty) return const SizedBox.shrink();
        final song = provider.currentSong;

        return GestureDetector(
          onTap: onTap,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
              onTap();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AuroraTheme.darkSurface.withValues(alpha: 0.95),
                  AuroraTheme.darkSurface.withValues(alpha: 0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: provider.isPlaying 
                    ? AuroraTheme.accentCyan.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: provider.isPlaying
                      ? AuroraTheme.accentCyan.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
                  child: Row(
                    children: [
                      // Album art with animated border when playing
                      Hero(
                        tag: 'album_art_transition',
                        child: _buildAlbumArt(song, provider.isPlaying),
                      ),
                      const SizedBox(width: 14),
                      // Song info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (provider.isPlaying)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: const BoxDecoration(
                                      color: AuroraTheme.accentCyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    song.title,
                                    style: const TextStyle(
                                      color: AuroraTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                color: AuroraTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Previous button
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: AuroraTheme.textPrimary, size: 26),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: provider.previous,
                      ),
                      // Play/Pause button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: provider.isPlaying
                                ? [AuroraTheme.accentCyan, AuroraTheme.accentCyan.withValues(alpha: 0.8)]
                                : [AuroraTheme.glassMedium, AuroraTheme.glassLight],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: provider.isPlaying
                                  ? AuroraTheme.accentCyan.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            provider.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: provider.isPlaying ? AuroraTheme.oledBlack : AuroraTheme.textPrimary,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: provider.playPause,
                        ),
                      ),
                      // Next button
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            color: AuroraTheme.textPrimary, size: 26),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: provider.next,
                      ),
                    ],
                  ),
                ),
                // Progress bar at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: _buildProgressBar(provider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(Song song, bool isPlaying) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying ? AuroraTheme.accentCyan : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: AuroraTheme.accentCyan.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: song.effectiveAlbumArt.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: song.effectiveAlbumArt,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (_, __) => _albumArtPlaceholder(),
                errorWidget: (_, __, ___) => _albumArtPlaceholder(),
              )
            : _albumArtPlaceholder(),
      ),
    );
  }

  Widget _albumArtPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AuroraTheme.glassMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.music_note_rounded, color: AuroraTheme.textMuted, size: 24),
    );
  }

  Widget _buildProgressBar(MusicProvider provider) {
    return ValueListenableBuilder<Duration>(
      valueListenable: provider.positionNotifier,
      builder: (context, pos, _) {
        final dur = provider.duration;
        final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds : 1;
        final val = pos.inMilliseconds.clamp(0, maxMs).toDouble() / maxMs;
        return _progressIndicator(val);
      },
    );
  }

  Widget _progressIndicator(double value) {
    return LinearProgressIndicator(
      value: value,
      minHeight: 3,
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      valueColor: const AlwaysStoppedAnimation<Color>(AuroraTheme.accentCyan),
    );
  }
}