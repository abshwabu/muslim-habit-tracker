import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/frequency_type.dart';
import '../models/habit.dart';
import '../providers/providers.dart';
import '../widgets/habit_ui_utils.dart';

/// Create a new habit, or edit an existing one when [habitId] is set.
///
/// Frequency changes apply going forward only — historical logs are never rewritten.
class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key, this.habitId});

  /// When non-null, the form edits that habit instead of creating one.
  final String? habitId;

  bool get isEditing => habitId != null;

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _arabicController = TextEditingController();

  late FrequencyType _frequencyType;
  late Set<int> _weekdays;
  late String _icon;
  late String _colorHex;
  Habit? _existing;
  var _initialized = false;
  var _saving = false;

  static const _weekdayLabels = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureInitialized();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _arabicController.dispose();
    super.dispose();
  }

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    if (widget.habitId != null) {
      _existing = ref.read(habitRepositoryProvider).getHabit(widget.habitId!);
    }

    final existing = _existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _arabicController.text = existing.arabicName ?? '';
      _frequencyType = existing.frequencyType;
      _weekdays = existing.weekdays.toSet();
      _icon = kHabitIconOptions.contains(existing.icon)
          ? existing.icon
          : kHabitIconOptions.first;
      _colorHex = kHabitColorPalette.contains(existing.colorHex)
          ? existing.colorHex
          : kHabitColorPalette.first;
    } else {
      _frequencyType = FrequencyType.daily;
      _weekdays = {};
      _icon = kHabitIconOptions.first;
      _colorHex = kHabitColorPalette.first;
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _weekdayError() {
    if (_frequencyType == FrequencyType.specificWeekdays &&
        _weekdays.isEmpty) {
      return 'Select at least one weekday';
    }
    return null;
  }

  Future<void> _save() async {
    final weekdayError = _weekdayError();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || weekdayError != null) {
      setState(() {});
      return;
    }

    setState(() => _saving = true);
    final name = _nameController.text.trim();
    final arabic = _arabicController.text.trim();
    final arabicName = arabic.isEmpty ? null : arabic;
    final weekdays = _frequencyType == FrequencyType.specificWeekdays
        ? (_weekdays.toList()..sort())
        : <int>[];

    try {
      final notifier = ref.read(habitsProvider.notifier);
      if (widget.isEditing && _existing != null) {
        final existing = _existing!;
        // Replace the whole object so optional arabicName can clear to null.
        // Keep id / createdAt / isCustom / isActive — do not touch logs.
        await notifier.updateHabit(
          Habit(
            id: existing.id,
            name: name,
            arabicName: arabicName,
            icon: _icon,
            colorHex: _colorHex,
            frequencyType: _frequencyType,
            weekdays: weekdays,
            isCustom: existing.isCustom,
            isActive: existing.isActive,
            createdAt: existing.createdAt,
          ),
        );
      } else {
        await notifier.addHabit(
          Habit(
            id: const Uuid().v4(),
            name: name,
            arabicName: arabicName,
            icon: _icon,
            colorHex: _colorHex,
            frequencyType: _frequencyType,
            weekdays: weekdays,
            isCustom: true,
            isActive: true,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekdayError = _weekdayError();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Habit' : 'Add Habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: _validateName,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _arabicController,
              textAlign: TextAlign.start,
              decoration: const InputDecoration(
                labelText: 'Arabic name (optional)',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            Text(
              'Icon',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in kHabitIconOptions)
                  _IconChoice(
                    iconKey: key,
                    selected: _icon == key,
                    color: colorFromHex(_colorHex),
                    onTap: _saving
                        ? null
                        : () => setState(() => _icon = key),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Color',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final hex in kHabitColorPalette)
                  _ColorChoice(
                    hex: hex,
                    selected: _colorHex == hex,
                    onTap: _saving
                        ? null
                        : () => setState(() => _colorHex = hex),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Frequency',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<FrequencyType>(
              segments: const [
                ButtonSegment(
                  value: FrequencyType.daily,
                  label: Text('Every day'),
                  icon: Icon(Icons.today_outlined, size: 18),
                ),
                ButtonSegment(
                  value: FrequencyType.specificWeekdays,
                  label: Text('Specific days'),
                  icon: Icon(Icons.date_range_outlined, size: 18),
                ),
              ],
              selected: {_frequencyType},
              onSelectionChanged: _saving
                  ? null
                  : (next) {
                      setState(() {
                        _frequencyType = next.first;
                      });
                    },
            ),
            if (_frequencyType == FrequencyType.specificWeekdays) ...[
              const SizedBox(height: 16),
              Text(
                'Weekdays',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _weekdayLabels)
                    FilterChip(
                      label: Text(entry.$2),
                      selected: _weekdays.contains(entry.$1),
                      onSelected: _saving
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  _weekdays.add(entry.$1);
                                } else {
                                  _weekdays.remove(entry.$1);
                                }
                              });
                            },
                    ),
                ],
              ),
              if (weekdayError != null) ...[
                const SizedBox(height: 8),
                Text(
                  weekdayError,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Changing frequency only affects future due days. '
                'Past completion history is kept as-is.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(widget.isEditing ? 'Save changes' : 'Create habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          habitIconData(iconKey),
          color: selected
              ? color
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  const _ColorChoice({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(hex);
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}
