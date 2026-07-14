import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/stats_calculator.dart';
import '../widgets/habit_ui_utils.dart';
import 'share_export_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfect = ref.watch(perfectDayStreakProvider);
    final habitStats = ref.watch(habitStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ShareExportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Perfect days',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BigStatCard(
                  label: 'Current streak',
                  value: '${perfect.currentStreak}',
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStatCard(
                  label: 'Longest streak',
                  value: '${perfect.longestStreak}',
                  color: scheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Per habit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last $kStatsWindowDays days · due days only',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
          const SizedBox(height: 12),
          if (habitStats.isEmpty)
            Text(
              'No active habits yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            )
          else
            for (final row in habitStats) ...[
              _HabitStatTile(stats: row),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 18),
          Text(
            'Overall',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (habitStats.isEmpty)
            Text(
              'Complete habits to see totals.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final row in habitStats)
                  _OverallChip(
                    habitName: row.habit.name,
                    count: row.lifetimeCompletions,
                    color: colorFromHex(row.habit.colorHex),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  const _BigStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _HabitStatTile extends StatelessWidget {
  const _HabitStatTile({required this.stats});

  final HabitWindowStats stats;

  @override
  Widget build(BuildContext context) {
    final habit = stats.habit;
    final color = colorFromHex(habit.colorHex);
    final scheme = Theme.of(context).colorScheme;
    final ratePct = (stats.completionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(habitIconData(habit.icon), size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habit.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '${stats.streak.currentStreak} / ${stats.streak.longestStreak}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'streak current / longest',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.completionRate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$ratePct% · ${stats.completedDueDays} of ${stats.totalDueDays} due days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
        ],
      ),
    );
  }
}

class _OverallChip extends StatelessWidget {
  const _OverallChip({
    required this.habitName,
    required this.count,
    required this.color,
  });

  final String habitName;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final unit = _unitFor(habitName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$habitName $unit',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                ),
          ),
        ],
      ),
    );
  }

  static String _unitFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('qiyam') || lower.contains('night')) return 'nights';
    if (lower.contains('fast')) return 'days';
    return 'days';
  }
}
