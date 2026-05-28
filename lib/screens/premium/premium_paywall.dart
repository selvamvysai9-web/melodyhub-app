import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/premium_provider.dart';
import '../../theme/aurora_theme.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glowing_orb.dart';

class PremiumPaywall extends ConsumerWidget {
  const PremiumPaywall({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      body: Stack(
        children: [
          _buildMeshBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildCloseButton(context),
                  const SizedBox(height: 20),
                  _buildCrown(),
                  const SizedBox(height: 16),
                  _buildHeadline(),
                  const SizedBox(height: 8),
                  _buildSubtitle(),
                  const SizedBox(height: 32),
                  _buildPlans(context, ref),
                  const SizedBox(height: 24),
                  _buildComparisonTable(),
                  const SizedBox(height: 32),
                  _buildTerms(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeshBackground() {
    return Stack(
      children: [
        Container(color: AuroraTheme.oledBlack),
        Positioned(top: -120, right: -80, child: GlowingOrb(size: 240, color: AuroraTheme.accentCyan.withValues(alpha: 0.25), blurRadius: 100)),
        Positioned(bottom: -100, left: -60, child: GlowingOrb(size: 200, color: AuroraTheme.accentPurple.withValues(alpha: 0.2), blurRadius: 80)),
        Positioned(top: 300, left: -40, child: GlowingOrb(size: 150, color: AuroraTheme.accentPink.withValues(alpha: 0.15), blurRadius: 60)),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GlassContainer(
          borderRadius: 20, padding: const EdgeInsets.all(4),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: AuroraTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCrown() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple]),
            boxShadow: [BoxShadow(color: AuroraTheme.accentCyan.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10)],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple, AuroraTheme.accentPink]).createShader(bounds),
          child: const Text('MELODY HUB', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 6)),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(colors: [AuroraTheme.accentCyan, AuroraTheme.accentPurple]).createShader(bounds),
      child: const Text(
        'Unlock the Full Experience',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2),
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Go Premium for unlimited skips, high-quality audio, offline mode, SonicAI, and more.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: AuroraTheme.textSecondary, height: 1.4),
    );
  }

  Widget _buildPlans(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _buildPlanCard(
          context: context,
          title: 'Melody Plus',
          price: '\$4.99',
          period: '/month',
          features: ['Unlimited skips', 'High-quality audio (320kbps)', 'Ad-free', 'Offline downloads (100 tracks)'],
          color: AuroraTheme.accentCyan,
          onTap: () {
            ref.read(premiumProvider.notifier).upgrade(PremiumTier.plus);
            Navigator.pop(context);
          },
          recommended: false,
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          context: context,
          title: 'Melody Pro',
          price: '\$9.99',
          period: '/month',
          features: ['Everything in Plus', 'Unlimited offline', 'SonicAI full access', 'Campfire social sync', 'Lossless FLAC audio'],
          color: AuroraTheme.accentPurple,
          onTap: () {
            ref.read(premiumProvider.notifier).upgrade(PremiumTier.pro);
            Navigator.pop(context);
          },
          recommended: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required Color color,
    required VoidCallback onTap,
    required bool recommended,
  }) {
    return GlassContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      decoration: recommended
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              color: color.withValues(alpha: 0.08),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(20)),
              child: const Text('BEST VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AuroraTheme.oledBlack)),
            ),
          if (recommended) const SizedBox(height: 12),
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AuroraTheme.textPrimary)),
              const Spacer(),
              Text(price, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              Text(period, style: const TextStyle(fontSize: 14, color: AuroraTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: color, size: 18),
                const SizedBox(width: 8),
                Text(f, style: const TextStyle(fontSize: 14, color: AuroraTheme.textSecondary)),
              ],
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AuroraTheme.oledBlack,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: Text('Subscribe to $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return GlassContainer(
      width: double.infinity, padding: const EdgeInsets.all(20), borderRadius: 24,
      child: Column(
        children: [
          const Text('Compare Plans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AuroraTheme.textPrimary)),
          const SizedBox(height: 16),
          _compareRow('Ad-free', true, true, true),
          _compareRow('Unlimited skips', false, true, true),
          _compareRow('320kbps audio', false, true, true),
          _compareRow('Offline mode', false, '100 tracks', 'Unlimited'),
          _compareRow('SonicAI access', false, false, true),
          _compareRow('Campfire sync', false, false, true),
          _compareRow('Lossless FLAC', false, false, true),
        ],
      ),
    );
  }

  Widget _compareRow(String label, dynamic free, dynamic plus, dynamic pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 13, color: AuroraTheme.textSecondary))),
          Expanded(flex: 2, child: _check(free)),
          Expanded(flex: 2, child: _check(plus)),
          Expanded(flex: 2, child: _check(pro)),
        ],
      ),
    );
  }

  Widget _check(dynamic value) {
    if (value == true) {
      return const Icon(Icons.check, color: AuroraTheme.accentGreen, size: 18);
    } else if (value == false) {
      return const Icon(Icons.close, color: AuroraTheme.textMuted, size: 18);
    }
    return Text('$value', style: const TextStyle(fontSize: 12, color: AuroraTheme.textSecondary));
  }

  Widget _buildTerms() {
    return const Text(
      'Cancel anytime. Subscription auto-renews. Terms apply.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: AuroraTheme.textMuted),
    );
  }
}
