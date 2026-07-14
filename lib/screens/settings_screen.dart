import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/hive_setup.dart';
import '../providers/providers.dart';
import '../services/app_info.dart';
import '../services/app_settings.dart';
import '../services/local_notification_service.dart';
import '../services/reminder_sync.dart';
import '../services/seed_defaults.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haptic = ref.watch(hapticFeedbackProvider);
    final gridRange = ref.watch(gridRangeProvider);
    final weekStartsOnMonday = ref.watch(weekStartsOnMondayProvider);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final eveningMinutes = ref.watch(eveningReminderMinutesProvider);
    final eveningTime = TimeOfDay(
      hour: eveningMinutes ~/ 60,
      minute: eveningMinutes % 60,
    );
    final scheme = Theme.of(context).colorScheme;
    final timeLabel = eveningTime.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionLabel('Reminders'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Local reminders'),
            subtitle: const Text(
              'Evening incomplete-habit alert and Mon/Thu fasting nudges. '
              'Scheduled on-device only — no push service.',
            ),
            value: remindersEnabled,
            onChanged: (value) => _onRemindersToggled(context, ref, value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: remindersEnabled,
            title: const Text('Evening reminder time'),
            subtitle: Text(
              remindersEnabled
                  ? timeLabel
                  : 'Enable reminders to set a time',
            ),
            trailing: const Icon(Icons.schedule_rounded),
            onTap: remindersEnabled
                ? () => _pickEveningTime(context, ref, eveningTime)
                : null,
          ),
          Text(
            'Fasting nudges fire at '
            '${LocalNotificationService.fastingMorningHour.toString().padLeft(2, '0')}'
            ':${LocalNotificationService.fastingMorningMinute.toString().padLeft(2, '0')} '
            'on Mondays and Thursdays only when a Sunnah fasting habit is due.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 28),
          _SectionLabel('Preferences'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Haptic feedback'),
            subtitle: const Text('Vibrate when toggling a habit'),
            value: haptic,
            onChanged: (value) {
              ref.read(hapticFeedbackProvider.notifier).setEnabled(value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Grid range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'How many days appear in the home grid',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [
              for (final days in kGridRangeOptions)
                ButtonSegment(
                  value: days,
                  label: Text('$days'),
                ),
            ],
            selected: {gridRange},
            onSelectionChanged: (next) {
              ref.read(gridRangeProvider.notifier).setRange(next.first);
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Week starts on',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Orders the habit calendar header and weekday picker',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Monday'),
              ),
              ButtonSegment(
                value: false,
                label: Text('Sunday'),
              ),
            ],
            selected: {weekStartsOnMonday},
            onSelectionChanged: (next) {
              ref
                  .read(weekStartsOnMondayProvider.notifier)
                  .setStartsOnMonday(next.first);
            },
          ),
          const SizedBox(height: 28),
          _SectionLabel('Data'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever_rounded, color: scheme.error),
            title: Text(
              'Reset all data',
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Permanently deletes habits, logs, and streaks',
            ),
            onTap: () => _confirmReset(context, ref),
          ),
          const SizedBox(height: 28),
          _SectionLabel('About'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppInfo.name),
            subtitle: Text('Version ${AppInfo.versionLabel}'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppInfo.attribution,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRemindersToggled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      final service = ref.read(localNotificationServiceProvider);
      final granted = await service.requestPermissions();
      if (!context.mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required for reminders'),
          ),
        );
        return;
      }
    }
    await ref.read(remindersEnabledProvider.notifier).setEnabled(enabled);
  }

  Future<void> _pickEveningTime(
    BuildContext context,
    WidgetRef ref,
    TimeOfDay current,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    await ref.read(eveningReminderMinutesProvider.notifier).setMinutes(
          hourMinuteToMinutes(picked.hour, picked.minute),
        );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This will permanently delete every habit, completion log, '
          'and streak. App preferences like grid range are kept.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Continue',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'Tap “Erase everything” to wipe your tracker and restore '
          'the default habits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    await _resetAllData(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data reset. Default habits restored.')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _resetAllData(WidgetRef ref) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.clearAllHabitData();

    final settings = Hive.box(HiveBoxes.settings);
    await settings.delete(hasSeededKey);
    await seedDefaultHabitsIfNeeded(repository: repo, settingsBox: settings);

    ref.read(habitsProvider.notifier).refresh();
    ref.read(habitStreaksProvider.notifier).refresh();
    ref.read(perfectDayStreakProvider.notifier).refresh();
    ref.read(todayLogsRevisionProvider.notifier).state++;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
