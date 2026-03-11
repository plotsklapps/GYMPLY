import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals/signals_flutter.dart';

class BackupService {
  // Singleton pattern.
  factory BackupService() {
    return _instance;
  }

  BackupService._internal();
  static final BackupService _instance = BackupService._internal();

  final Logger _logger = Logger();

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

  // Helper: Generate the ZIP bytes of all Hive data.
  Future<Uint8List?> _generateZIPBackup() async {
    try {
      // Get the directory where Hive stores its boxes.
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String hivePath = appDocDir.path;

      // Close all open Hive boxes to ensure data consistency.
      await Hive.close();

      // Log status.
      _logger.i('BackupService: Closed all Hive boxes. Hivepath: $hivePath');

      // Create ZIP archive (archive package).
      final Archive archive = Archive();
      final Directory hiveDir = Directory(hivePath);
      final List<FileSystemEntity> files = hiveDir.listSync();

      for (final FileSystemEntity file in files) {
        if (file is File &&
            (file.path.endsWith('.hive') || file.path.endsWith('.lock'))) {
          final String filename = file.path.split(Platform.pathSeparator).last;
          final Uint8List bytes = await file.readAsBytes();
          archive.addFile(ArchiveFile(filename, bytes.length, bytes));
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

  // Create LOCAL backup.
  Future<void> backupToLocal() async {
    sIsBackingUp.value = true;
    sProgress.value = 0;

    try {
      // Log status.
      _logger.i('BackupService: Starting local backup...');

      // Request Storage Permission Android versions < 30.
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 30) {
          final PermissionStatus status = await Permission.storage.request();
          if (status.isDenied) throw Exception('Storage permission denied.');
        }
      }

      final Uint8List? zipBytes = await _generateZIPBackup();
      if (zipBytes == null) throw Exception('Failed to create ZIP archive.');

      final String timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final String fileName = 'GYMPLY_$timestamp.zip';

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
        bytes: zipBytes,
      );

      if (outputFile != null) {
        // Log success.
        _logger.i('BackupService: Local backup saved to $outputFile');

        // Show toast to user.
        ToastService.showSuccess(
          title: 'Backup Successful',
          subtitle: 'Data saved to your device: $outputFile',
        );
      } else {
        // Log warning.
        _logger.w('BackupService: Local backup cancelled.');
      }
    } on Object catch (e) {
      // Log error.
      _logger.e('BackupService: Local backup failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Backup Failed', subtitle: '$e');
    } finally {
      // Refresh app.
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
      // Log status.
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
      // Log error.
      _logger.e('BackupService: Local pick failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');
      sIsRestoring.value = false;
      return null;
    }
  }

  /// Helper to apply ZIP contents to Hive.
  Future<void> applyRestore(Uint8List zipBytes) async {
    sIsRestoring.value = true;

    try {
      await Hive.close();
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String hivePath = appDocDir.path;

      // Clear existing.
      final Directory hiveDir = Directory(hivePath);
      if (hiveDir.existsSync()) {
        for (final FileSystemEntity file in hiveDir.listSync()) {
          if (file is File &&
              (file.path.endsWith('.hive') || file.path.endsWith('.lock'))) {
            await file.delete();
          }
        }
      }

      // Extract Archive.
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);
      for (final ArchiveFile file in archive) {
        if (file.isFile) {
          final List<int> data = file.content as List<int>;
          File('$hivePath${Platform.pathSeparator}${file.name}')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      // Log success.
      _logger.i('BackupService: Restore complete.');

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Restore Successful',
        subtitle: 'Your data has been restored.',
      );

      // Refresh app.
      await workoutService.init();
    } on Object catch (e) {
      // Log error.
      _logger.e('BackupService: Apply restore failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');

      // Refresh app.
      await workoutService.init();
    } finally {
      sIsRestoring.value = false;
      sProgress.value = 0;
    }
  }

  // Cancel restore if user cancels confirmation sheet.
  void cancelRestore() {
    sIsRestoring.value = false;
    sProgress.value = 0;
  }
}

// Globalize BackupService.
final BackupService backupService = BackupService();
