import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/providers.dart';
import '../screens/habit_detail_screen.dart';
import '../services/habit_repository.dart';
import '../services/schedule_calculator.dart';
import 'habit_grid_cell.dart';
import 'habit_ui_utils.dart';

/// Loop / GitHub-style habit grid with a pinned name column.
class HabitGrid extends ConsumerWidget {
  const HabitGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final dates = ref.watch(gridDatesProvider);
    final logs = ref.watch(gridLogsProvider);

    if (habits.isEmpty) {
      return Center(
        child: Text(
          'No active habits yet',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 0.55,
                    ),
              ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        final daysWidth = (constraints.maxWidth -
                kHabitNameColumnWidth -
                horizontalPadding)
            .clamp(0.0, double.infinity);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: kHabitNameColumnWidth,
                    height: kGridHeaderHeight,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Habit',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ),
                  for (final habit in habits)
                    HabitNameCell(
                      habit: habit,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                HabitDetailScreen(habitId: habit.id),
                          ),
                        );
                      },
                    ),
                ],
              ),
              SizedBox(
                width: daysWidth,
                child: _HorizontalDays(
                  dates: dates,
                  habits: habits,
                  logs: logs,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Scrollable day columns; jumps to the trailing edge (most recent / today).
class _HorizontalDays extends StatefulWidget {
  const _HorizontalDays({
    required this.dates,
    required this.habits,
    required this.logs,
  });

  final List<DateTime> dates;
  final List<Habit> habits;
  final Map<String, HabitLog> logs;

  @override
  State<_HorizontalDays> createState() => _HorizontalDaysState();
}

class _HorizontalDaysState extends State<_HorizontalDays> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      if (max > 0) _controller.jumpTo(max);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      child: Consumer(
        builder: (context, ref, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final date in widget.dates)
                    HabitGridDayHeader(date: date),
                ],
              ),
              for (final habit in widget.habits)
                _HabitCellsRow(
                  habit: habit,
                  dates: widget.dates,
                  logs: widget.logs,
                  onToggle: (date) {
                    ref
                        .read(habitsProvider.notifier)
                        .toggleCompletion(habit.id, date: date);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HabitCellsRow extends StatelessWidget {
  const _HabitCellsRow({
    required this.habit,
    required this.dates,
    required this.logs,
    required this.onToggle,
  });

  final Habit habit;
  final List<DateTime> dates;
  final Map<String, HabitLog> logs;
  final void Function(DateTime date) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final date in dates)
          HabitGridCell(
            habit: habit,
            date: date,
            completed: _completed(habit, date),
            onToggle: isDueOn(habit, date) ? () => onToggle(date) : null,
          ),
      ],
    );
  }

  bool _completed(Habit habit, DateTime date) {
    final key = HabitRepository.logKey(
      habit.id,
      HabitRepository.formatDate(date),
    );
    return logs[key]?.completed ?? false;
  }
}
