import 'package:hive/hive.dart';

import '../models/hive_setup.dart';

/// Keys stored in [HiveBoxes.settings] (alongside [hasSeededKey]).
abstract final class SettingsKeys {
  static const hapticFeedback = 'hapticFeedback';
  static const gridRange = 'gridRange';
  static const weekStartsOnMonday = 'weekStartsOnMonday';
  static const remindersEnabled = 'remindersEnabled';
  static const eveningReminderMinutes = 'eveningReminderMinutes';
}

const List<int> kGridRangeOptions = [14, 30, 60];

/// Default evening reminder: 20:00 local.
const int kDefaultEveningReminderMinutes = 20 * 60;

bool readHapticFeedback(Box box) =>
    box.get(SettingsKeys.hapticFeedback, defaultValue: true) as bool;

int readGridRange(Box box) {
  final value = box.get(SettingsKeys.gridRange);
  if (value is int && kGridRangeOptions.contains(value)) return value;
  return 30;
}

/// `true` = Monday first (default), `false` = Sunday first.
bool readWeekStartsOnMonday(Box box) =>
    box.get(SettingsKeys.weekStartsOnMonday, defaultValue: true) as bool;

bool readRemindersEnabled(Box box) =>
    box.get(SettingsKeys.remindersEnabled, defaultValue: false) as bool;

int readEveningReminderMinutes(Box box) {
  final value = box.get(SettingsKeys.eveningReminderMinutes);
  if (value is int && value >= 0 && value < 24 * 60) return value;
  return kDefaultEveningReminderMinutes;
}

(int hour, int minute) minutesToHourMinute(int totalMinutes) =>
    (totalMinutes ~/ 60, totalMinutes % 60);

int hourMinuteToMinutes(int hour, int minute) => hour * 60 + minute;

/// Weekday chips ordered by week-start preference.
///
/// Values are Dart weekday numbers: `1=Mon` … `7=Sun`.
List<(int weekday, String label)> orderedWeekdayLabels({
  required bool weekStartsOnMonday,
}) {
  const monFirst = <(int, String)>[
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];
  if (weekStartsOnMonday) return monFirst;
  return [monFirst.last, ...monFirst.sublist(0, 6)];
}
