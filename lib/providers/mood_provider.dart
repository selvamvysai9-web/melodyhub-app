import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/mood_theme.dart';

class MoodState {
  final AppMood mood;
  final String rationale;

  const MoodState({
    this.mood = AppMood.neutral,
    this.rationale = 'Default Vibe',
  });

  MoodState copyWith({AppMood? mood, String? rationale}) {
    return MoodState(
      mood: mood ?? this.mood,
      rationale: rationale ?? this.rationale,
    );
  }
}

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(const MoodState());

  void updateMood(AppMood newMood, String rationale) {
    state = state.copyWith(mood: newMood, rationale: rationale);
  }

  void resetMood() {
    state = const MoodState();
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier();
});
