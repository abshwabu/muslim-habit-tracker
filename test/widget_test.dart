import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_habit_tracker/main.dart';

void main() {
  testWidgets('HomeScreen shows Habit Tracker title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MuslimHabitTrackerApp(),
      ),
    );

    expect(find.text('Habit Tracker'), findsOneWidget);
    expect(find.text('Welcome'), findsOneWidget);
  });
}
