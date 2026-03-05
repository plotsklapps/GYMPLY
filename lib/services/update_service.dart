import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals_flutter.dart';

class UpdateService {
  // Singleton pattern.
  factory UpdateService() => _instance;
  UpdateService._internal();
  static final UpdateService _instance = UpdateService._internal();

  final Logger _logger = Logger();
  final Dio _dio = Dio();

  // Signals for tracking update state.
  final Signal<bool> sIsCheckingForUpdate = signal(false);
  final Signal<double> sDownloadProgress = signal(0);
  final Signal<String?> sUpdateError = signal(null);

  // URL pointing to your GitHub version metadata.
  // Replace this with your actual raw GitHub URL.
  static const String _versionUrl =
      'https://raw.githubusercontent.com/jhuch/gymply/main/version.json';

  /// Checks for updates and returns true if a new version is available.
  Future<void> checkForUpdates() async {
    sIsCheckingForUpdate.value = true;
    sUpdateError.value = null;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      _logger.i('Current Version: $currentVersion ($currentBuildNumber)');

      // Fetch metadata from GitHub.
      final Response response = await _dio.get(_versionUrl);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;

        final String latestVersion = data['version_name'] as String;
        final int latestBuildNumber = data['version_code'] as int;
        final String downloadUrl = data['download_url'] as String;

        _logger.i(
          'Latest Version available: $latestVersion ($latestBuildNumber)',
        );

        if (latestBuildNumber > currentBuildNumber) {
          _logger.i('New version found. Starting download...');
          await _downloadAndInstall(downloadUrl);
        } else {
          _logger.i('App is already up to date.');
        }
      }
    } catch (e) {
      _logger.e('Failed to check for updates: $e');
      sUpdateError.value = 'Update check failed. Check your connection.';
    } finally {
      sIsCheckingForUpdate.value = false;
    }
  }

  Future<void> _downloadAndInstall(String url) async {
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
          }
        },
      );

      _logger.i('Download complete. Opening APK: $filePath');

      // Clear progress.
      sDownloadProgress.value = 0;

      // Use OpenFilex to trigger the Android package installer.
      final OpenResult result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        _logger.e('Failed to open APK: ${result.message}');
        sUpdateError.value = 'Could not open installer: ${result.message}';
      }
    } catch (e) {
      _logger.e('Download error: $e');
      sUpdateError.value = 'Failed to download update.';
    }
  }
}
