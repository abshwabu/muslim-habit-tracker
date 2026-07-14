import 'package:flutter/material.dart';

/// Placeholder until habit editing (Step 9) is implemented.
class EditHabitScreen extends StatelessWidget {
  const EditHabitScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Habit')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Habit editing coming in Step 9.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                ),
          ),
        ),
      ),
    );
  }
}
