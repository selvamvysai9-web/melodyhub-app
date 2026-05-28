import '../repositories/gemini_repository.dart';

class AIService {
  final GeminiRepository _gemini;

  AIService(this._gemini);

  List<Map<String, String>> get quickActions => [
        {'icon': '🔮', 'label': 'Recommend', 'query': 'recommend some music for me'},
        {'icon': '🎭', 'label': 'My Mood', 'query': 'what should I listen to based on my mood?'},
        {'icon': '🎤', 'label': 'Lyrics', 'query': 'find songs with great lyrics'},
        {'icon': '🎸', 'label': 'Artists', 'query': 'suggest similar artists'},
        {'icon': '📊', 'label': 'Genres', 'query': 'what genres should I explore?'},
      ];

  Future<GeminiResult> generateResponse(String query) async {
    return _gemini.chat(query);
  }

  Future<GeminiResult> analyzeMood(String query) async {
    return _gemini.analyzeMood(query);
  }

  Future<GeminiResult> enrichSong(String title, String artist) async {
    return _gemini.enrichSong(title, artist);
  }
}
