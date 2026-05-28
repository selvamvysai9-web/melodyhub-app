import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.timer_rounded, color: AppTheme.accent, size: 24),
          SizedBox(width: 10),
          Text(
            'Sleep Timer',
            style: TextStyle(
                color: AppTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Consumer<MusicProvider>(
        builder: (context, provider, _) {
          final active = provider.sleepTarget != null;
          if (active) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sleep timer active',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<Duration?>(
                  valueListenable: provider.sleepNotifier,
                  builder: (context, remaining, _) {
                    if (remaining == null) {
                      return const Text(
                        'Paused',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 28,
                            fontWeight: FontWeight.w700),
                      );
                    }
                    final mins =
                        remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
                    final secs =
                        remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
                    return Text(
                      '$mins:$secs',
                      style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 32,
                          fontWeight: FontWeight.w700),
                    );
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.cancelSleepTimer();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel Timer',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _timerOption(
                  context, provider, const Duration(minutes: 15), '15 min'),
              _timerOption(
                  context, provider, const Duration(minutes: 30), '30 min'),
              _timerOption(
                  context, provider, const Duration(minutes: 45), '45 min'),
              _timerOption(
                  context, provider, const Duration(minutes: 60), '1 hour'),
            ],
          );
        },
      ),
    );
  }

  Widget _timerOption(
      BuildContext context, MusicProvider provider, Duration duration, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            provider.setSleepTimer(duration);
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.text, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
