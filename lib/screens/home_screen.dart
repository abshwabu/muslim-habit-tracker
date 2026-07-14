import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/habit_grid.dart';
import '../widgets/perfect_day_banner.dart';
import 'add_habit_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            tooltip: 'Stats',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PerfectDayBanner(),
          Expanded(child: HabitGrid()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddHabitScreen(),
            ),
          );
        },
        tooltip: 'Add habit',
        child: const Icon(Icons.add),
      ),
    );
  }
}
