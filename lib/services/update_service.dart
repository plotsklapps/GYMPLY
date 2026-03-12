import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gymply/services/toast_service.dart';
import 'package:logger/logger.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // URL for the Play Store page.
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=dev.plotsklapps.gymply';

  // Checks for updates and handles logic based on installer source.
  Future<void> checkForUpdates() async {
    sIsCheckingForUpdate.value = true;
    sUpdateError.value = null;

    _logger.i('UpdateService: Starting update check...');

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersionName = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final String installerStore = packageInfo.installerStore ?? '';

      _logger.i(
        'UpdateService: Local version: $currentVersionName '
        '($currentBuildNumber), Installer: $installerStore',
      );

      // Fetch metadata.
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

        _logger.i(
          'UpdateService: Remote version: $latestVersionName '
          '($latestBuildNumber)',
        );

        if (latestBuildNumber > currentBuildNumber) {
          _logger.i('UpdateService: New version detected!');

          // SMART LOGIC: Check where the app was installed from.
          // common installer stores: 'com.android.vending' (Play Store),
          // 'com.google.android.packageinstaller' (Manual APK), etc.
          final bool isPlayStore = installerStore == 'com.android.vending';

          if (isPlayStore) {
            // PLAY STORE VERSION: Just point to the store.
            _logger.i('UpdateService: Redirecting to Play Store...');
            ToastService.showSuccess(
              title: 'Update Available',
              subtitle:
                  'Opening the Google Play Store for version '
                  '$latestVersionName...',
            );

            final Uri url = Uri.parse(_playStoreUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          } else {
            // GITHUB/APK VERSION: Download and install manually.
            _logger.i('UpdateService: Starting GitHub APK download...');
            ToastService.showSuccess(
              title: 'Update Found',
              subtitle: 'Downloading version $latestVersionName from GitHub...',
            );
            await _downloadAndInstall(downloadUrl);
          }
        } else {
          _logger.i('UpdateService: App is up to date.');
          ToastService.showSuccess(
            title: 'Up to Date',
            subtitle: 'You are running the latest version: $currentVersionName',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on Exception catch (e) {
      _logger.e('UpdateService: Error checking for updates: $e');
      sUpdateError.value = 'Update check failed.';
      ToastService.showError(
        title: 'Update check failed',
        subtitle: '$e',
      );
    } finally {
      sIsCheckingForUpdate.value = false;
    }
  }

  // Download and install update (only for non-Play Store installs).
  Future<void> _downloadAndInstall(String url) async {
    _logger.i('UpdateService: Initiating download from $url');

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath = '${tempDir.path}/GYMPLY-update.apk';
      final File file = File(filePath);

      final HttpClientRequest request = await _httpClient.getUrl(
        Uri.parse(url),
      );
      final HttpClientResponse response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final int totalBytes = response.contentLength;
      int receivedBytes = 0;
      final IOSink sink = file.openWrite();

      try {
        // Use await for to process the stream safely and await completion.
        await for (final List<int> chunk in response) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes != -1) {
            sDownloadProgress.value = receivedBytes / totalBytes;
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      _logger.i('UpdateService: Download complete. Requesting install...');
      sDownloadProgress.value = 0;

      final OpenResult result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Installer failed: ${result.message}');
      }
    } on Exception catch (e) {
      _logger.e('UpdateService: Download/Install error: $e');
      sUpdateError.value = 'Failed to download update.';
      ToastService.showError(
        title: 'Download Failed',
        subtitle: 'Could not download or install the new version...',
      );
    }
  }
}
