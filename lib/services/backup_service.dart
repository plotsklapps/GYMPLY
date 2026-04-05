import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/backup_signal.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  // Singleton pattern.
  factory BackupService() {
    return _instance;
  }

  BackupService._internal();
  static final BackupService _instance = BackupService._internal();

  final Logger _logger = Logger();
  static const String _imageSubDir = 'workout_images';

  // Generate ZIP bytes of all Hive data and images.
  Future<Uint8List?> _generateZIPBackup() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String baseDir = appDocDir.path;

      // Close all open Hive boxes to ensure data consistency.
      await Hive.close();

      final Archive archive = Archive();

      // Add Hive Files.
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

      // Add Images.
      final Directory imageDir = Directory(path.join(baseDir, _imageSubDir));
      if (imageDir.existsSync()) {
        final List<FileSystemEntity> imageFiles = imageDir.listSync();
        for (final FileSystemEntity entity in imageFiles) {
          if (entity is File) {
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
      // Log error.
      _logger.e('BackupService: ZIP generation failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'ZIP Generation Failed', subtitle: '$e');

      return null;
    }
  }

  // Create LOCAL backup and share it.
  Future<void> backupToLocal() async {
    sIsBackingUp.value = true;
    sProgress.value = 0;

    try {
      // Create ZIP bytes with _generateZIPBackup method.
      final Uint8List? zipBytes = await _generateZIPBackup();

      if (zipBytes == null) throw Exception('Failed to create ZIP archive.');

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final String fileName = 'GYMPLY_$timestamp.zip';
      final String filePath = path.join(tempDir.path, fileName);

      final File zipFile = File(filePath);

      // Create zipfile from zipbytes.
      await zipFile.writeAsBytes(zipBytes);

      // Log success.
      _logger.i(
        'BackupService: ZIP created at $filePath. Opening share sheet...',
      );

      // Open share sheet.
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(filePath)],
          subject: 'GYMPLY Backup $timestamp',
        ),
      );

      if (result.status == ShareResultStatus.success) {
        // Log success.
        _logger.i('BackupService: Local backup shared successfully.');

        // Show toast to user.
        ToastService.showSuccess(
          title: 'Backup Exported',
          subtitle: 'Your backup was successfully shared/saved.',
        );
      } else {
        // Log warning.
        _logger.w('BackupService: Sharing was cancelled or failed.');
      }

      // Safeguard to only delete if zipfile exists.
      if (zipFile.existsSync()) {
        await zipFile.delete();
        _logger.d('BackupService: Temporary backup file deleted.');
      }
    } on Object catch (e) {
      // Log error.
      _logger.e('BackupService: Local backup failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Backup Failed', subtitle: '$e');
    } finally {
      // Create fresh workoutService.
      await workoutService.init();

      // Reset Signals.
      sIsBackingUp.value = false;
      sProgress.value = 0;
    }
  }

  // Generate ZIP bytes from local file.
  Future<Uint8List?> pickLocalBackup() async {
    sIsRestoring.value = true;
    sProgress.value = 0;

    try {
      // Restrict picking ONLY ZIP files.
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
        withData: true,
      );

      if (result == null) {
        sIsRestoring.value = false;
        return null;
      }

      // Read ZIP file into bytes.
      if (result.files.single.bytes != null) {
        return result.files.single.bytes;
      } else if (result.files.single.path != null) {
        return await File(result.files.single.path!).readAsBytes();
      }

      // Reset Signal.
      sIsRestoring.value = false;

      return null;
    } on Object catch (e) {
      // Log error.
      _logger.e('BackupService: Local pick failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');

      // Reset Signal.
      sIsRestoring.value = false;

      return null;
    }
  }

  // Restore Hive backup data to device.
  Future<void> applyRestore(Uint8List zipBytes) async {
    sIsRestoring.value = true;

    try {
      // Close all open Hive boxes to ensure data consistency.
      await Hive.close();

      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String baseDir = appDocDir.path;

      // Clear existing Hive boxes.
      final Directory hiveDir = Directory(baseDir);
      if (hiveDir.existsSync()) {
        for (final FileSystemEntity file in hiveDir.listSync()) {
          if (file is File &&
              (file.path.endsWith('.hive') || file.path.endsWith('.lock'))) {
            await file.delete();
          }
        }
      }

      // Clear existing image directory.
      final Directory imageDir = Directory(path.join(baseDir, _imageSubDir));
      if (imageDir.existsSync()) {
        await imageDir.delete(recursive: true);
      }

      // Extract Archive.
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      for (final ArchiveFile file in archive) {
        if (file.isFile) {
          final List<int> data = file.content as List<int>;
          final String outPath = path.join(baseDir, file.name);
          File(outPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      // Log success.
      _logger.i('BackupService: Restore complete.');

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Restore Successful',
        subtitle: 'Your data and images have been restored.',
      );

      // Refresh WorkoutService.
      await workoutService.init();
    } on Object catch (e) {
      // Log error.
      _logger.e('BackupService: Apply restore failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');

      // Refresh WorkoutService.
      await workoutService.init();
    } finally {
      // Reset Signals.
      sIsRestoring.value = false;
      sProgress.value = 0;
    }
  }

  void cancelRestore() {
    sIsRestoring.value = false;
    sProgress.value = 0;
  }
}

// Globalize BackupService.
final BackupService backupService = BackupService();
