import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/habit.dart';
import '../providers/providers.dart';
import '../services/habit_repository.dart';
import '../services/schedule_calculator.dart';
import '../services/streak_calculator.dart';
import '../widgets/habit_ui_utils.dart';
import 'edit_habit_screen.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habit = ref.watch(habitByIdProvider(habitId));
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit')),
        body: const Center(child: Text('Habit not found')),
      );
    }

    final streak = ref.watch(habitComputedStreakProvider(habitId));
    final logs = ref.watch(habitLogsProvider(habitId));
    final completedDates = {
      for (final log in logs)
        if (log.completed) log.date,
    };
    final color = colorFromHex(habit.colorHex);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Header(habit: habit, color: color),
          const SizedBox(height: 20),
          _StreakCards(
            current: streak.currentStreak,
            longest: streak.longestStreak,
            color: color,
          ),
          const SizedBox(height: 24),
          Text(
            'History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _HabitHistoryCalendar(
            habit: habit,
            completedDates: completedDates,
            color: color,
          ),
          const SizedBox(height: 16),
          _RecentHistoryList(
            habit: habit,
            completedDates: completedDates,
            color: color,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EditHabitScreen(habitId: habitId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmArchive(context, ref, habit),
                  icon: Icon(Icons.archive_outlined, color: scheme.error),
                  label: Text(
                    'Archive',
                    style: TextStyle(color: scheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Archive habit?'),
          content: Text(
            '"${habit.name}" will be hidden from your grid. '
            'Your completion history and streaks are preserved and are not deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(habitsProvider.notifier).archiveHabit(habit.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.habit, required this.color});

  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(habitIconData(habit.icon), color: color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
              ),
              if (habit.arabicName != null && habit.arabicName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  habit.arabicName!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                frequencyDescription(habit),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakCards extends StatelessWidget {
  const _StreakCards({
    required this.current,
    required this.longest,
    required this.color,
  });

  final int current;
  final int longest;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Current streak',
            value: '$current',
            subtitle: current == 1 ? 'day' : 'days',
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'Longest streak',
            value: '$longest',
            subtitle: longest == 1 ? 'day' : 'days',
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}

class _HabitHistoryCalendar extends ConsumerWidget {
  const _HabitHistoryCalendar({
    required this.habit,
    required this.completedDates,
    required this.color,
  });

  final Habit habit;
  final Set<String> completedDates;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = todayDate();
    final firstDay = dateOnly(habit.createdAt);
    final scheme = Theme.of(context).colorScheme;
    final weekStartsOnMonday = ref.watch(weekStartsOnMondayProvider);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: TableCalendar<void>(
        firstDay: firstDay.isAfter(today) ? today : firstDay,
        lastDay: today,
        focusedDay: today,
        startingDayOfWeek: weekStartsOnMonday
            ? StartingDayOfWeek.monday
            : StartingDayOfWeek.sunday,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: color.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(shape: BoxShape.circle),
        ),
        selectedDayPredicate: (_) => false,
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focused) =>
              _dayCell(context, day, color, completedDates),
          todayBuilder: (context, day, focused) =>
              _dayCell(context, day, color, completedDates, isToday: true),
          disabledBuilder: (context, day, focused) =>
              _dayCell(context, day, color, completedDates, disabled: true),
        ),
      ),
    );
  }

  Widget _dayCell(
    BuildContext context,
    DateTime day,
    Color color,
    Set<String> completed, {
    bool isToday = false,
    bool disabled = false,
  }) {
    final due = isDueOn(habit, day);
    final key = HabitRepository.formatDate(day);
    final done = completed.contains(key);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

    Widget mark;
    if (!due) {
      mark = Text('–', style: TextStyle(color: muted, fontSize: 14));
    } else if (done) {
      mark = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    } else {
      mark = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: isToday
          ? BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: disabled
                      ? muted
                      : Theme.of(context).colorScheme.onSurface.withValues(
                            alpha: 0.75,
                          ),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          mark,
        ],
      ),
    );
  }
}

class _RecentHistoryList extends StatelessWidget {
  const _RecentHistoryList({
    required this.habit,
    required this.completedDates,
    required this.color,
  });

  final Habit habit;
  final Set<String> completedDates;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final today = todayDate();
    final start = dateOnly(habit.createdAt);
    final dueDays = <DateTime>[];
    for (var d = today;
        !d.isBefore(start) && dueDays.length < 14;
        d = d.subtract(const Duration(days: 1))) {
      if (isDueOn(habit, d)) dueDays.add(d);
    }

    if (dueDays.isEmpty) {
      return Text(
        'No due days yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
            ),
      );
    }

    final dateFormat = DateFormat.yMMMd();

    return Column(
      children: [
        for (final day in dueDays)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              completedDates.contains(HabitRepository.formatDate(day))
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: completedDates.contains(HabitRepository.formatDate(day))
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.35,
                      ),
            ),
            title: Text(dateFormat.format(day)),
            subtitle: Text(
              completedDates.contains(HabitRepository.formatDate(day))
                  ? 'Completed'
                  : day == today
                      ? 'Not yet today'
                      : 'Missed',
            ),
          ),
      ],
    );
  }
}
