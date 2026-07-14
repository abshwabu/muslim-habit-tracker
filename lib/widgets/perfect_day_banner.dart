import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

/// Top banner: perfect-day streak + today's completion progress.
class PerfectDayBanner extends ConsumerWidget {
  const PerfectDayBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(perfectDayStreakProvider).currentStreak;
    final progress = ref.watch(todayCompletionCountProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '🔥 $streak day streak — ${progress.done} of ${progress.total} '
        "today's habits done",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
      ),
    );
  }
}
