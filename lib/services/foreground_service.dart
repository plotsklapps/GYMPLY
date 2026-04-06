import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

// Timer type string constants — shared between both isolates.
const String kTimerTypeRest = 'rest';
const String kTimerTypeInterval = 'interval';
const String kTimerTypeStopwatch = 'stopwatch';
const String kTimerTypeTotal = 'total';

// Unique service ID for GYMPLY's foreground service.
const int kGymplyServiceId = 901;

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
  String _timerType = kTimerTypeTotal;
  int _endTimeMs = 0; // Epoch ms when countdown ends.
  int _virtualStartMs = 0; // Epoch ms representing "time zero" for count-up.

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Read the timer state that ForegroundService wrote before starting.
    _timerType =
        await FlutterForegroundTask.getData<String>(key: 'timerType') ??
        kTimerTypeTotal;
    _endTimeMs =
        await FlutterForegroundTask.getData<int>(key: 'endTimeMs') ?? 0;
    _virtualStartMs =
        await FlutterForegroundTask.getData<int>(key: 'virtualStartMs') ?? 0;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Rebuild the notification text on every tick.
    unawaited(
      FlutterForegroundTask.updateService(
        notificationText: _buildNotificationText(timestamp),
      ),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Nothing to clean up in this handler.
  }

  @override
  void onReceiveData(Object data) {
    // Main isolate sends a 'start' message when the timer type or end time
    // changes (e.g. interval → rest transition during auto-interval).
    if (data is! Map<String, dynamic>) return;
    if (data['action'] != 'start') return;

    _timerType = data['timerType'] as String? ?? kTimerTypeTotal;
    _endTimeMs = data['endTimeMs'] as int? ?? 0;
    _virtualStartMs = data['virtualStartMs'] as int? ?? 0;
  }

  // Builds the notification body text based on active timer type.
  String _buildNotificationText(DateTime now) {
    if (_timerType == kTimerTypeStopwatch || _timerType == kTimerTypeTotal) {
      final int elapsedMs = now.millisecondsSinceEpoch - _virtualStartMs;
      return _formatElapsedTime(elapsedMs < 0 ? 0 : elapsedMs);
    }
    final int remainingMs = _endTimeMs - now.millisecondsSinceEpoch;
    return _formatCountdownTime(remainingMs < 0 ? 0 : remainingMs);
  }

  // Format using intl for consistency.
  // Stopwatch/Total: H:mm:ss
  String _formatElapsedTime(int ms) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    // User requested H:MM:SS for Total/Interval.
    // For Stopwatch, they asked for H:MM:SS:MS, but we'll stick to 1s ticks.
    if (ms >= 3600000) {
      return DateFormat('H:mm:ss').format(date);
    }
    return DateFormat('mm:ss').format(date);
  }

  // Countdown Format.
  // Interval: H:mm:ss, Rest: mm:ss
  String _formatCountdownTime(int ms) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    if (_timerType == kTimerTypeRest) {
      return DateFormat('mm:ss').format(date);
    }
    if (ms >= 3600000) {
      return DateFormat('H:mm:ss').format(date);
    }
    return DateFormat('mm:ss').format(date);
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

  // Starts the service in "Total Workout Timer" mode.
  Future<void> startTotalTimerService({required int virtualStartMs}) async {
    await _startOrUpdateService(
      timerType: kTimerTypeTotal,
      virtualStartMs: virtualStartMs,
    );
  }

  // Starts the service for a countdown timer (Rest/Interval).
  Future<void> startCountdownService({
    required String timerType,
    required int endTimeMs,
  }) async {
    await _startOrUpdateService(
      timerType: timerType,
      endTimeMs: endTimeMs,
    );
  }

  // Starts the service for the stopwatch.
  Future<void> startStopwatchService({required int virtualStartMs}) async {
    await _startOrUpdateService(
      timerType: kTimerTypeStopwatch,
      virtualStartMs: virtualStartMs,
    );
  }

  // Internal helper to manage the service transitions.
  Future<void> _startOrUpdateService({
    required String timerType,
    int endTimeMs = 0,
    int virtualStartMs = 0,
  }) async {
    try {
      const String title = 'GYMPLY:';
      final String body = _formatInitialDisplay(
        timerType,
        endTimeMs,
        virtualStartMs,
      );

      // Persist state for the task isolate.
      await FlutterForegroundTask.saveData(key: 'timerType', value: timerType);
      await FlutterForegroundTask.saveData(key: 'endTimeMs', value: endTimeMs);
      await FlutterForegroundTask.saveData(
        key: 'virtualStartMs',
        value: virtualStartMs,
      );

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: body,
        );
        // Communicate with the running TaskHandler isolate.
        FlutterForegroundTask.sendDataToTask(<String, dynamic>{
          'action': 'start',
          'timerType': timerType,
          'endTimeMs': endTimeMs,
          'virtualStartMs': virtualStartMs,
        });
      } else {
        await FlutterForegroundTask.startService(
          serviceId: kGymplyServiceId,
          notificationTitle: title,
          notificationText: body,
          callback: gymplyTaskCallback,
        );
      }
      _logger.i('ForegroundService: Service running [$timerType].');
    } catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to start/update service',
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

  // Formats the initial display for the notification before the TaskHandler ticks.
  String _formatInitialDisplay(String type, int end, int start) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (type == kTimerTypeStopwatch || type == kTimerTypeTotal) {
      final int elapsed = now - start;
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(
        elapsed < 0 ? 0 : elapsed,
        isUtc: true,
      );
      if (elapsed >= 3600000) return DateFormat('H:mm:ss').format(date);
      return DateFormat('mm:ss').format(date);
    }
    final int remaining = end - now;
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(
      remaining < 0 ? 0 : remaining,
      isUtc: true,
    );
    if (type == kTimerTypeRest) return DateFormat('mm:ss').format(date);
    if (remaining >= 3600000) return DateFormat('H:mm:ss').format(date);
    return DateFormat('mm:ss').format(date);
  }
}

final ForegroundService foregroundService = ForegroundService();
