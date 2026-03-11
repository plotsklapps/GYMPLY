import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupService {
  // Singleton pattern.
  factory BackupService() {
    return _instance;
  }

  BackupService._internal();
  static final BackupService _instance = BackupService._internal();

  final Logger _logger = Logger();

  // Create a backup of all Hive data.
  Future<void> backupData(BuildContext context) async {
    try {
      _logger.i('BackupService: Starting backup...');

      // Request Storage Permission ONLY for older Android versions (API < 30).
      // On Android 11+ (API 30+), the FilePicker handles permissions implicitly.
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt < 30) {
          final PermissionStatus status = await Permission.storage.request();
          if (status.isDenied) {
            throw Exception('Storage permission denied.');
          }
        }
      }

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
      final List<int>? zipBytes = zipEncoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('Failed to create ZIP archive.');
      }

      // Let user choose where to save file.
      final String timestamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final String fileName = 'gymply_$timestamp.zip';

      // On Android/iOS, 'bytes' are required for saveFile to work.
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
        bytes: Uint8List.fromList(zipBytes),
      );

      if (outputFile != null) {
        // Log success.
        _logger.i('BackupService: Backup saved to $outputFile');

        // Show toast to user.
        ToastService.showSuccess(
          title: 'Backup Successful',
          subtitle: 'Data saved to $fileName',
        );
      } else {
        // Log warning.
        _logger.w('BackupService: Backup cancelled by user.');

        // Show toast to user.
        ToastService.showWarning(
          title: 'Backup Cancelled',
          subtitle: 'No new backup was created',
        );
      }

      // Re-initialize WorkoutService to reopen boxes and resume app state.
      await workoutService.init();
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: Backup failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Backup Failed', subtitle: '$e');

      // Attempt to reopen boxes even if backup failed.
      await workoutService.init();
    }
  }

  // Restore Hive data from a backup ZIP.
  Future<void> restoreData(BuildContext context) async {
    try {
      // Log status.
      _logger.i('BackupService: Starting restore...');

      // Let the user pick the backup file.
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
      );

      if (result == null || result.files.single.path == null) {
        // Log warning.
        _logger.w('BackupService: Restore cancelled by user.');

        // Show toast to user.
        ToastService.showWarning(
          title: 'Restore Cancelled',
          subtitle: 'No backup file was selected',
        );

        return;
      }

      final File zipFile = File(result.files.single.path!);

      // Confirm restore.
      final bool? confirm = await showModalBottomSheet<bool>(
        showDragHandle: true,
        isScrollControlled: true,
        context: context,
        builder:
            (
              BuildContext context,
            ) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Restore Backup'),
                    const Divider(),
                    const Text(
                      'This will overwrite all current data with data from '
                      'the .zip file. This action cannot be undone.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text(
                              'RESTORE',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
      );

      if (confirm != true) return;

      // Close boxes and clear existing Hive files.
      await Hive.close();
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String hivePath = appDocDir.path;
      final Directory hiveDir = Directory(hivePath);

      if (hiveDir.existsSync()) {
        final List<FileSystemEntity> files = hiveDir.listSync();
        for (final FileSystemEntity file in files) {
          if (file is File &&
              (file.path.endsWith('.hive') || file.path.endsWith('.lock'))) {
            await file.delete();
          }
        }
      }

      // Log status.
      _logger.d('BackupService: Cleared existing Hive files.');

      // Extract ZIP to Hive directory.
      final Uint8List bytes = await zipFile.readAsBytes();
      final Archive archive = ZipDecoder().decodeBytes(bytes);

      for (final ArchiveFile file in archive) {
        final String filename = file.name;
        if (file.isFile) {
          final List<int> data = file.content as List<int>;
          File('$hivePath${Platform.pathSeparator}$filename')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        }
      }

      // Log success.
      _logger.i('BackupService: Restore complete.');

      // Re-initialize services.
      await workoutService.init();

      ToastService.showSuccess(
        title: 'Restore Successful',
        subtitle: 'Your data has been restored.',
      );
    } on Exception catch (e) {
      // Log error.
      _logger.e('BackupService: Restore failed: $e');

      // Show toast to user.
      ToastService.showError(title: 'Restore Failed', subtitle: '$e');

      // Attempt to reopen boxes.
      await workoutService.init();
    }
  }
}

// Globalize the BackupService.
final BackupService backupService = BackupService();
