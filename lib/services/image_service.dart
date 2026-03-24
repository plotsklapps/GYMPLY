import 'dart:io';

import 'package:gymply/services/toast_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageService {
  // Singleton pattern.
  factory ImageService() {
    return _instance;
  }

  ImageService._internal();
  static final ImageService _instance = ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  static const String _imageSubDir = 'workout_images';
  final Logger _logger = Logger();

  // Get directory where workout images are stored.
  Future<Directory> get _imageDirectory async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory imageDir = Directory(path.join(appDir.path, _imageSubDir));
    if (!imageDir.existsSync()) {
      imageDir.createSync(recursive: true);
    }
    return imageDir;
  }

  // Convert relative path (filename) to absolute path for display.
  Future<String> getAbsolutePath(String relativePath) async {
    final Directory dir = await _imageDirectory;
    return path.join(dir.path, relativePath);
  }

  // Pick image and save, return only relative filename.
  Future<String?> pickAndSaveImage(ImageSource source) async {
    try {
      // Create a 300kB version of a possibly 10MB image.
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final Directory imageDir = await _imageDirectory;

      // Store filename to make it portable across devices/installs.
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}'
          '${path.extension(image.path)}';
      final String permanentPath = path.join(imageDir.path, fileName);

      await File(image.path).copy(permanentPath);

      // Log success.
      _logger.i('Image saved to $permanentPath');

      return fileName;
    } on Object catch (e) {
      // Log error.
      _logger.e('Error picking or saving image: $e');

      // Show toast to user.
      ToastService.showError(title: 'Image Saving Error', subtitle: '$e');

      return null;
    }
  }
}

// Globalize ImageService.
final ImageService imageService = ImageService();
