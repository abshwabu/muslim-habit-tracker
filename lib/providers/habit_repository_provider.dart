import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/habit_repository.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

/// Calendar day at local midnight (time stripped).
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime todayDate() => dateOnly(DateTime.now());
