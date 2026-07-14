/// App identity for About (keep in sync with pubspec.yaml `version`).
abstract final class AppInfo {
  static const name = 'Muslim Habit Tracker';
  static const version = '1.0.0';
  static const buildNumber = '1';

  static String get versionLabel => '$version ($buildNumber)';

  static const attribution =
      'A local-first tracker for daily good deeds. '
      'Grid layout inspired by Loop Habit Tracker.';
}
