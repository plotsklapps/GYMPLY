import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Captures a widget (via GlobalKey) and converts it to a PNG file, then shares it.
  Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    required String workoutTitle,
  }) async {
    try {
      // 1. Find the RepaintBoundary.
      final RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return;

      // 2. Convert boundary to an image (high pixel ratio for quality).
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 3. Save to a temporary directory.
      final Directory directory = await getTemporaryDirectory();
      final String fileName =
          'GYMPLY_${DateTime.now().millisecondsSinceEpoch}.png';
      final String imagePath = '${directory.path}/$fileName';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // 4. Share the file using the modern SharePlus API.
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(imagePath)],
          subject: 'My Workout: $workoutTitle',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing workout: $e');
    }
  }
}

final ShareService shareService = ShareService();
