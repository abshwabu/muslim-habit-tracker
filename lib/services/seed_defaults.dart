import 'package:hive/hive.dart';

import '../models/frequency_type.dart';
import '../models/habit.dart';
import '../models/hive_setup.dart';
import 'habit_repository.dart';

const String hasSeededKey = 'hasSeeded';

/// Built-in defaults (stable ids). [Habit.isCustom] is always false.
List<Habit> buildDefaultHabits({DateTime? createdAt}) {
  final now = createdAt ?? DateTime.now();
  return [
    Habit(
      id: 'seed_quran',
      name: "Qur'an Reading",
      arabicName: 'قراءة القرآن',
      icon: 'book',
      colorHex: '#3D6B4F',
      frequencyType: FrequencyType.daily,
      isCustom: false,
      isActive: true,
      createdAt: now,
    ),
    Habit(
      id: 'seed_dhikr',
      name: 'Dhikr',
      arabicName: 'الذكر',
      icon: 'prayer-beads',
      colorHex: '#4A7C6F',
      frequencyType: FrequencyType.daily,
      isCustom: false,
      isActive: true,
      createdAt: now,
    ),
    Habit(
      id: 'seed_sadaqah',
      name: 'Sadaqah',
      arabicName: 'صدقة',
      icon: 'heart-hand',
      colorHex: '#C4785A',
      frequencyType: FrequencyType.daily,
      isCustom: false,
      isActive: true,
      createdAt: now,
    ),
    Habit(
      id: 'seed_fasting',
      name: 'Voluntary Fasting',
      arabicName: 'صيام التطوع',
      icon: 'moon-star',
      colorHex: '#5A6B8C',
      frequencyType: FrequencyType.specificWeekdays,
      weekdays: const [1, 4],
      isCustom: false,
      isActive: true,
      createdAt: now,
    ),
    Habit(
      id: 'seed_qiyam',
      name: 'Night Prayer (Qiyam)',
      arabicName: 'قيام الليل',
      icon: 'stars',
      colorHex: '#B8956A',
      frequencyType: FrequencyType.daily,
      isCustom: false,
      isActive: true,
      createdAt: now,
    ),
  ];
}

/// One-time seed of default habits. Safe to call on every launch.
Future<void> seedDefaultHabitsIfNeeded({
  HabitRepository? repository,
  Box? settingsBox,
}) async {
  final settings = settingsBox ?? Hive.box(HiveBoxes.settings);
  if (settings.get(hasSeededKey) == true) return;

  final repo = repository ?? HabitRepository();
  for (final habit in buildDefaultHabits()) {
    await repo.addHabit(habit);
  }
  await settings.put(hasSeededKey, true);
}
