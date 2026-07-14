import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

/// Captures bytes, writes a temp PNG, and opens the system share sheet.
class StreakCardExporter {
  StreakCardExporter({ScreenshotController? controller})
      : controller = controller ?? ScreenshotController();

  final ScreenshotController controller;

  Future<Uint8List?> capturePng({double pixelRatio = 1}) {
    return controller.capture(pixelRatio: pixelRatio);
  }

  Future<File> writeTempPng(Uint8List bytes, {String? fileName}) async {
    final dir = await getTemporaryDirectory();
    final name = fileName ??
        'habit_streak_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<ShareResult> shareCardFile(
    File file, {
    required String caption,
    Rect? sharePositionOrigin,
  }) {
    // ignore: deprecated_member_use — shareXFiles is the requested API
    return Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: caption,
      subject: 'Habit streak',
      sharePositionOrigin:
          sharePositionOrigin ?? const Rect.fromLTWH(0, 0, 1, 1),
    );
  }
}
