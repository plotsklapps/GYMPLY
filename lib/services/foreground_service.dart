import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:logger/logger.dart';

// ---------------------------------------------------------------------------
// Top-level entry point for the foreground service isolate.
// Must be a top-level function annotated with @pragma('vm:entry-point').
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
void gymplyTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_GymplyTaskHandler());
}

// ---------------------------------------------------------------------------
// Private TaskHandler — runs in the foreground service isolate.
// Ticks every second, reads timer state, and updates the notification text.
// ---------------------------------------------------------------------------
class _GymplyTaskHandler extends TaskHandler {
  String _totalText = '00:00:00';
  String _segmentText = 'Idle';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initial state can be empty or loaded from data if needed.
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Just refresh with the latest variables we have stored.
    // The main isolate pushes new strings to us via onReceiveData().
    unawaited(
      FlutterForegroundTask.updateService(
        notificationText: 'Total: $_totalText | $_segmentText',
      ),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map<String, dynamic>) return;
    _totalText = data['total'] as String? ?? _totalText;
    _segmentText = data['segment'] as String? ?? _segmentText;
  }
}

// ---------------------------------------------------------------------------
// ForegroundService — central provider for the Android foreground service.
// Manages service lifecycle, permission requests, and timer state handoff
// to the service isolate.
// ---------------------------------------------------------------------------
class ForegroundService {
  // Singleton pattern.
  factory ForegroundService() {
    return _instance;
  }

  ForegroundService._internal();
  static final ForegroundService _instance = ForegroundService._internal();

  // Unique service ID for GYMPLY's foreground service.
  static const int kGymplyServiceId = 901;

  final Logger _logger = Logger();
  bool _isInitialized = false;

  // Initializes the foreground service configuration and registers the
  // data callback for messages sent from the task isolate.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Register to receive data from the task isolate.
      FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

      // Configure the foreground service channel and behaviour.
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'gymply_timer_channel',
          channelName: 'GYMPLY Timer',
          channelDescription: 'Shows the live timer status in your status bar.',
          // LOW importance = silent status bar notification, no sound or pop.
          // This allows our custom app sounds to play without OS interference.
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          showWhen: false,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          // Tick once per second to update the display.
          eventAction: ForegroundTaskEventAction.repeat(1000),
          allowWakeLock: true,
        ),
      );

      _isInitialized = true;
      _logger.i('ForegroundService: Initialized successfully.');
    } catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to initialize',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Updates the workout notification display.
  Future<void> updateWorkoutDisplay({
    required String totalTime,
    required String segmentLabel,
    required String segmentTime,
  }) async {
    try {
      final String body = 'Total: $totalTime | $segmentLabel: $segmentTime';

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationText: body,
        );
        FlutterForegroundTask.sendDataToTask(<String, dynamic>{
          'total': totalTime,
          'segment': '$segmentLabel: $segmentTime',
        });
      }
    } catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to update',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Starts the service for the first time.
  Future<void> startService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) return;

      await FlutterForegroundTask.startService(
        serviceId: ForegroundService.kGymplyServiceId,
        serviceTypes: const <ForegroundServiceTypes>[
          ForegroundServiceTypes.health,
        ],
        notificationTitle: 'GYMPLY.',
        notificationText: 'Total: 00:00:00 | Ready',
        callback: gymplyTaskCallback,
      );
      _logger.i('ForegroundService: Started.');
    } catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to start',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Stops the foreground service entirely.
  Future<void> stopService() async {
    try {
      await FlutterForegroundTask.stopService();
      _logger.i('ForegroundService: Service stopped.');
    } catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to stop service',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Permission handling.
  Future<void> requestPermissionWithDialog(BuildContext context) async {
    try {
      final NotificationPermission permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission == NotificationPermission.granted) {
        if (Platform.isAndroid) {
          await _requestBatteryOptimization();
        }
        return;
      }

      // Check if we already showed the permission modal.
      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      final String? hasShown = await secureStorage.read(
        key: 'hasShownTimerPermissionModal',
      );
      if (hasShown == 'true') {
        return;
      }

      if (!context.mounted) return;

      // Mark as shown.
      await secureStorage.write(
        key: 'hasShownTimerPermissionModal',
        value: 'true',
      );

      await ModalService.showModal(
        context: context,
        child: const PermissionModal(),
      );
    } catch (e, stack) {
      _logger.e(
        'ForegroundService: Permission request failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static Future<void> requestBatteryOptimization() async {
    await _requestBatteryOptimization();
  }

  static Future<void> _requestBatteryOptimization() async {
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  void _onReceiveTaskData(Object data) {
    // Port for extension if we need to receive signals from the service isolate.
  }
}

final ForegroundService foregroundService = ForegroundService();
