import 'dart:math';
import 'package:flutter/material.dart';

class GlowingOrb extends StatefulWidget {
  final double size;
  final Color color;
  final double blurRadius;
  final Offset? offset;

  const GlowingOrb({
    super.key,
    this.size = 120,
    required this.color,
    this.blurRadius = 60,
    this.offset,
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
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
        final scale = 1.0 + sin(_controller.value * 2 * pi) * 0.08;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: widget.blurRadius,
                  spreadRadius: widget.blurRadius * 0.3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
