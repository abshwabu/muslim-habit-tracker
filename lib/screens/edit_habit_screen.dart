import 'package:flutter/material.dart';

import 'add_habit_screen.dart';

/// Opens the shared habit form in edit mode.
class EditHabitScreen extends StatelessWidget {
  const EditHabitScreen({super.key, required this.habitId});

  final String habitId;

  @override
  Widget build(BuildContext context) {
    return AddHabitScreen(habitId: habitId);
  }
}
