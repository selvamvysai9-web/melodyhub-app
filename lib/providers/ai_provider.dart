import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/gemini_repository.dart';
import '../services/ai_service.dart';
import '../theme/mood_theme.dart';
import 'mood_provider.dart';

final geminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  return GeminiRepository();
});

final aiServiceProvider = Provider<AIService>((ref) {
  final gemini = ref.watch(geminiRepositoryProvider);
  return AIService(gemini);
});

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class AIChatNotifier extends StateNotifier<AIChatState> {
  final AIService _aiService;
  final Ref _ref;

  AIChatNotifier(this._aiService, this._ref) : super(const AIChatState());

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(text: text, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      isTyping: true,
    );

    final results = await Future.wait([
      _aiService.generateResponse(text),
      _aiService.analyzeMood(text),
    ]);

    final chatResult = results[0];
    final moodResult = results[1];

    final reply = switch (chatResult) {
      GeminiReply(text: final t) => t,
      GeminiError(message: final m) => '⚠️ $m',
      _ => 'No response',
    };

    if (moodResult is GeminiMoodReply) {
      final mood = _parseMood(moodResult.mood);
      _ref.read(moodProvider.notifier).updateMood(mood, moodResult.rationale);
    }

    final aiMsg = ChatMessage(text: reply, isUser: false);
    state = state.copyWith(
      messages: [...state.messages, aiMsg],
      isLoading: false,
      isTyping: false,
    );
  }

  Future<void> quickAction(String query) async {
    await sendMessage(query);
  }

  void clear() {
    state = const AIChatState();
  }

  AppMood _parseMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'chill':
        return AppMood.chill;
      case 'energetic':
        return AppMood.energetic;
      case 'dark':
        return AppMood.dark;
      case 'euphoric':
        return AppMood.euphoric;
      default:
        return AppMood.neutral;
    }
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>(
  (ref) => AIChatNotifier(ref.watch(aiServiceProvider), ref),
);
