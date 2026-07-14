import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../services/habit_repository.dart';
import '../services/schedule_calculator.dart';
import 'habit_ui_utils.dart';

/// Single grid cell: not-due dash, empty circle, or filled circle.
class HabitGridCell extends StatelessWidget {
  const HabitGridCell({
    super.key,
    required this.habit,
    required this.date,
    required this.completed,
    required this.onToggle,
  });

  final Habit habit;
  final DateTime date;
  final bool completed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final due = isDueOn(habit, date);
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isFuture = dateOnly.isAfter(todayOnly);
    final tappable = due && !isFuture && onToggle != null;

    final color = colorFromHex(habit.colorHex);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.22);

    Widget glyph;
    if (!due) {
      glyph = Text(
        '–',
        style: TextStyle(
          color: muted,
          fontSize: 16,
          fontWeight: FontWeight.w300,
          height: 1,
        ),
      );
    } else if (completed) {
      glyph = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    } else {
      glyph = Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
        ),
      );
    }

    return SizedBox(
      width: kGridCellSize,
      height: kGridRowHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tappable ? onToggle : null,
          customBorder: const CircleBorder(),
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

/// Day-of-week letter above a column.
class HabitGridDayHeader extends StatelessWidget {
  const HabitGridDayHeader({super.key, required this.date});

  final DateTime date;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final isToday = HabitRepository.formatDate(date) ==
        HabitRepository.formatDate(DateTime.now());
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: isToday ? 0.9 : 0.45,
              ),
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        );

    return SizedBox(
      width: kGridCellSize,
      height: kGridHeaderHeight,
      child: Center(
        child: Text(_letters[date.weekday - 1], style: style),
      ),
    );
  }
}

class HabitNameCell extends StatelessWidget {
  const HabitNameCell({
    super.key,
    required this.habit,
    this.onTap,
  });

  final Habit habit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(habit.colorHex);

    return SizedBox(
      width: kHabitNameColumnWidth,
      height: kGridRowHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(habitIconData(habit.icon), size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
