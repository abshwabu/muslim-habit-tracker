import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

import '../providers/providers.dart';
import '../services/streak_card_exporter.dart';
import '../widgets/streak_card.dart';

/// Captures a hidden [StreakCard], previews it, then shares the PNG.
class ShareExportScreen extends ConsumerStatefulWidget {
  const ShareExportScreen({super.key});

  @override
  ConsumerState<ShareExportScreen> createState() => _ShareExportScreenState();
}

class _ShareExportScreenState extends ConsumerState<ShareExportScreen> {
  late final StreakCardExporter _exporter;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _exporter = StreakCardExporter();
  }

  Future<void> _prepareAndPreview() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Brief delay so the off-screen card can paint before capture.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      final bytes = await _exporter.capturePng(pixelRatio: 1);
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture streak card')),
        );
        return;
      }

      final streak = ref.read(perfectDayStreakProvider).currentStreak;
      final shouldShare = await showDialog<bool>(
        context: context,
        builder: (ctx) => _PreviewDialog(imageBytes: bytes, streakDays: streak),
      );

      if (shouldShare != true || !mounted) return;

      final file = await _exporter.writeTempPng(bytes);
      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? const Rect.fromLTWH(0, 0, 1, 1)
          : box.localToGlobal(Offset.zero) & box.size;

      await _exporter.shareCardFile(
        file,
        caption: '$streak day streak of daily good deeds 🌙',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(perfectDayStreakProvider).currentStreak;
    final due = ref.watch(dueTodayProvider);
    final logs = ref.watch(todayLogsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Off-screen but still painted — required for capture()/toImage.
          // (Offstage and Opacity(0) skip painting and break Screenshot.)
          Positioned(
            left: -StreakCard.size - 64,
            top: 0,
            width: StreakCard.size,
            height: StreakCard.size,
            child: Screenshot(
              controller: _exporter.controller,
              child: StreakCard(
                streakDays: streak,
                date: todayDate(),
                dueHabits: due,
                todayLogs: logs,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share your streak',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We’ll create a square card with today’s perfect-day streak '
                  'and which habits you completed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: IgnorePointer(
                          child: StreakCard(
                            streakDays: streak,
                            date: todayDate(),
                            dueHabits: due,
                            todayLogs: logs,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _prepareAndPreview,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_busy ? 'Preparing…' : 'Preview & share'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({
    required this.imageBytes,
    required this.streakDays,
  });

  final Uint8List imageBytes;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preview streak card'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Looks good? Share “$streakDays day streak of daily good deeds 🌙”.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Share'),
        ),
      ],
    );
  }
}
