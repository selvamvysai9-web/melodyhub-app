import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mood_theme.dart';

class AuroraTheme {
  static const Color oledBlack = Color(0xFF050505);
  static const Color darkSurface = Color(0xFF0A0A0F);
  static const Color glassLight = Color(0x33FFFFFF);
  static const Color glassMedium = Color(0x4DFFFFFF);
  static const Color glassHeavy = Color(0x66FFFFFF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFFBB86FC);
  static const Color accentPink = Color(0xFFFF4081);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6A6A6A);
  static const Color error = Color(0xFFCF6679);

  static const List<Color> auroraGradient = [
    Color(0xFF00E5FF),
    Color(0xFF7C4DFF),
    Color(0xFFFF4081),
  ];

  static const List<Color> meshGradient = [
    Color(0x1A00E5FF),
    Color(0x1A7C4DFF),
    Color(0x1AFF4081),
    Color(0x1A00E676),
    Color(0x0D000000),
  ];

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: oledBlack,
      primaryColor: accentCyan,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentPurple,
        tertiary: accentPink,
        surface: darkSurface,
        onSurface: textPrimary,
        error: error,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: oledBlack.withValues(alpha: 0.85),
        selectedItemColor: accentCyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassLight,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: accentCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: oledBlack,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: glassLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: textSecondary, size: 24),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentCyan,
        inactiveTrackColor: textMuted.withValues(alpha: 0.3),
        thumbColor: accentCyan,
        overlayColor: accentCyan.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentCyan,
        linearTrackColor: Color(0x33FFFFFF),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: glassHeavy,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF),
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData forMood(AppMood mood) {
    final mt = MoodTheme.themes[mood] ?? MoodTheme.themes[AppMood.neutral]!;
    final base = darkTheme;
    return base.copyWith(
      scaffoldBackgroundColor: mt.primary,
      primaryColor: mt.accent,
      colorScheme: base.colorScheme.copyWith(
        primary: mt.accent,
        secondary: mt.gradient.length > 1 ? mt.gradient[1] : mt.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: mt.accent),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: mt.accent,
        thumbColor: mt.accent,
        overlayColor: mt.accent.withValues(alpha: 0.2),
      ),
    );
  }
}
