class GeminiMoodReply {
  final String mood;
  final String rationale;
  final List<String> searchKeywords;

  GeminiMoodReply({
    required this.mood,
    required this.rationale,
    required this.searchKeywords,
  });

  factory GeminiMoodReply.fromJson(Map<String, dynamic> json) {
    return GeminiMoodReply(
      mood: json['mood'] as String? ?? 'neutral',
      rationale: json['rationale'] as String? ?? '',
      searchKeywords: List<String>.from(json['search_keywords'] ?? []),
    );
  }
}
