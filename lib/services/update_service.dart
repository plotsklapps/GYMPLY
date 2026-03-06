import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

class UpdateService {
  // Singleton pattern.
  factory UpdateService() {
    return _instance;
  }
  UpdateService._internal();
  static final UpdateService _instance = UpdateService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio();

  // Signals for tracking update state.
  final Signal<bool> sIsCheckingForUpdate = signal(false);
  final Signal<double> sDownloadProgress = signal(0);
  final Signal<String?> sUpdateError = signal(null);

  // URL pointing to your GitHub version metadata.
  static const String _versionUrl =
      'https://raw.githubusercontent.com/plotsklapps/gymply/master/version.json';

  /// Checks for updates and returns true if a new version is available.
  Future<void> checkForUpdates() async {
    sIsCheckingForUpdate.value = true;
    sUpdateError.value = null;

    _logger.i('UpdateService: Starting update check...');

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersionName = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      _logger.i(
        'UpdateService: Local version: $currentVersionName ($currentBuildNumber)',
      );

      // Fetch metadata from GitHub with explicit type arguments.
      final Response<dynamic> response = await _dio.get<dynamic>(_versionUrl);

      if (response.statusCode == 200) {
        // Handle case where GitHub returns text/plain and Dio doesn't parse it automatically.
        final dynamic rawData = response.data;
        final Map<String, dynamic> data;

        if (rawData is String) {
          _logger.d('UpdateService: Parsing response as JSON string...');
          data = jsonDecode(rawData) as Map<String, dynamic>;
        } else if (rawData is Map<String, dynamic>) {
          data = rawData;
        } else {
          throw Exception('Unexpected data format: ${rawData.runtimeType}');
        }

        final String latestVersionName = data['version_name'] as String;
        final int latestBuildNumber = data['version_code'] as int;
        final String downloadUrl = data['download_url'] as String;

        _logger.i(
          'UpdateService: Remote version: $latestVersionName ($latestBuildNumber)',
        );

        if (latestBuildNumber > currentBuildNumber) {
          _logger.i('UpdateService: New version detected!');

          toastification.show(
            type: ToastificationType.info,
            title: const Text('Update Found'),
            description: Text(
              'Upgrading from $currentVersionName ($currentBuildNumber) '
              'to $latestVersionName ($latestBuildNumber). Starting download...',
            ),
            autoCloseDuration: const Duration(seconds: 5),
          );

          await _downloadAndInstall(downloadUrl);
        } else {
          _logger.i('UpdateService: App is up to date.');

          toastification.show(
            type: ToastificationType.success,
            title: const Text('Up to Date'),
            description: Text(
              'You are running the latest version: $currentVersionName ($currentBuildNumber).',
            ),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } else {
        _logger.w(
          'UpdateService: Server returned status code ${response.statusCode}',
        );
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('UpdateService: Error checking for updates: $e');
      sUpdateError.value = 'Update check failed.';

      toastification.show(
        type: ToastificationType.error,
        title: const Text('Check Failed'),
        description: Text('Error: $e'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    } finally {
      sIsCheckingForUpdate.value = false;
    }
  }

  Future<void> _downloadAndInstall(String url) async {
    _logger.i('UpdateService: Initiating download from $url');

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/gymply_update.apk';

      // Download APK with progress tracking.
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (int count, int total) {
          if (total != -1) {
            sDownloadProgress.value = count / total;
            // Log progress occasionally (every 10%) to avoid spamming.
            if ((count / total * 100).toInt() % 10 == 0) {
              _logger.d(
                'UpdateService: Download progress: ${(count / total * 100).toStringAsFixed(0)}%',
              );
            }
          }
        },
      );

      _logger.i('UpdateService: Download complete. File saved to $filePath');
      sDownloadProgress.value = 0;

      _logger.i(
        'UpdateService: Requesting Android Package Installer to open the APK...',
      );

      toastification.show(
        type: ToastificationType.success,
        title: const Text('Download Complete'),
        description: const Text('Opening the installer now...'),
        autoCloseDuration: const Duration(seconds: 3),
      );

      // Use OpenFilex to trigger the Android package installer.
      final OpenResult result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        _logger.e('UpdateService: OpenFilex failed: ${result.message}');
        throw Exception('Installer failed: ${result.message}');
      }
    } catch (e) {
      _logger.e('UpdateService: Download/Install error: $e');
      sUpdateError.value = 'Failed to download update.';

      toastification.show(
        type: ToastificationType.error,
        title: const Text('Download Failed'),
        description: const Text(
          'Could not download or install the new version.',
        ),
        autoCloseDuration: const Duration(seconds: 5),
      );
    }
  }
}
