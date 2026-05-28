import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PremiumTier { free, plus, pro }

class PremiumState {
  final PremiumTier tier;
  final DateTime? expiryDate;
  final bool showPaywall;

  const PremiumState({
    this.tier = PremiumTier.free,
    this.expiryDate,
    this.showPaywall = false,
  });

  PremiumState copyWith({
    PremiumTier? tier,
    DateTime? expiryDate,
    bool? showPaywall,
  }) {
    return PremiumState(
      tier: tier ?? this.tier,
      expiryDate: expiryDate ?? this.expiryDate,
      showPaywall: showPaywall ?? this.showPaywall,
    );
  }

  bool get isPremium => tier != PremiumTier.free;
}

class PremiumNotifier extends StateNotifier<PremiumState> {
  PremiumNotifier() : super(const PremiumState());

  void upgrade(PremiumTier tier) {
    state = state.copyWith(
      tier: tier,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      showPaywall: false,
    );
  }

  void showPaywall() {
    state = state.copyWith(showPaywall: true);
  }

  void hidePaywall() {
    state = state.copyWith(showPaywall: false);
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>(
  (ref) => PremiumNotifier(),
);
