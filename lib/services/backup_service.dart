import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gymply/services/googledrive_service.dart';
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
  final Signal<bool> sIsProcessing = Signal<bool>(
    false,
    debugLabel: 'sIsProcessing',
  );
  final Signal<double> sProgress = Signal<double>(0, debugLabel: 'sProgress');

  // Helper: Generate the ZIP bytes of all Hive data.
  Future<Uint8List?> _generateBackupBytes() async {
    try {
      // Get the directory where Hive stores its boxes.
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String hivePath = appDocDir.path;

      // Close all open Hive boxes to ensure data consistency.
      await Hive.close();
      _logger.d('BackupService: Closed all Hive boxes.');

      // Create the ZIP archive.
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
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: ZIP generation failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'ZIP Generation Failed', subtitle: '$e');
      return null;
    }
  }

  // Create backup and save it LOCALLY.
  Future<void> backupToLocal(BuildContext context) async {
    sIsProcessing.value = true;
    sProgress.value = 0;

    try {
      // Log status.
      _logger.i('BackupService: Starting local backup...');

      // Request Storage Permission ONLY for older Android versions (API < 30).
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 30) {
          final PermissionStatus status = await Permission.storage.request();
          if (status.isDenied) throw Exception('Storage permission denied.');
        }
      }

      final Uint8List? zipBytes = await _generateBackupBytes();
      if (zipBytes == null) throw Exception('Failed to create ZIP archive.');

      final String timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final String fileName = 'gymply_$timestamp.zip';

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
          subtitle: 'Data saved to your device',
        );
      } else {
        // Log warning.
        _logger.w('BackupService: Local backup cancelled.');
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: Local backup failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Backup Failed', subtitle: '$e');
    } finally {
      // Refresh app.
      await workoutService.init();
      sIsProcessing.value = false;
      sProgress.value = 0;
    }
  }

  // Create backup and sync it to GOOGLE DRIVE.
  Future<void> backupToCloud(BuildContext context) async {
    sIsProcessing.value = true;
    sProgress.value = 0;

    try {
      // Log status.
      _logger.i('BackupService: Starting cloud backup...');

      final Uint8List? zipBytes = await _generateBackupBytes();
      if (zipBytes == null) throw Exception('Failed to create ZIP archive.');

      // Use fixed name for the cloud backup to make syncing easier.
      const String fileName = 'GYMPLY_cloud_backup.zip';

      final bool success = await googleDriveService.uploadBackup(
        zipBytes,
        fileName,
        onProgress: (double p) => sProgress.value = p,
      );

      if (success) {
        // Log success.
        _logger.i('GoogleDriveService: Backup successfully synced to Cloud.');

        // Show toast to user.
        ToastService.showSuccess(
          title: 'Cloud Sync Successful',
          subtitle: 'Data backed up to Google Drive',
        );
      } else {
        // Log warning.
        _logger.w('GoogleDriveService: Backup failed to sync to Cloud.');

        // Show toast to user.
        ToastService.showWarning(
          title: 'Sync Failed',
          subtitle:
              'Could not '
              'connect to Google Drive',
        );

        throw Exception('Could not connect to Google Drive.');
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: Cloud backup failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Sync Failed', subtitle: '$e');
    } finally {
      // Refresh app.
      await workoutService.init();
      sIsProcessing.value = false;
      sProgress.value = 0;
    }
  }

  // Restore backup from a LOCAL file.
  Future<void> restoreFromLocal(BuildContext context) async {
    sIsProcessing.value = true;
    sProgress.value = 0;

    try {
      // Log status.
      _logger.i('BackupService: Restoring from local file...');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
      );

      if (result == null || result.files.single.path == null) return;

      final Uint8List bytes = await File(
        result.files.single.path!,
      ).readAsBytes();

      if (context.mounted) {
        await _applyRestore(context, bytes);
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: Local restore failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');

      // Refresh app.
      await workoutService.init();
    } finally {
      sIsProcessing.value = false;
      sProgress.value = 0;
    }
  }

  // Restore backup from Google Drive.
  Future<void> restoreFromCloud(BuildContext context) async {
    sIsProcessing.value = true;
    sProgress.value = 0;

    try {
      // Log status.
      _logger.i('BackupService: Restoring from Google Drive...');

      const String fileName = 'gymply_cloud_backup.zip';
      final List<int>? zipBytes = await googleDriveService.downloadBackup(
        fileName,
        onProgress: (double p) => sProgress.value = p,
      );

      if (zipBytes == null) {
        throw Exception('No backup found on Google Drive.');
      }

      if (context.mounted) {
        await _applyRestore(context, Uint8List.fromList(zipBytes));
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: Cloud restore failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');

      // Refresh app.
      await workoutService.init();
    } finally {
      sIsProcessing.value = false;
      sProgress.value = 0;
    }
  }

  /// Shared helper to apply the ZIP contents to Hive.
  Future<void> _applyRestore(BuildContext context, Uint8List zipBytes) async {
    // Confirm restore.
    final bool? confirm = await showModalBottomSheet<bool>(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: _buildRestoreConfirm,
    );

    if (confirm != true) return;

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

    // Extract.
    final Archive archive = ZipDecoder().decodeBytes(zipBytes);
    for (final ArchiveFile file in archive) {
      if (file.isFile) {
        final List<int> data = file.content as List<int>;
        File('$hivePath${Platform.pathSeparator}${file.name}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      }
    }

    _logger.i('BackupService: Restore complete.');
    await workoutService.init();
    ToastService.showSuccess(
      title: 'Restore Successful',
      subtitle: 'Your data has been restored.',
    );
  }

  Widget _buildRestoreConfirm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Restore Backup'),
          const Divider(),
          const Text(
            'This will overwrite all current data. This action '
            'cannot be undone.',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('RESTORE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final BackupService backupService = BackupService();
