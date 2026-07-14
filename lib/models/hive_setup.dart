import 'package:hive_flutter/hive_flutter.dart';

import 'frequency_type.dart';
import 'habit.dart';
import 'habit_log.dart';
import 'habit_streak.dart';
import 'perfect_day_streak.dart';

/// Hive box name constants.
abstract final class HiveBoxes {
  static const habits = 'habits';
  static const habitLogs = 'habitLogs';
  static const habitStreaks = 'habitStreaks';
  static const perfectDayStreak = 'perfectDayStreak';
}

/// Registers all TypeAdapters and opens app boxes.
Future<void> initHive() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FrequencyTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(HabitAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(HabitLogAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(HabitStreakAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(PerfectDayStreakAdapter());
  }

  await Future.wait([
    Hive.openBox<Habit>(HiveBoxes.habits),
    Hive.openBox<HabitLog>(HiveBoxes.habitLogs),
    Hive.openBox<HabitStreak>(HiveBoxes.habitStreaks),
    Hive.openBox<PerfectDayStreak>(HiveBoxes.perfectDayStreak),
  ]);
}
