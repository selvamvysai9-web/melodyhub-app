import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/music_provider.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glowing_orb.dart';
import '../../widgets/mini_player.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicProvider = context.watch<MusicProvider>();
    final songs = musicProvider.playlist;

    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: const SizedBox(height: 8)),
                      SliverToBoxAdapter(child: _buildGreeting()),
                      SliverToBoxAdapter(child: const SizedBox(height: 20)),
                      SliverToBoxAdapter(child: _buildFeaturedCard(context, musicProvider)),
                      SliverToBoxAdapter(child: const SizedBox(height: 24)),
                      SliverToBoxAdapter(child: _buildTrendingYtHits(context, musicProvider)),
                      SliverToBoxAdapter(child: const SizedBox(height: 24)),
                      SliverToBoxAdapter(child: _buildRecentlyPlayed(context, musicProvider)),
                      SliverToBoxAdapter(child: const SizedBox(height: 24)),
                      SliverToBoxAdapter(child: _buildQuickBrowse(context)),
                      SliverToBoxAdapter(child: const SizedBox(height: 28)),
                      SliverToBoxAdapter(child: _buildSectionHeader('Trending Now')),
                      SliverToBoxAdapter(child: const SizedBox(height: 16)),
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 120),
                        sliver: _buildSongList(songs, musicProvider, context),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: AuroraTheme.oledBlack),
        Positioned(top: -100, right: -80, child: GlowingOrb(size: 220, color: AuroraTheme.accentCyan.withValues(alpha: 0.12), blurRadius: 100)),
        Positioned(bottom: -60, left: -40, child: GlowingOrb(size: 160, color: AuroraTheme.accentPurple.withValues(alpha: 0.08), blurRadius: 80)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple]),
              boxShadow: [
                BoxShadow(
                  color: AuroraTheme.accentCyan.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Melody Hub', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary, letterSpacing: -0.5)),
              Text('Premium Music', style: TextStyle(fontSize: 11, color: AuroraTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          _buildIconButton(Icons.search_rounded, () => context.go('/search'), AuroraTheme.accentCyan),
          const SizedBox(width: 8),
          _buildIconButton(Icons.settings_rounded, () => context.push('/settings'), AuroraTheme.accentOrange),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    if (hour < 12) {
      greeting = 'Good morning';
      icon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      icon = Icons.wb_sunny_rounded;
    } else {
      greeting = 'Good evening';
      icon = Icons.nights_stay_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AuroraTheme.accentCyan),
              const SizedBox(width: 8),
              Text(greeting, style: const TextStyle(fontSize: 13, color: AuroraTheme.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Let\'s find your vibe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AuroraTheme.textPrimary, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, MusicProvider musicProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          if (musicProvider.playlist.isNotEmpty) {
            musicProvider.playSong(0);
            context.push('/player');
          }
        },
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                AuroraTheme.accentCyan.withValues(alpha: 0.15),
                AuroraTheme.accentPurple.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AuroraTheme.glassMedium.withValues(alpha: 0.3), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AuroraTheme.accentCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AuroraTheme.accentCyan.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 12, color: AuroraTheme.accentCyan),
                                const SizedBox(width: 6),
                                const Text('FEATURED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AuroraTheme.accentCyan, letterSpacing: 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            musicProvider.playlist.isNotEmpty ? musicProvider.playlist.first.title : 'Aurora Nights',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary, height: 1.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            musicProvider.playlist.isNotEmpty ? musicProvider.playlist.first.artist : 'Tap to play',
                            style: const TextStyle(fontSize: 13, color: AuroraTheme.textSecondary, fontWeight: FontWeight.w500),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentCyan]),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AuroraTheme.accentCyan.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                const Text('Play Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AuroraTheme.oledBlack)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AuroraTheme.accentCyan.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: musicProvider.playlist.isNotEmpty && musicProvider.playlist.first.albumArt.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CachedNetworkImage(
                                imageUrl: musicProvider.playlist.first.albumArt,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                                errorWidget: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Colors.white70, size: 40),
                              ),
                            )
                          : const Icon(Icons.music_note_rounded, color: Colors.white70, size: 40),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayed(BuildContext context, MusicProvider musicProvider) {
    final recent = musicProvider.recentlyPlayed;
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: AuroraTheme.accentPurple),
              const SizedBox(width: 8),
              const Text('Recently played', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recent.length.clamp(0, 10),
            itemBuilder: (context, i) {
              final song = recent[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    final idx = musicProvider.playlist.indexWhere((s) => s.youtubeId == song.youtubeId);
                    if (idx >= 0) {
                      musicProvider.playSong(idx);
                    } else {
                      musicProvider.playQueue([song]);
                    }
                    context.push('/player');
                  },
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AuroraTheme.glassLight.withValues(alpha: 0.5),
                      border: Border.all(color: AuroraTheme.glassMedium.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: song.effectiveAlbumArt.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: song.effectiveAlbumArt,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: AuroraTheme.glassMedium,
                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.accentCyan)),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AuroraTheme.glassMedium,
                                      child: const Icon(Icons.music_note_rounded, color: AuroraTheme.textMuted, size: 28),
                                    ),
                                  )
                                : Container(
                                    color: AuroraTheme.glassMedium,
                                    child: const Icon(Icons.music_note_rounded, color: AuroraTheme.textMuted, size: 28),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  song.artist,
                                  style: const TextStyle(fontSize: 10, color: AuroraTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingYtHits(BuildContext context, MusicProvider musicProvider) {
    final hits = musicProvider.trendingYtHits;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text('YouTube Hits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AuroraTheme.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AuroraTheme.accentCyan)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: hits.isEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 5,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AuroraTheme.glassMedium,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.accentCyan),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(width: 80, height: 10, decoration: BoxDecoration(color: AuroraTheme.glassMedium, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 4),
                            Container(width: 50, height: 8, decoration: BoxDecoration(color: AuroraTheme.glassMedium, borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: hits.length,
                  itemBuilder: (context, i) {
                    final song = hits[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          musicProvider.playSongByReference(song);
                          context.push('/player');
                        },
                        child: SizedBox(
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: song.effectiveAlbumArt.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: song.effectiveAlbumArt,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              width: 110,
                                              height: 110,
                                              color: AuroraTheme.glassMedium,
                                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AuroraTheme.accentCyan)),
                                            ),
                                            errorWidget: (_, __, ___) => Container(
                                              width: 110,
                                              height: 110,
                                              color: AuroraTheme.glassMedium,
                                              child: const Icon(Icons.music_note, color: AuroraTheme.textMuted),
                                            ),
                                          )
                                        : Container(
                                            width: 110,
                                            height: 110,
                                            color: AuroraTheme.glassMedium,
                                            child: const Icon(Icons.music_note, color: AuroraTheme.textMuted),
                                          ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AuroraTheme.oledBlack,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow_rounded, color: AuroraTheme.accentCyan, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song.title,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: const TextStyle(fontSize: 11, color: AuroraTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuickBrowse(BuildContext context) {
    final items = [
      ('Discover', Icons.explore_rounded, AuroraTheme.accentPink, '/discover'),
      ('Chill', Icons.nights_stay_rounded, AuroraTheme.accentPurple, '/search'),
      ('Workout', Icons.fitness_center_rounded, AuroraTheme.accentOrange, '/search'),
      ('Focus', Icons.psychology_rounded, AuroraTheme.accentCyan, '/search'),
      ('Premium', Icons.workspace_premium_rounded, AuroraTheme.accentPink, '/premium'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Browse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final (label, icon, color, route) = items[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.go(route),
                  child: GlassContainer(
                    width: 120,
                    height: 100,
                    borderRadius: 16,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(icon, color: color, size: 28),
                        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
          const Spacer(),
          const Text('See all', style: TextStyle(fontSize: 13, color: AuroraTheme.accentCyan)),
        ],
      ),
    );
  }

  Widget _buildSongList(List songs, MusicProvider musicProvider, BuildContext context) {
    if (musicProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AuroraTheme.accentCyan),
      );
    }
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off_rounded, size: 64, color: AuroraTheme.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text('No songs available', style: TextStyle(fontSize: 14, color: AuroraTheme.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Add bottom padding to account for MiniPlayer
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrentlyPlaying = musicProvider.isSongPlaying(song);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 16, color: AuroraTheme.glassLight,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: song.effectiveAlbumArt.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.effectiveAlbumArt,
                        width: 48, height: 48, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(width: 48, height: 48, color: AuroraTheme.glassLight, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22)),
                        errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AuroraTheme.glassMedium, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22)),
                      )
                    : Container(width: 48, height: 48, color: AuroraTheme.glassMedium, child: const Icon(Icons.music_note, color: AuroraTheme.textMuted)),
              ),
              title: Text(
                song.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrentlyPlaying ? AuroraTheme.accentCyan : AuroraTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(song.artist, style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: Icon(
                  isCurrentlyPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: AuroraTheme.accentCyan,
                  size: 28,
                ),
                onPressed: () {
                  if (isCurrentlyPlaying) {
                    musicProvider.playPause();
                  } else {
                    musicProvider.playSongByReference(song);
                  }
                },
              ),
              onTap: () => musicProvider.playSongByReference(song),
            ),
          ),
        );
      },
    );
  }
}
