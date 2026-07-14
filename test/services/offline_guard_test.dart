import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/services/app_info.dart';

/// Airplane-mode / local-first guardrails for app Dart sources.
void main() {
  test('AppInfo is Muslim Habit Tracker and local-first', () {
    expect(AppInfo.name, 'Muslim Habit Tracker');
    expect(AppInfo.attribution.toLowerCase(), contains('local-first'));
  });

  test('lib/ has no direct network client imports', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue);

    final offenders = <String>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains("import 'package:http/") ||
          source.contains('import "package:http/') ||
          source.contains("import 'package:dio/") ||
          source.contains('import "package:dio/') ||
          source.contains('HttpClient(') ||
          RegExp(r"\bdio\.|Dio\(").hasMatch(source)) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Network client usage found in: $offenders',
    );
  });
}
