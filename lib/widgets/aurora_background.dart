import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mood_provider.dart';
import '../theme/mood_theme.dart';


class AuroraBackground extends ConsumerStatefulWidget {
  const AuroraBackground({super.key});

  @override
  ConsumerState<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends ConsumerState<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);
    final theme = MoodTheme.themes[moodState.mood] ?? MoodTheme.themes[AppMood.neutral]!;

    return Stack(
      children: [
        // Smoothly animate background colors
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: theme.primary,
          ),
        ),
        
        // Animated mesh gradients
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildOrb(
                  position: Offset(0.1, 0.1),
                  size: 350,
                  color: theme.gradient[0],
                  animationValue: _controller.value,
                ),
                _buildOrb(
                  position: Offset(0.8, 0.2),
                  size: 450,
                  color: theme.gradient[1],
                  animationValue: (_controller.value + 0.5) % 1.0,
                ),
                _buildOrb(
                  position: Offset(0.5, 0.7),
                  size: 300,
                  color: theme.accent,
                  animationValue: 1.0 - _controller.value,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrb({
    required Offset position,
    required double size,
    required Color color,
    required double animationValue,
  }) {
    // Subtle movement using animationValue
    final double offsetX = (animationValue * 40.0) - 20.0;
    final double offsetY = (animationValue * 60.0) - 30.0;

    return Positioned(
      top: position.dy * MediaQuery.of(context).size.height + offsetY,
      left: position.dx * MediaQuery.of(context).size.width + offsetX,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
