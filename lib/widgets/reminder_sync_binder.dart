import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/reminder_sync.dart';

/// Keeps offline reminder schedules in sync with habits/settings.
class ReminderSyncBinder extends ConsumerStatefulWidget {
  const ReminderSyncBinder({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderSyncBinder> createState() => _ReminderSyncBinderState();
}

class _ReminderSyncBinderState extends ConsumerState<ReminderSyncBinder>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }

  void _sync() {
    unawaited(() async {
      try {
        await syncHabitReminders(ref);
      } catch (_) {
        // Plugin unavailable in some test/desktop environments.
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(habitsProvider, (_, __) => _sync());
    ref.listen(todayLogsRevisionProvider, (_, __) => _sync());
    ref.listen(remindersEnabledProvider, (_, __) => _sync());
    ref.listen(eveningReminderMinutesProvider, (_, __) => _sync());
    return widget.child;
  }
}
