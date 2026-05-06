import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/models/settings_model.dart';
import 'package:gymply/services/hive_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/signals/appicon_signal.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:gymply/signals/exercisesgridmode_signal.dart';
import 'package:gymply/signals/favoriteexercises_signal.dart';
import 'package:gymply/signals/onboarding_signal.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Central provider for user preferences and UI configuration. It knows how
// settings behave.
//
// init() / loadSettings(): Read Settings model from Hive and push values
//                          into global Signals on app startup.

class SettingsService {
  // Singleton pattern.
  factory SettingsService() {
    return _instance;
  }

  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();
  final Logger _logger = Logger();

  // MethodChannel for native communication.
  static const MethodChannel _iconChannel = MethodChannel(
    'dev.plotsklapps.gymply/app_icon',
  );

  // Reference to settings box from HiveService.
  late final Box<Settings> _settingsBox;

  // Initialize SettingsService.
  void init() {
    _settingsBox = hiveService.settingsBox;
    loadSettings();
    _logger.i('SettingsService: Initialized');
  }

  // Load settings from Hive into signals.
  void loadSettings() {
    Settings? settings = _settingsBox.get('settings');

    // Make sure we have a default for new users.
    if (settings == null) {
      settings = Settings();
      unawaited(_settingsBox.put('settings', settings));
      _logger.i('SettingsService: Created default settings');
    }

    // Auto-complete onboarding for existing users upgrading to this version.
    if (!settings.onboardingCompleted && hiveService.workoutBox.isNotEmpty) {
      settings = settings.copyWith(onboardingCompleted: true);
      unawaited(_settingsBox.put('settings', settings));
      _logger.i('SettingsService: Auto-completed onboarding for existing user');
    }

    sDarkMode.value = settings.darkMode;
    RestTimer.sInitialRestTime.value = settings.initialRestTime;
    RestTimer.sElapsedRestTime.value = settings.initialRestTime;
    sFavoriteExercises.value = List<int>.from(settings.favoriteExercises);
    sWakelock.value = settings.isWakelock;
    sFlexScheme.value = settings.flexScheme;
    sFont.value = settings.fontFamily;
    sAge.value = settings.age;
    sHeight.value = settings.height;
    sWeight.value = settings.weight;
    sSex.value = settings.sex;
    sSomatotype.value = settings.somatotypeIndex;
    sOnboardingCompleted.value = settings.onboardingCompleted;
    sExercisesGridMode.value = settings.isExercisesGridMode;
    sAppIcon.value = settings.appIcon;
    _logger.i('SettingsService: Settings loaded');
  }

  // Mark onboarding as completed.
  Future<void> completeOnboarding() async {
    try {
      sOnboardingCompleted.value = true;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(onboardingCompleted: true),
        );
      }

      _logger.i('SettingsService: Onboarding completed');
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to complete onboarding',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Toggle ThemeMode.
  Future<void> toggleThemeMode({required bool value}) async {
    try {
      sDarkMode.value = value;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put('settings', settings.copyWith(darkMode: value));
      }

      _logger.i('SettingsService: DarkMode toggled to $value');
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to toggle DarkMode',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update dark mode.',
      );
    }
  }

  // Toggle Wakelock.
  Future<void> toggleWakelock({required bool value}) async {
    try {
      sWakelock.value = value;
      await WakelockPlus.toggle(enable: value);

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(isWakelock: value),
        );
      }

      _logger.i('SettingsService: Wakelock toggled to $value');
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to toggle Wakelock',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update wakelock.',
      );
    }
  }

  // Toggle ExerciseViewMode.
  Future<void> toggleExerciseViewMode() async {
    try {
      sExercisesGridMode.value = !sExercisesGridMode.value;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(isExercisesGridMode: sExercisesGridMode.value),
        );
      }

      _logger.i(
        'SettingsService: ExerciseGridMode toggled to '
        '${sExercisesGridMode.value}',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to toggle ExerciseGridMode',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update settings.',
      );
    }
  }

  // Toggle favorite exercise by id.
  Future<void> toggleFavorite(int exerciseId) async {
    try {
      final List<int> currentFavorites = List<int>.from(
        sFavoriteExercises.value,
      );

      if (currentFavorites.contains(exerciseId)) {
        currentFavorites.remove(exerciseId);
        _logger.i('SettingsService: Removed $exerciseId from favorites');
      } else {
        currentFavorites.add(exerciseId);
        _logger.i('SettingsService: Added $exerciseId from favorites');
      }

      sFavoriteExercises.value = currentFavorites;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(favoriteExercises: currentFavorites),
        );
      }
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to toggle favorite',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update favorites.',
      );
    }
  }

  // Update FlexScheme.
  Future<void> updateFlexScheme(FlexSchemes scheme) async {
    try {
      sFlexScheme.value = scheme;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(flexScheme: scheme),
        );
      }

      _logger.i('SettingsService: FlexScheme updated to ${scheme.name}');
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to update FlexScheme',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update theme color.',
      );
    }
  }

  // Update Font.
  Future<void> updateFont(String font) async {
    try {
      sFont.value = font;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put('settings', settings.copyWith(fontFamily: font));
      }

      _logger.i('SettingsService: Font updated to $font');
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to update Font',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update font.',
      );
    }
  }

  // Update App Icon.
  Future<void> updateAppIcon(String iconName) async {
    try {
      sAppIcon.value = iconName;

      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(appIcon: iconName),
        );
      }

      await _iconChannel.invokeMethod('changeIcon', <String, String>{
        'iconName': iconName,
      });
      _logger.i('SettingsService: AppIcon updated to $iconName. Exiting app.');
      
      // Force close the app to ensure the new icon applies consistently
      SystemNavigator.pop();
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to update AppIcon',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Settings Error',
        subtitle: 'Failed to update app icon.',
      );
    }
  }

  // Update Supporter Status.
  Future<void> updateIsSupporter({required bool value}) async {
    try {
      final Settings? settings = _settingsBox.get('settings');
      if (settings != null) {
        await _settingsBox.put(
          'settings',
          settings.copyWith(isSupporter: value),
        );
      }
      _logger.i('SettingsService: isSupporter updated to $value');
    } on Object catch (e, stackTrace) {
      _logger.e(
        'SettingsService: Failed to update isSupporter',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Get current Supporter Status from Hive.
  bool get isSupporter {
    return _settingsBox.get('settings')?.isSupporter ?? false;
  }
}

// Globalize SettingsService.
final SettingsService settingsService = SettingsService();
