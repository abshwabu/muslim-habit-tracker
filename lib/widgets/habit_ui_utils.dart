import 'package:flutter/material.dart';

/// Parses `#RRGGBB` / `#AARRGGBB` into a [Color].
Color colorFromHex(String hex) {
  var cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  return Color(int.parse(cleaned, radix: 16));
}

/// Fixed icon keys available in the habit form picker.
const List<String> kHabitIconOptions = [
  'book',
  'prayer-beads',
  'heart-hand',
  'moon-star',
  'stars',
  'mosque',
  'hands',
  'water',
  'leaf',
  'sun',
  'heart',
  'check',
];

/// Fixed earth/sage color palette for habit accents.
const List<String> kHabitColorPalette = [
  '#3D6B4F',
  '#4A7C6F',
  '#C4785A',
  '#5A6B8C',
  '#B8956A',
  '#6B8F71',
  '#8B6B5A',
  '#7A6B8C',
  '#5A7A8B',
  '#A67C52',
];

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
    case 'mosque':
      return Icons.mosque_rounded;
    case 'hands':
      return Icons.front_hand_rounded;
    case 'water':
      return Icons.water_drop_rounded;
    case 'leaf':
      return Icons.eco_rounded;
    case 'sun':
      return Icons.wb_sunny_rounded;
    case 'heart':
      return Icons.favorite_rounded;
    case 'check':
      return Icons.task_alt_rounded;
    default:
      return Icons.circle_outlined;
  }
}

const double kHabitNameColumnWidth = 148;
const double kGridCellSize = 28;
const double kGridRowHeight = 44;
const double kGridHeaderHeight = 28;
