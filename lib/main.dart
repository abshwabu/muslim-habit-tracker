import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/hive_setup.dart';
import 'screens/home_screen.dart';
import 'services/seed_defaults.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await seedDefaultHabitsIfNeeded();

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
      home: const HomeScreen(),
    );
  }
}
