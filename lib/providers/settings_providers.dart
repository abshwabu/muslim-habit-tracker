import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

import '../models/hive_setup.dart';
import '../services/app_settings.dart';

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(HiveBoxes.settings);
});

/// Haptic feedback when toggling habit completion. Default: on.
class HapticFeedbackNotifier extends StateNotifier<bool> {
  HapticFeedbackNotifier(this._box) : super(readHapticFeedback(_box));

  final Box _box;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _box.put(SettingsKeys.hapticFeedback, enabled);
  }
}

final hapticFeedbackProvider =
    StateNotifierProvider<HapticFeedbackNotifier, bool>((ref) {
  return HapticFeedbackNotifier(ref.watch(settingsBoxProvider));
});

/// Days shown in the home habit grid. Default: 30.
class GridRangeNotifier extends StateNotifier<int> {
  GridRangeNotifier(this._box) : super(readGridRange(_box));

  final Box _box;

  Future<void> setRange(int days) async {
    if (!kGridRangeOptions.contains(days)) {
      throw ArgumentError.value(days, 'days', 'Must be one of $kGridRangeOptions');
    }
    state = days;
    await _box.put(SettingsKeys.gridRange, days);
  }
}

final gridRangeProvider =
    StateNotifierProvider<GridRangeNotifier, int>((ref) {
  return GridRangeNotifier(ref.watch(settingsBoxProvider));
});

/// Week starts on Monday when `true`, Sunday when `false`. Default: Monday.
class WeekStartNotifier extends StateNotifier<bool> {
  WeekStartNotifier(this._box) : super(readWeekStartsOnMonday(_box));

  final Box _box;

  Future<void> setStartsOnMonday(bool monday) async {
    state = monday;
    await _box.put(SettingsKeys.weekStartsOnMonday, monday);
  }
}

final weekStartsOnMondayProvider =
    StateNotifierProvider<WeekStartNotifier, bool>((ref) {
  return WeekStartNotifier(ref.watch(settingsBoxProvider));
});
