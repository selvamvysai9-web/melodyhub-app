import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/music_provider.dart';
import '../../theme/aurora_theme.dart';

import '../../widgets/glowing_orb.dart';
import '../../services/lyrics_service.dart';
import '../../widgets/playback_queue_sheet.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../providers/favorites_provider.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  final double _vibeX = 0.0;
  final double _vibeY = 0.0;
  final LyricsService _lyricsService = LyricsService();
  List<LyricsLine> _lyrics = [];
  int currentLyricIndex = 0;
  String _activePreset = 'Flat';
  String? _lastSongId;
  StreamSubscription<Duration>? _positionSub;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _lyrics = _lyricsService.getMockLyrics();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
  }

  void _setupLyricsListener() {
    final provider = context.read<MusicProvider>();
    _positionSub?.cancel();
    _positionSub = provider.player.positionStream.listen((pos) {
      _updateLyricsIndex(pos);
    });
  }

  void _updateLyricsIndex(Duration pos) {
    if (_lyrics.isEmpty) return;
    int index = 0;
    for (int i = 0; i < _lyrics.length; i++) {
      if (pos >= _lyrics[i].timestamp) {
        index = i;
      } else {
        break;
      }
    }
    if (index != currentLyricIndex) {
      setState(() {
        currentLyricIndex = index;
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final currentSong = musicProvider.currentSong;

    // Update rotation animation based on playback
    if (musicProvider.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    if (currentSong.id != _lastSongId) {
      _lastSongId = currentSong.id;
      _lyrics = _lyricsService.getMockLyrics();
      currentLyricIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupLyricsListener();
      });
    }

    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('PLAYING FROM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AuroraTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 2),
            Text(
              currentSong.artist,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AuroraTheme.textSecondary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AuroraTheme.textSecondary),
            onPressed: () => _showSongOptions(context, musicProvider),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildAudioReactiveBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Expanded(child: _buildTabContent(currentSong)),
                _buildSeekBar(),
                _buildPlaybackControls(),
                _buildBottomActions(musicProvider),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, MusicProvider provider) {
    final song = provider.currentSong;
    showModalBottomSheet(
      context: context,
      backgroundColor: AuroraTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AuroraTheme.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: AuroraTheme.accentPurple),
              title: const Text('Add to playlist', style: TextStyle(color: AuroraTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showAddToPlaylistSheet(context, song);
              },
            ),
            ListTile(
              leading: Icon(
                context.read<FavoritesProvider>().isLiked(song.youtubeId)
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                color: AuroraTheme.accentPink,
              ),
              title: const Text('Like', style: TextStyle(color: AuroraTheme.textPrimary)),
              onTap: () {
                context.read<FavoritesProvider>().toggleLike(song);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded, color: AuroraTheme.accentCyan),
              title: const Text('View queue', style: TextStyle(color: AuroraTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                showPlaybackQueueSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AuroraTheme.accentCyan),
              title: const Text('Share', style: TextStyle(color: AuroraTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                provider.shareSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: AuroraTheme.accentGreen),
              title: const Text('Download', style: TextStyle(color: AuroraTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                provider.downloadSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_rounded, color: AuroraTheme.accentOrange),
              title: const Text('Sleep Timer', style: TextStyle(color: AuroraTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showSleepTimerPicker(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerPicker(BuildContext context, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AuroraTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sleep Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
            const SizedBox(height: 16),
            ...['15 min', '30 min', '45 min', '1 hour'].map((label) {
              final mins = label == '1 hour' ? 60 : int.parse(label.split(' ')[0]);
              return ListTile(
                title: Text(label, style: const TextStyle(color: AuroraTheme.textPrimary)),
                onTap: () {
                  provider.setSleepTimer(Duration(minutes: mins));
                  Navigator.pop(ctx);
                },
              );
            }),
            if (provider.sleepTarget != null)
              ListTile(
                leading: const Icon(Icons.cancel_rounded, color: AuroraTheme.accentPink),
                title: const Text('Cancel Timer', style: TextStyle(color: AuroraTheme.accentPink)),
                onTap: () {
                  provider.cancelSleepTimer();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioReactiveBackground() {
    return Stack(
      children: [
        Container(color: AuroraTheme.oledBlack),
        Positioned(
          top: -100, right: -60,
          child: GlowingOrb(
            size: 200,
            color: AuroraTheme.accentCyan.withValues(alpha: 0.3 + _vibeX * 0.3),
            blurRadius: 80,
          ),
        ),
        Positioned(
          bottom: -80, left: -40,
          child: GlowingOrb(
            size: 180,
            color: AuroraTheme.accentPurple.withValues(alpha: 0.3 + _vibeY * 0.3),
            blurRadius: 70,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(Song currentSong) {
    switch (_selectedTab) {
      case 0:
        return _buildNowPlayingTab(currentSong);
      case 1:
        return _buildLyricsTab();
      case 2:
        return _buildEqualizerTab();
      default:
        return _buildNowPlayingTab(currentSong);
    }
  }

  Widget _buildNowPlayingTab(Song currentSong) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Album art with rotation animation
        RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuroraTheme.accentCyan.withValues(alpha: 0.15),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipOval(
                child: currentSong.effectiveAlbumArt.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: currentSong.effectiveAlbumArt,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AuroraTheme.glassMedium,
                          child: const Icon(Icons.music_note, size: 80, color: AuroraTheme.textSecondary),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AuroraTheme.glassMedium,
                          child: const Icon(Icons.music_note, size: 80, color: AuroraTheme.textSecondary),
                        ),
                      )
                    : Container(
                        color: AuroraTheme.glassMedium,
                        child: const Icon(Icons.music_note, size: 80, color: AuroraTheme.textSecondary),
                      ),
              ),
            ),
          ),
        const SizedBox(height: 36),
        // Song title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            currentSong.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          currentSong.artist,
          style: const TextStyle(fontSize: 15, color: AuroraTheme.textSecondary),
        ),
        const SizedBox(height: 28),
        // Tab buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabButton(0, Icons.disc_full_rounded, 'Now Playing'),
            const SizedBox(width: 24),
            _buildTabButton(1, Icons.lyrics_rounded, 'Lyrics'),
            const SizedBox(width: 24),
            _buildTabButton(2, Icons.tune_rounded, 'EQ'),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AuroraTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: AuroraTheme.accentPink, size: 20),
              const SizedBox(width: 8),
              const Text('Sing-Along', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AuroraTheme.accentPink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, color: AuroraTheme.accentPink, size: 16),
                    SizedBox(width: 4),
                    Text('Karaoke', style: TextStyle(fontSize: 12, color: AuroraTheme.accentPink, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _lyrics.length,
              itemBuilder: (context, index) {
                final line = _lyrics[index];
                final isActive = index == currentLyricIndex;
                final isPast = index < currentLyricIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isActive ? 22 : 16,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AuroraTheme.accentCyan : isPast ? AuroraTheme.textMuted : AuroraTheme.textSecondary,
                      height: 1.4,
                    ),
                    child: Text(line.text, textAlign: TextAlign.center),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizerTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('EQ Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
          const SizedBox(height: 24),
          ...['Flat', 'Rock', 'Pop', 'Jazz', 'Classical', 'Bass Boost'].map(
            (preset) {
              final isSelected = preset == _activePreset;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activePreset = preset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected ? AuroraTheme.accentCyan.withValues(alpha: 0.15) : AuroraTheme.glassLight,
                      border: isSelected
                          ? Border.all(color: AuroraTheme.accentCyan, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.equalizer_rounded,
                          color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          preset,
                          style: TextStyle(
                            color: isSelected ? AuroraTheme.accentCyan : AuroraTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AuroraTheme.accentCyan,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar() {
    final provider = context.watch<MusicProvider>();
    return StreamBuilder<Duration>(
      stream: provider.player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = provider.duration;
        return _seekBarContent(pos, dur, provider);
      },
    );
  }

  Widget _seekBarContent(Duration pos, Duration dur, MusicProvider provider) {
    final maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds : 1;
    final val = pos.inMilliseconds.clamp(0, maxMs).toDouble() / maxMs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AuroraTheme.accentCyan,
              inactiveTrackColor: AuroraTheme.textMuted.withValues(alpha: 0.2),
              thumbColor: AuroraTheme.accentCyan,
              overlayColor: AuroraTheme.accentCyan.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: val,
              onChanged: (v) => provider.seek(Duration(milliseconds: (v * maxMs).toInt())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(provider.formatDuration(pos), style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted, fontWeight: FontWeight.w500)),
                Text(provider.formatDuration(dur), style: const TextStyle(fontSize: 12, color: AuroraTheme.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final provider = context.watch<MusicProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color: provider.isShuffled ? AuroraTheme.accentCyan : AuroraTheme.textSecondary,
              size: 24,
            ),
            onPressed: provider.toggleShuffle,
          ),
          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, color: AuroraTheme.textPrimary, size: 36),
            onPressed: provider.previous,
          ),
          // Play/Pause
          GestureDetector(
            onTap: provider.playPause,
            child: Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AuroraTheme.accentCyan, Color(0xFF00B4D8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AuroraTheme.accentCyan.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AuroraTheme.oledBlack,
                size: 36,
              ),
            ),
          ),
          // Next
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: AuroraTheme.textPrimary, size: 36),
            onPressed: provider.next,
          ),
          // Repeat
          IconButton(
            icon: Icon(
              provider.repeatMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: provider.repeatMode != LoopMode.off ? AuroraTheme.accentCyan : AuroraTheme.textSecondary,
              size: 24,
            ),
            onPressed: provider.cycleRepeatMode,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(MusicProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded, color: AuroraTheme.textMuted, size: 22),
            onPressed: () => showPlaybackQueueSheet(context),
            tooltip: 'Queue',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AuroraTheme.textMuted, size: 22),
            onPressed: () => provider.shareSong(provider.currentSong),
          ),
          // Volume slider
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volume_down_rounded, color: AuroraTheme.textMuted, size: 18),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      activeTrackColor: AuroraTheme.textSecondary,
                      inactiveTrackColor: AuroraTheme.textMuted.withValues(alpha: 0.2),
                      thumbColor: AuroraTheme.textSecondary,
                    ),
                    child: Slider(
                      value: provider.volume,
                      onChanged: (v) => provider.setVolume(v),
                    ),
                  ),
                ),
                const Icon(Icons.volume_up_rounded, color: AuroraTheme.textMuted, size: 18),
              ],
            ),
          ),
          // Download button
          IconButton(
            icon: Icon(
              provider.isDownloaded(provider.currentSong.youtubeId)
                  ? Icons.download_done_rounded
                  : Icons.download_rounded,
              color: provider.isDownloaded(provider.currentSong.youtubeId)
                  ? AuroraTheme.accentGreen
                  : AuroraTheme.textMuted,
              size: 22,
            ),
            onPressed: () => provider.downloadSong(provider.currentSong),
          ),
        ],
      ),
    );
  }
}
