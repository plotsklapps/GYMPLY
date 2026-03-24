import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  // Singleton pattern.
  factory ShareService() {
    return _instance;
  }

  ShareService._internal();
  static final ShareService _instance = ShareService._internal();

  final Logger _logger = Logger();

  // Capture widget (via GlobalKey) -> convert to PNG bytes for Nostr.
  Future<Uint8List?> captureImage(GlobalKey boundaryKey) async {
    try {
      final RenderRepaintBoundary? boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return null;

      // Convert boundary to an image (high pixel ratio for quality).
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      // Log success.
      _logger.i('Image captured successfully');

      return byteData.buffer.asUint8List();
    } on Object catch (e) {
      // Log error.
      _logger.e('Error capturing image: $e');

      // Show toast to user.
      ToastService.showError(title: 'Error Capturing Image', subtitle: '$e');

      return null;
    }
  }

  // Capture widget (via GlobalKey) -> convert to PNG -> share via OS.
  Future<void> captureAndShare(
    GlobalKey boundaryKey, {
    required String workoutTitle,
  }) async {
    try {
      final Uint8List? pngBytes = await captureImage(boundaryKey);
      if (pngBytes == null) return;

      // Save to a temporary directory.
      final Directory directory = await getTemporaryDirectory();
      final String fileName =
          'GYMPLY_${DateTime.now().millisecondsSinceEpoch}.png';
      final String imagePath = '${directory.path}/$fileName';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Share file using share_plus package.
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(imagePath)],
          subject: 'My Workout: $workoutTitle',
        ),
      );

      // Log success.
      _logger.i('Workout shared successfully');
    } on Object catch (e) {
      // Log error.
      _logger.e('Error sharing workout: $e');

      // Show toast to user.
      ToastService.showError(title: 'Error Sharing Workout', subtitle: '$e');
    }
  }
}

// Globalize ShareService.
final ShareService shareService = ShareService();
