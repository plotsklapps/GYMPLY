import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  final HttpClient _httpClient = HttpClient();

  // Signals for tracking update state.
  final Signal<bool> sIsCheckingForUpdate = Signal<bool>(
    false,
    debugLabel: 'sIsCheckingForUpdate',
  );
  final Signal<double> sDownloadProgress = Signal<double>(
    0,
    debugLabel: 'sDownloadProgress',
  );
  final Signal<String?> sUpdateError = Signal<String?>(
    null,
    debugLabel: 'sUpdateError',
  );

  // URL pointing to GitHub version metadata.
  static const String _versionUrl =
      'https://raw.githubusercontent.com/plotsklapps/gymply/master/version.json';

  // Checks for updates and returns true if new version is available.
  Future<void> checkForUpdates() async {
    // Set Signals.
    sIsCheckingForUpdate.value = true;
    sUpdateError.value = null;

    // Log the status.
    _logger.i('UpdateService: Starting update check...');

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersionName = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Log local version.
      _logger.i(
        'UpdateService: Local version: $currentVersionName '
        '($currentBuildNumber)',
      );

      // Fetch metadata using native HttpClient.
      final HttpClientRequest request = await _httpClient.getUrl(
        Uri.parse(_versionUrl),
      );
      final HttpClientResponse response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final String contents = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data =
            jsonDecode(contents) as Map<String, dynamic>;

        final String latestVersionName = data['version_name'] as String;
        final int latestBuildNumber = data['version_code'] as int;
        final String downloadUrl = data['download_url'] as String;

        // Log remote version.
        _logger.i(
          'UpdateService: Remote version: $latestVersionName '
          '($latestBuildNumber)',
        );

        // Compare versions.
        if (latestBuildNumber > currentBuildNumber) {
          // Log the update.
          _logger.i('UpdateService: New version detected!');

          // Show toast to user.
          toastification.show(
            type: ToastificationType.info,
            title: const Text('Update Found'),
            description: Text(
              'Upgrading from $currentVersionName ($currentBuildNumber) '
              'to $latestVersionName ($latestBuildNumber). '
              'Starting download...',
            ),
            autoCloseDuration: const Duration(seconds: 5),
          );

          await _downloadAndInstall(downloadUrl);
        } else {
          // Log no update.
          _logger.i('UpdateService: App is up to date.');

          // Show toast to user.
          toastification.show(
            type: ToastificationType.success,
            title: const Text('Up to Date'),
            description: Text(
              'You are running the latest version: $currentVersionName '
              '($currentBuildNumber).',
            ),
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      } else {
        // Log warning.
        _logger.w(
          'UpdateService: Server returned status code ${response.statusCode}',
        );
        throw Exception('Server error: ${response.statusCode}');
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('UpdateService: Error checking for updates: $e');

      // Set Signal.
      sUpdateError.value = 'Update check failed.';

      // Show toast to user.
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Check Failed'),
        description: Text('Error: $e'),
        autoCloseDuration: const Duration(seconds: 5),
      );
    } finally {
      // Set Signal.
      sIsCheckingForUpdate.value = false;
    }
  }

  // Download and install update.
  Future<void> _downloadAndInstall(String url) async {
    // Log the status.
    _logger.i('UpdateService: Initiating download from $url');

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/gymply_update.apk';
      final File file = File(filePath);

      // Download using native HttpClient.
      final HttpClientRequest request = await _httpClient.getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        // Log warning.
        _logger.w(
          'UpdateService: Server returned status code ${response.statusCode}',
        );
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final int totalBytes = response.contentLength;
      int receivedBytes = 0;

      final IOSink sink = file.openWrite();

      // Listen to response stream to track progress and save file.
      await response
          .listen(
            (List<int> chunk) {
              receivedBytes += chunk.length;
              sink.add(chunk);

              if (totalBytes != -1) {
                // Set Signal.
                sDownloadProgress.value = receivedBytes / totalBytes;

                // Log progress occasionally (every 10%) to avoid spamming.
                if ((receivedBytes / totalBytes * 100).toInt() % 10 == 0) {
                  _logger.d(
                    'UpdateService: Download progress: '
                    '${(receivedBytes / totalBytes * 100).toStringAsFixed(0)}%',
                  );
                }
              }
            },
            onDone: () async {
              await sink.flush();
              await sink.close();
            },
            onError: (Exception e) async {
              await sink.close();
              throw e;
            },
            cancelOnError: true,
          )
          .asFuture<void>();

      // Log download completion.
      _logger.i('UpdateService: Download complete. File saved to $filePath');
      sDownloadProgress.value = 0;

      // Log install status.
      _logger.i(
        'UpdateService: Requesting Android Package Installer to open '
        'the APK...',
      );

      // Show toast to user.
      toastification.show(
        type: ToastificationType.success,
        title: const Text('Download Complete'),
        description: const Text('Opening the installer now...'),
        autoCloseDuration: const Duration(seconds: 3),
      );

      // Use OpenFilex to trigger the Android package installer.
      final OpenResult result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        // Log error.
        _logger.e('UpdateService: OpenFilex failed: ${result.message}');
        throw Exception('Installer failed: ${result.message}');
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('UpdateService: Download/Install error: $e');

      // Set Signal.
      sUpdateError.value = 'Failed to download update.';

      // Show toast to user.
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
