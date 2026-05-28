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
            // Swipe up to open full player
            if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
              onTap();
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AuroraTheme.darkSurface.withValues(alpha: 0.92),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AuroraTheme.accentCyan.withValues(alpha: provider.isPlaying ? 0.08 : 0.0),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
                  child: Row(
                    children: [
                      // Album art with playing animation
                      Hero(
                        tag: 'album_art_transition',
                        child: _buildAlbumArt(song, provider.isPlaying),
                      ),
                      const SizedBox(width: 12),
                      // Song info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: AuroraTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: const TextStyle(
                                color: AuroraTheme.textSecondary,
                                fontSize: 12,
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
                            color: AuroraTheme.textSecondary, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: provider.previous,
                      ),
                      // Play/Pause button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AuroraTheme.accentCyan,
                              AuroraTheme.accentCyan.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AuroraTheme.accentCyan.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            provider.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: AuroraTheme.oledBlack,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: provider.playPause,
                        ),
                      ),
                      // Next button
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded,
                            color: AuroraTheme.textSecondary, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isPlaying
            ? [BoxShadow(color: AuroraTheme.accentCyan.withValues(alpha: 0.2), blurRadius: 8)]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: song.effectiveAlbumArt.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: song.effectiveAlbumArt,
                width: 46,
                height: 46,
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AuroraTheme.glassLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22),
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
      minHeight: 2.5,
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      valueColor: const AlwaysStoppedAnimation<Color>(AuroraTheme.accentCyan),
    );
  }
}