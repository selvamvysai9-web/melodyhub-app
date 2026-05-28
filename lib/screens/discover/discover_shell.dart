import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/library_track.dart';
import '../../models/discover_track.dart';
import '../../providers/legacy_providers.dart';
import '../../providers/community_library_provider.dart';
import '../../providers/discover_provider.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../services/cloudflare_search_service.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glowing_orb.dart';
import '../../widgets/mini_player.dart';
import '../../repositories/playlist_repository.dart';

class DiscoverShell extends ConsumerStatefulWidget {
  const DiscoverShell({super.key});

  @override
  ConsumerState<DiscoverShell> createState() => _DiscoverShellState();
}

class _DiscoverShellState extends ConsumerState<DiscoverShell> {
  final TextEditingController _searchController = TextEditingController();
  final CloudflareSearchService _searchService = CloudflareSearchService();
  List<WorkerSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _hasTriggeredDiscover = false;

  @override
  void initState() {
    super.initState();
  }

  void _triggerDiscover() {
    if (_hasTriggeredDiscover) return;
    _hasTriggeredDiscover = true;

    final music = ref.read(musicProviderProvider);
    final recent = music.recentlyPlayed;
    final catalog = music.playlist;

    ref.read(discoverProvider.notifier).load(
          recentlyPlayed: recent,
          catalogFallback: catalog,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _searchService.search(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _saveMixToLibrary() async {
    final discoverState = ref.read(discoverProvider);
    final authState = ref.read(firebaseAuthProvider);

    final uid = authState.profile?.uid;
    if (uid == null || uid == 'guest') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to save mixes to your library'),
            backgroundColor: AuroraTheme.error,
          ),
        );
      }
      return;
    }

    final repo = PlaylistRepository();
    final tracks = discoverState.tracks.where((t) => t.isResolved).toList();
    if (tracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No playable tracks to save'),
            backgroundColor: AuroraTheme.error,
          ),
        );
      }
      return;
    }

    try {
      await repo.saveMixToLibrary(
        uid: uid,
        playlistTitle: discoverState.playlistTitle,
        summary: discoverState.summary,
        tracks: tracks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${discoverState.playlistTitle}" saved to library!'),
            backgroundColor: AuroraTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AuroraTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSearchResults = _searchQuery.trim().isNotEmpty;
    final discoverState = ref.watch(discoverProvider);

    // Trigger discover on first build with data
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerDiscover());

    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: showSearchResults
                      ? _buildSearchResults()
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: [
                            _buildDiscoverMixSection(discoverState),
                            const SizedBox(height: 24),
                            _buildCommunityFeedSection(),
                          ],
                        ),
                ),
              ],
            ),
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
  }

  Widget _buildDiscoverMixSection(DiscoverState state) {
    if (state.isLoadingAi) {
      return _buildDiscoverStatus(
        icon: Icons.auto_awesome_rounded,
        title: 'Crafting your mix\u2026',
        subtitle: 'AI is analyzing your listening history',
        isAnimating: true,
      );
    }

    if (state.isResolvingTracks) {
      return _buildDiscoverStatus(
        icon: Icons.search_rounded,
        title: 'Finding tracks on YouTube\u2026',
        subtitle: 'Pulling up the best matches for you',
        isAnimating: true,
      );
    }

    if (state.errorMessage != null) {
      return GlassContainer(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        borderRadius: 20,
        color: AuroraTheme.glassLight,
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, size: 36, color: AuroraTheme.accentOrange),
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AuroraTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _hasTriggeredDiscover = false;
                _triggerDiscover();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AuroraTheme.accentCyan),
              label: const Text('Try Again', style: TextStyle(color: AuroraTheme.accentCyan)),
            ),
          ],
        ),
      );
    }

    if (state.tracks.isEmpty) return const SizedBox.shrink();

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      color: AuroraTheme.glassLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AuroraTheme.accentCyan, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.playlistTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AuroraTheme.textPrimary,
                      ),
                    ),
                    if (state.summary.isNotEmpty)
                      Text(
                        state.summary,
                        style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Track list
          ...state.tracks.take(5).map((track) => _buildDiscoverTrack(track)),
          // Show more indicator
          if (state.tracks.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${state.tracks.length - 5} more',
                  style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                ),
              ),
            ),
          // Save button
          if (state.hasPlayableTracks) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuroraTheme.accentCyan,
                  foregroundColor: AuroraTheme.oledBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saveMixToLibrary,
                icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                label: const Text(
                  'Save mix to Library',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoverTrack(DiscoverTrack track) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Album art or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              color: AuroraTheme.glassMedium,
              child: track.song != null && track.song!.albumArt.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: track.song!.albumArt,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.music_note,
                          color: AuroraTheme.textMuted, size: 18),
                    )
                  : const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AuroraTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        track.artist,
                        style: const TextStyle(fontSize: 11, color: AuroraTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (track.isResolved)
                      const Icon(Icons.check_circle, size: 14, color: AuroraTheme.accentGreen),
                    if (!track.isResolved)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AuroraTheme.accentOrange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (track.isResolved)
            IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded,
                  color: AuroraTheme.accentCyan, size: 28),
              onPressed: () {
                if (track.song != null) {
                  ref.read(musicProvider.notifier).playSongByReference(track.song!);
                  context.push('/player');
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoverStatus({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isAnimating = false,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      borderRadius: 20,
      color: AuroraTheme.glassLight,
      child: Column(
        children: [
          if (isAnimating)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AuroraTheme.accentCyan,
              ),
            )
          else
            Icon(icon, size: 32, color: AuroraTheme.accentOrange),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AuroraTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AuroraTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityFeedSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('global_library')
          .orderBy('addedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AuroraTheme.accentCyan),
          );
        }

        if (snapshot.hasError) {
          return _buildStatus(
            icon: Icons.error_outline_rounded,
            title: 'Could not load community feed',
            subtitle: 'Please check your connection and try again.',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildStatus(
            icon: Icons.music_note_rounded,
            title: 'Feed is empty',
            subtitle: 'Be the first to search and add a song to the global feed!',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Community Feed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AuroraTheme.textPrimary,
                ),
              ),
            ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final track = LibraryTrack.fromFirestore(data);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                              errorWidget: (_, __, ___) => _artPlaceholder(),
                              placeholder: (_, __) => _artPlaceholder(),
                            )
                          : _artPlaceholder(),
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AuroraTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.artist,
                          style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded,
                                size: 12, color: AuroraTheme.accentCyan),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Shared by ${track.addedBy}',
                                style: const TextStyle(
                                    fontSize: 11, color: AuroraTheme.accentCyan),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AuroraTheme.accentCyan,
                      size: 32,
                    ),
                    onTap: () {
                      final song = Song(
                        id: 'yt_${track.videoId}',
                        title: track.title,
                        artist: track.artist,
                        youtubeId: track.videoId,
                        albumArt: track.thumbnail,
                      );
                      ref.read(musicProvider.notifier).playSongByReference(song);
                      context.push('/player');
                    },
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AuroraTheme.accentCyan),
            SizedBox(height: 16),
            Text(
              'Searching YouTube...',
              style: TextStyle(color: AuroraTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildStatus(
        icon: Icons.search_off_rounded,
        title: 'No songs found',
        subtitle: 'Try adjusting your search terms.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassContainer(
            padding: const EdgeInsets.all(8),
            borderRadius: 16,
            color: AuroraTheme.glassLight,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: result.thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: result.thumbnail,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _artPlaceholder(),
                        placeholder: (_, __) => _artPlaceholder(),
                      )
                    : _artPlaceholder(),
              ),
              title: Text(
                result.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AuroraTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                result.artist,
                style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.play_circle_outline_rounded,
                color: AuroraTheme.accentCyan,
                size: 28,
              ),
              onTap: () {
                ref.read(communityLibraryProvider.notifier).playAndDualSave(
                      track: result,
                      ref: ref,
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AuroraTheme.darkSurface,
                    content: Text(
                      'Tuned in: "${result.title}" shared with community!',
                      style: const TextStyle(color: AuroraTheme.textPrimary),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

                context.push('/player');
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: AuroraTheme.oledBlack),
        Positioned(
          top: -80,
          left: -60,
          child: GlowingOrb(
            size: 200,
            color: AuroraTheme.accentPink.withValues(alpha: 0.18),
            blurRadius: 80,
          ),
        ),
        Positioned(
          bottom: 100,
          right: -50,
          child: GlowingOrb(
            size: 180,
            color: AuroraTheme.accentPurple.withValues(alpha: 0.15),
            blurRadius: 70,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AuroraTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _searchQuery.trim().isNotEmpty
                      ? 'Search Results on YouTube'
                      : 'AI Picks + Community Feed',
                  style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
                ),
              ],
            ),
          ),
          // Refresh button for AI discover
          if (_searchQuery.trim().isEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AuroraTheme.accentCyan, size: 22),
              onPressed: () {
                ref.read(discoverProvider.notifier).clearCache();
                _hasTriggeredDiscover = false;
                _triggerDiscover();
              },
              tooltip: 'Refresh AI picks',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        borderRadius: 24,
        color: AuroraTheme.glassLight,
        child: TextField(
          controller: _searchController,
          onChanged: _performSearch,
          style: const TextStyle(color: AuroraTheme.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search songs, artists, or keywords...',
            hintStyle: const TextStyle(color: AuroraTheme.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AuroraTheme.accentCyan),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AuroraTheme.textMuted, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _artPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: AuroraTheme.glassMedium,
      child: const Icon(Icons.music_note, color: AuroraTheme.textMuted, size: 22),
    );
  }

  Widget _buildStatus({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AuroraTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AuroraTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AuroraTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
