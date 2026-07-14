import 'package:flutter/material.dart';

/// Placeholder until share/export (Step 12) is implemented.
class ShareExportScreen extends StatelessWidget {
  const ShareExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Share your progress card — coming in Step 12.',
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
