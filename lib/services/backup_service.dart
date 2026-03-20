import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:signals/signals_flutter.dart';

class BackupService {
  // Singleton pattern.
  factory BackupService() {
    return _instance;
  }

  BackupService._internal();
  static final BackupService _instance = BackupService._internal();

  final Logger _logger = Logger();
  static const String _imageSubDir = 'workout_images';

  // Signals for tracking state.
  final Signal<bool> sIsBackingUp = Signal<bool>(
    false,
    debugLabel: 'sIsBackingUp',
  );
  final Signal<bool> sIsRestoring = Signal<bool>(
    false,
    debugLabel: 'sIsRestoring',
  );
  final Signal<double> sProgress = Signal<double>(0, debugLabel: 'sProgress');

  // Helper: Generate the ZIP bytes of all Hive data and images.
  Future<Uint8List?> _generateZIPBackup() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String baseDir = appDocDir.path;

      // Close all open Hive boxes to ensure data consistency.
      await Hive.close();

      _logger.i('BackupService: Starting ZIP generation. Base: $baseDir');

      final Archive archive = Archive();

      // 1. Add Hive Files.
      final Directory hiveDir = Directory(baseDir);
      final List<FileSystemEntity> files = hiveDir.listSync();
      for (final FileSystemEntity file in files) {
        if (file is File &&
            (file.path.endsWith('.hive') || file.path.endsWith('.lock'))) {
          final String filename = path.basename(file.path);
          final Uint8List bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(filename, bytes.length, bytes));
        }
      }

      // 2. Add Images.
      final Directory imageDir = Directory(path.join(baseDir, _imageSubDir));
      if (await imageDir.exists()) {
        final List<FileSystemEntity> imageFiles = imageDir.listSync();
        for (final FileSystemEntity entity in imageFiles) {
          if (entity is File) {
            // Use forward slashes for internal ZIP paths to ensure
            // cross-platform compatibility.
            final String zipPath =
                '$_imageSubDir/${path.basename(entity.path)}';
            final Uint8List bytes = await entity.readAsBytes();
            archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
          }
        }
      }

      final ZipEncoder zipEncoder = ZipEncoder();
      final List<int> zipBytes = zipEncoder.encode(archive);

      return Uint8List.fromList(zipBytes);
    } on Object catch (e) {
      _logger.e('BackupService: ZIP generation failed: $e');
      ToastService.showError(title: 'ZIP Generation Failed', subtitle: '$e');
      return null;
    }
  }

  // Create LOCAL backup and share it.
  Future<void> backupToLocal() async {
    sIsBackingUp.value = true;
    sProgress.value = 0;

    try {
      _logger.i('BackupService: Starting local backup for sharing...');

      final Uint8List? zipBytes = await _generateZIPBackup();
      if (zipBytes == null) throw Exception('Failed to create ZIP archive.');

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final String fileName = 'GYMPLY_$timestamp.zip';
      final String filePath = path.join(tempDir.path, fileName);

      final File zipFile = File(filePath);
      await zipFile.writeAsBytes(zipBytes);

      _logger.i(
        'BackupService: ZIP created at $filePath. Opening share sheet...',
      );

      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(filePath)],
          subject: 'GYMPLY Backup $timestamp',
        ),
      );

      if (result.status == ShareResultStatus.success) {
        _logger.i('BackupService: Local backup shared successfully.');
        ToastService.showSuccess(
          title: 'Backup Exported',
          subtitle: 'Your backup was successfully shared/saved.',
        );
      } else {
        _logger.w('BackupService: Sharing was cancelled or failed.');
      }

      if (await zipFile.exists()) {
        await zipFile.delete();
        _logger.d('BackupService: Temporary backup file deleted.');
      }
    } on Object catch (e) {
      _logger.e('BackupService: Local backup failed: $e');
      ToastService.showError(title: 'Backup Failed', subtitle: '$e');
    } finally {
      await workoutService.init();
      sIsBackingUp.value = false;
      sProgress.value = 0;
    }
  }

  // Restore LOCAL backup.
  Future<Uint8List?> pickLocalBackup() async {
    sIsRestoring.value = true;
    sProgress.value = 0;

    try {
      _logger.i('BackupService: Picking local file...');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
        withData: true,
      );

      if (result == null) {
        sIsRestoring.value = false;
        return null;
      }

      if (result.files.single.bytes != null) {
        return result.files.single.bytes;
      } else if (result.files.single.path != null) {
        return await File(result.files.single.path!).readAsBytes();
      }
      sIsRestoring.value = false;

      return null;
    } on Object catch (e) {
      _logger.e('BackupService: Local pick failed: $e');
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');
      sIsRestoring.value = false;
      return null;
    }
  }

  /// Helper to apply ZIP contents to Hive and image folder.
  Future<void> applyRestore(Uint8List zipBytes) async {
    sIsRestoring.value = true;

    try {
      await Hive.close();
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String baseDir = appDocDir.path;

      // Clear existing Hive boxes and image directory.
      final Directory hiveDir = Directory(baseDir);
      if (hiveDir.existsSync()) {
        for (final FileSystemEntity file in hiveDir.listSync()) {
          if (file is File &&
              (file.path.endsWith('.hive') || file.path.endsWith('.lock'))) {
            await file.delete();
          }
        }
      }

      final Directory imageDir = Directory(path.join(baseDir, _imageSubDir));
      if (imageDir.existsSync()) {
        await imageDir.delete(recursive: true);
      }

      // Extract Archive.
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      for (final ArchiveFile file in archive) {
        if (file.isFile) {
          final List<int> data = file.content as List<int>;
          // Zip filenames use '/' as separator regardless of platform.
          // path.join will convert them to the local platform's separator.
          final String outPath = path.join(baseDir, file.name);
          File(outPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      _logger.i('BackupService: Restore complete.');
      ToastService.showSuccess(
        title: 'Restore Successful',
        subtitle: 'Your data and images have been restored.',
      );

      await workoutService.init();
    } on Object catch (e) {
      _logger.e('BackupService: Apply restore failed: $e');
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');
      await workoutService.init();
    } finally {
      sIsRestoring.value = false;
      sProgress.value = 0;
    }
  }

  void cancelRestore() {
    sIsRestoring.value = false;
    sProgress.value = 0;
  }
}

final BackupService backupService = BackupService();
