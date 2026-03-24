import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gymply/services/toast_service.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

  // Bool Signal to track update state.
  final Signal<bool> sIsCheckingForUpdate = Signal<bool>(
    false,
    debugLabel: 'sIsCheckingForUpdate',
  );

  // URL pointing to GitHub version metadata.
  static const String _versionUrl =
      'https://raw.githubusercontent.com/plotsklapps/gymply/master/version.json';

  // URL for the Play Store page.
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=dev.plotsklapps.gymply';

  // Check for updates and handle logic based on installer source (apk or aab).
  Future<void> checkForUpdates() async {
    sIsCheckingForUpdate.value = true;

    _logger.i('UpdateService: Starting update check...');

    try {
      // Fetch version and installer information.
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersionName = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      final String installerStore = packageInfo.installerStore ?? '';

      // Log version and installer information.
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

        // Set the latest version.
        final String latestVersionName = data['version_name'] as String;
        final int latestBuildNumber = data['version_code'] as int;
        final String downloadUrl = data['download_url'] as String;

        // Log version information.
        _logger.i(
          'UpdateService: Remote version: $latestVersionName '
          '($latestBuildNumber)',
        );

        if (latestBuildNumber > currentBuildNumber) {
          // Log update found.
          _logger.i('UpdateService: New version detected!');

          final bool isPlayStore = installerStore == 'com.android.vending';

          if (isPlayStore) {
            // PLAY STORE VERSION: Just point to the store.
            _logger.i('UpdateService: Redirecting to Play Store...');

            // Show toast to user.
            ToastService.showSuccess(
              title: 'Update Available',
              subtitle: 'Opening Google Play for version $latestVersionName...',
            );

            await _launchLink(_playStoreUrl);
          } else {
            // GITHUB/APK VERSION: Open browser to the APK download.
            _logger.i('UpdateService: Redirecting to GitHub APK download...');

            // Show toast to user.
            ToastService.showSuccess(
              title: 'Update Found',
              subtitle:
                  'Opening download link for version $latestVersionName...',
            );
            await _launchLink(downloadUrl);
          }
        } else {
          // Log update not found.
          _logger.i('UpdateService: App is up to date.');

          // Show toast to user.
          ToastService.showSuccess(
            title: 'Up to Date',
            subtitle:
                'You are running the latest version: '
                '$currentVersionName+$currentBuildNumber',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on Exception catch (e) {
      // Log error.
      _logger.e('UpdateService: Error checking for updates: $e');

      // Show toast to user.
      ToastService.showError(
        title: 'Update check failed',
        subtitle: '$e',
      );
    } finally {
      sIsCheckingForUpdate.value = false;
    }
  }

  // Helper to launch URL (url_launcher package).
  Future<void> _launchLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $urlString');
    }
  }
}
