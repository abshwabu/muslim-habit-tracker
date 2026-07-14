import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import 'habit_ui_utils.dart';

/// Fixed 1080×1080 shareable card for social export.
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.streakDays,
    required this.date,
    required this.dueHabits,
    required this.todayLogs,
    this.appName = 'Muslim Habit Tracker',
  });

  static const double size = 1080;

  final int streakDays;
  final DateTime date;
  final List<Habit> dueHabits;
  final Map<String, HabitLog> todayLogs;
  final String appName;

  static const Color sand = Color(0xFFF5F0E8);
  static const Color sage = Color(0xFF5B7C5A);
  static const Color earth = Color(0xFF8B7355);
  static const Color ink = Color(0xFF3D3A34);

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMEd().format(date);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: sand,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7F3EB),
            Color(0xFFEDE6DA),
            Color(0xFFE4DDD0),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _SoftBlob(
              diameter: 360,
              color: sage.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _SoftBlob(
              diameter: 420,
              color: earth.withValues(alpha: 0.14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 80, 72, 72),
            child: Column(
              children: [
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: sage,
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  '$streakDays',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 220,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                    color: sage,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'day streak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: earth,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: ink.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 36),
                if (dueHabits.isEmpty)
                  Text(
                    'No habits due today',
                    style: TextStyle(
                      fontSize: 24,
                      color: ink.withValues(alpha: 0.45),
                    ),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      for (final habit in dueHabits)
                        _HabitStatusChip(
                          habit: habit,
                          completed: todayLogs[habit.id]?.completed == true,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _HabitStatusChip extends StatelessWidget {
  const _HabitStatusChip({
    required this.habit,
    required this.completed,
  });

  final Habit habit;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final accent = colorFromHex(habit.colorHex);
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            habitIconData(habit.icon),
            size: 32,
            color: accent,
          ),
          const SizedBox(height: 8),
          Icon(
            completed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 26,
            color: completed ? StreakCard.sage : const Color(0xFFB07A6A),
          ),
        ],
      ),
    );
  }
}
