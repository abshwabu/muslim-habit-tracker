import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/hive_setup.dart';
import 'screens/home_screen.dart';
import 'services/local_notification_service.dart';
import 'services/seed_defaults.dart';
import 'theme/app_theme.dart';
import 'widgets/reminder_sync_binder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await seedDefaultHabitsIfNeeded();
  try {
    await LocalNotificationService.instance.initialize();
  } catch (_) {
    // Optional on unsupported platforms.
  }

  runApp(
    const ProviderScope(
      child: MuslimHabitTrackerApp(),
    ),
  );
}

class MuslimHabitTrackerApp extends StatelessWidget {
  const MuslimHabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ReminderSyncBinder(
        child: HomeScreen(),
      ),
    );
  }
}
