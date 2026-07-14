import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_habit_tracker/services/app_settings.dart';

void main() {
  test('orderedWeekdayLabels monday first', () {
    final labels = orderedWeekdayLabels(weekStartsOnMonday: true);
    expect(labels.first.$1, 1);
    expect(labels.first.$2, 'Mon');
    expect(labels.last.$1, 7);
    expect(labels.last.$2, 'Sun');
  });

  test('orderedWeekdayLabels sunday first', () {
    final labels = orderedWeekdayLabels(weekStartsOnMonday: false);
    expect(labels.map((e) => e.$1).toList(), [7, 1, 2, 3, 4, 5, 6]);
    expect(labels.first.$2, 'Sun');
  });
}
