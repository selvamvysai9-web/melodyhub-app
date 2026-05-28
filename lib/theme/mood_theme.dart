import 'package:flutter/material.dart';

enum AppMood {
  neutral,
  chill,
  energetic,
  dark,
  euphoric,
}

class MoodTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> gradient;

  const MoodTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
  });

  static const Map<AppMood, MoodTheme> themes = {
    AppMood.neutral: MoodTheme(
      primary: Color(0xFF050505),
      secondary: Color(0xFF0A0A0F),
      accent: Color(0xFF00E5FF),
      gradient: [Color(0xFF00E5FF), Color(0xFFBB86FC)],
    ),
    AppMood.chill: MoodTheme(
      primary: Color(0xFF020B1D),
      secondary: Color(0xFF051B3C),
      accent: Color(0xFF4FACFE),
      gradient: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    ),
    AppMood.energetic: MoodTheme(
      primary: Color(0xFF1A0505),
      secondary: Color(0xFF3D0A0A),
      accent: Color(0xFFFF4B2B),
      gradient: [Color(0xFFFF4B2B), Color(0xFFFF416C)],
    ),
    AppMood.dark: MoodTheme(
      primary: Color(0xFF000000),
      secondary: Color(0xFF0A0A0A),
      accent: Color(0xFF6A6A6A),
      gradient: [Color(0xFF2C3E50), Color(0xFF000000)],
    ),
    AppMood.euphoric: MoodTheme(
      primary: Color(0xFF0A001A),
      secondary: Color(0xFF1A0033),
      accent: Color(0xFFE040FB),
      gradient: [Color(0xFFE040FB), Color(0xFF00B0FF)],
    ),
  };
}
