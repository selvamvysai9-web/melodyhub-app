import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../theme.dart';
import 'sleep_timer_dialog.dart';

class FullScreenPlayer extends StatefulWidget {
  final VoidCallback? onQueue;
  final VoidCallback? onShare;
  const FullScreenPlayer({super.key, this.onQueue, this.onShare});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  bool _showLyrics = false;
  String _activePreset = 'Bass Booster';

  final Map<String, List<double>> _presetFrequencies = {
    'Flat': [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
    'Bass Booster': [0.9, 0.85, 0.7, 0.5, 0.4, 0.45, 0.4, 0.35],
    'Vocal Booster': [0.3, 0.4, 0.6, 0.85, 0.9, 0.75, 0.5, 0.4],
    'Acoustic': [0.6, 0.55, 0.5, 0.65, 0.75, 0.7, 0.6, 0.5],
    'Electronic': [0.8, 0.7, 0.4, 0.5, 0.75, 0.85, 0.7, 0.6],
    'Classical': [0.5, 0.55, 0.6, 0.55, 0.5, 0.65, 0.7, 0.75],
  };

  String _generateMockLyrics(Song song) {
    return 'Enjoying "${song.title}"\n'
        'By the legendary ${song.artist}\n'
        '\n'
        '🎵 (Instrumental Intro) 🎵\n'
        '\n'
        'This is a premium streaming experience\n'
        'Only on Melody Hub\n'
        'Where every beat comes alive\n'
        'And the rhythm takes control\n'
        '\n'
        'Oh, listen to the melody\n'
        'It is playing just for you and me\n'
        'Dancing in the night so free\n'
        'With ${song.artist}\'s harmony\n'
        '\n'
        '🎵 (Guitar Solo) 🎵\n'
        '\n'
        'Keep on pressing play\n'
        'Let the music lead the way\n'
        'Melody Hub night and day\n'
        'We are here to stay!';
  }

  void _showEqualizerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final freq = _presetFrequencies[_activePreset] ?? _presetFrequencies['Flat']!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Equalizer & Presets',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _activePreset,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Simulated Equalizer Frequencies Visualizer
                  SizedBox(
                    height: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(freq.length, (index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 24,
                              height: freq[index] * 80.0,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.accent, Color(0xFF1ED760)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(32 * (index + 1))}Hz',
                              style: const TextStyle(color: Colors.white38, fontSize: 8),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Presets List
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _presetFrequencies.keys.map((preset) {
                        final isSelected = preset == _activePreset;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _activePreset = preset);
                            setSheetState(() {});
                          },
                          child: Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accent.withValues(alpha: 0.1)
                                  : const Color(0xFF282828),
                              border: Border.all(
                                color: isSelected ? AppTheme.accent : Colors.transparent,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  color: isSelected ? AppTheme.accent : Colors.white54,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  preset,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        return Scaffold(
          backgroundColor: AppTheme.background,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: AppTheme.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('NOW PLAYING',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Selector<MusicProvider, bool>(
                  selector: (_, p) => p.sleepTarget != null,
                  builder: (_, active, __) => Icon(
                    Icons.timer_rounded,
                    color: active ? AppTheme.accent : AppTheme.textSecondary,
                  ),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const SleepTimerDialog(),
                ),
              ),
              if (widget.onQueue != null)
                IconButton(
                    icon: const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary),
                    onPressed: widget.onQueue),
              if (widget.onShare != null)
                IconButton(
                    icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
                    onPressed: widget.onShare),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // 1. Ambient Background Layer
              _buildAmbientBackground(provider, song),

              // 2. Main Content Layer
              Column(
                children: [
                  const SizedBox(height: 100),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _showLyrics ? _buildLyricsView(song) : _buildArtwork(provider, song),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildBottomSection(provider, song),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmbientBackground(MusicProvider provider, Song song) {
    return Stack(
      children: [
        SizedBox.expand(
          child: CachedNetworkImage(
            imageUrl: song.effectiveAlbumArt,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(color: AppTheme.surfaceElevated),
            errorWidget: (ctx, url, err) => Container(color: AppTheme.surfaceElevated),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtwork(MusicProvider provider, Song song) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.75;
        return Center(
          child: Hero(
            tag: 'album_art_transition',
            child: AnimatedScale(
              scale: provider.isPlaying ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 50,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: song.effectiveAlbumArt,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(Icons.music_note, color: AppTheme.textMuted, size: 64),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: AppTheme.surfaceElevated,
                      child: const Icon(Icons.music_note, color: AppTheme.textMuted, size: 64),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLyricsView(Song song) {
    final lyricsText = song.lyrics.isNotEmpty ? song.lyrics : _generateMockLyrics(song);
    final lines = lyricsText.split('\n');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.mic_external_on_rounded, color: AppTheme.accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lyrics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                onPressed: () {
                  setState(() => _showLyrics = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.1, 0.85, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: lines.length,
                itemBuilder: (context, index) {
                  final line = lines[index];
                  final isInstruction = line.startsWith('🎵') || line.startsWith('Enjoying') || line.startsWith('By');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isInstruction
                            ? AppTheme.accent
                            : (index == 5 || index == 11
                                ? AppTheme.accentPressed
                                : Colors.white.withValues(alpha: 0.8)),
                        fontSize: isInstruction ? 15 : 18,
                        fontWeight: (index == 5 || index == 11) ? FontWeight.bold : FontWeight.normal,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(MusicProvider provider, Song song) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            song.title,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          AudioVisualizer(isPlaying: provider.isPlaying),
          const SizedBox(height: 8),
          _buildSeekBar(provider),
          const SizedBox(height: 12),
          _buildControls(provider),
          const SizedBox(height: 12),
          _buildUtilityBar(context, provider),
        ],
      ),
    );
  }

  Widget _buildSeekBar(MusicProvider provider) {
    return StreamBuilder<Duration>(
      stream: provider.player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final dur = provider.duration;
        return _seekBarContent(context, pos, dur, provider);
      },
    );
  }

  Widget _seekBarContent(BuildContext context, Duration pos, Duration dur, MusicProvider provider) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.textMuted.withValues(alpha: 0.3),
            thumbColor: AppTheme.accent,
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            overlayColor: AppTheme.accent.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: dur.inMilliseconds > 0 ? pos.inMilliseconds.clamp(0, dur.inMilliseconds).toDouble() : 0,
            max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
            onChanged: (v) => provider.seek(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(provider.formatDuration(pos), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              Text(provider.formatDuration(dur), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(MusicProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: provider.isShuffled ? AppTheme.accent : AppTheme.textSecondary,
            size: 26,
          ),
          onPressed: provider.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.text, size: 36),
          onPressed: provider.previous,
        ),
        GestureDetector(
          onTap: provider.playPause,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.text,
            ),
            child: Icon(
              provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppTheme.background,
              size: 36,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: AppTheme.text, size: 36),
          onPressed: provider.next,
        ),
        IconButton(
          icon: Icon(
            provider.repeatMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: provider.repeatMode != LoopMode.off ? AppTheme.accent : AppTheme.textSecondary,
            size: 26,
          ),
          onPressed: provider.cycleRepeatMode,
        ),
      ],
    );
  }

  Widget _buildUtilityBar(BuildContext context, MusicProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              _showLyrics ? Icons.mic_external_on_rounded : Icons.mic_external_off_rounded,
              color: _showLyrics ? AppTheme.accent : Colors.white54,
              size: 22,
            ),
            onPressed: () {
              setState(() => _showLyrics = !_showLyrics);
            },
          ),
          IconButton(
            icon: const Icon(Icons.equalizer_rounded, color: Colors.white54, size: 22),
            onPressed: () => _showEqualizerSheet(context),
          ),
          if (provider.sleepTarget != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.sleepTarget!.difference(DateTime.now()).inMinutes}m left',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// REDESIGNED: SMOOTH HIGH-PERFORMANCE AUDIO VISUALIZER
// ============================================================================
class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  const AudioVisualizer({super.key, required this.isPlaying});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [
    0.3, 0.5, 0.7, 0.9, 0.6, 0.4, 0.8, 1.0, 0.5, 0.7,
    0.9, 0.6, 0.4, 0.8, 1.0, 0.5, 0.7, 0.9, 0.6, 0.4
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_baseHeights.length, (index) {
              final animValue = _controller.value;
              final heightMultiplier = widget.isPlaying
                  ? (index % 2 == 0 ? animValue : (1.0 - animValue))
                  : 0.1;
              final height = 3.0 + (_baseHeights[index] * 22.0 * heightMultiplier);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 3.5,
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accent, Color(0xFF1ED760)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
