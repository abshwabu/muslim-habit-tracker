import 'package:flutter/material.dart';

/// Parses `#RRGGBB` / `#AARRGGBB` into a [Color].
Color colorFromHex(String hex) {
  var cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  return Color(int.parse(cleaned, radix: 16));
}

IconData habitIconData(String key) {
  switch (key) {
    case 'book':
      return Icons.menu_book_rounded;
    case 'prayer-beads':
      return Icons.self_improvement_rounded;
    case 'heart-hand':
      return Icons.volunteer_activism_rounded;
    case 'moon-star':
      return Icons.nightlight_round;
    case 'stars':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.circle_outlined;
  }
}

const double kHabitNameColumnWidth = 148;
const double kGridCellSize = 28;
const double kGridRowHeight = 44;
const double kGridHeaderHeight = 28;
