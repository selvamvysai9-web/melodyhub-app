class LyricsLine {
  final String text;
  final Duration timestamp;

  const LyricsLine({required this.text, required this.timestamp});
}

class LyricsService {
  static final LyricsService _instance = LyricsService._();
  factory LyricsService() => _instance;
  LyricsService._();

  List<LyricsLine> getMockLyrics() {
    return [
      LyricsLine(text: "Lost in the neon lights", timestamp: const Duration(seconds: 0)),
      LyricsLine(text: "Dancing through the endless night", timestamp: const Duration(seconds: 4)),
      LyricsLine(text: "Electric pulses in my veins", timestamp: const Duration(seconds: 8)),
      LyricsLine(text: "Breaking through the soundproof chains", timestamp: const Duration(seconds: 12)),
      LyricsLine(text: "", timestamp: const Duration(seconds: 16)),
      LyricsLine(text: "We are the stars that never fade", timestamp: const Duration(seconds: 20)),
      LyricsLine(text: "Shadows in the masquerade", timestamp: const Duration(seconds: 24)),
      LyricsLine(text: "Feel the rhythm take control", timestamp: const Duration(seconds: 28)),
      LyricsLine(text: "Let the music make us whole", timestamp: const Duration(seconds: 32)),
      LyricsLine(text: "", timestamp: const Duration(seconds: 36)),
      LyricsLine(text: "Aurora sky, we're burning bright", timestamp: const Duration(seconds: 40)),
      LyricsLine(text: "Chasing echoes in the night", timestamp: const Duration(seconds: 44)),
      LyricsLine(text: "Every note a universe", timestamp: const Duration(seconds: 48)),
      LyricsLine(text: "In this song, we all converse", timestamp: const Duration(seconds: 52)),
    ];
  }
}
