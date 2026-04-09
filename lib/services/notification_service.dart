import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/notification_handler.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

class NotificationService {
  // Singleton pattern.
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;

  // Unique service ID for foreground service.
  static const int _serviceId = 901;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Relying on flutter_foreground_task package.
      FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'gymply_timer_channel',
          channelName: 'GYMPLY Timer',
          channelDescription: 'Shows the live timer status.',
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(1000),
        ),
      );
      _isInitialized = true;
      _setupTimerEffect();

      // Log success.
      _logger.i('NotificationService: Initialized successfully.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e(
        'NotificationService: Failed to initialize',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> updateNotificationDisplay({
    required String totalTime,
    String? segmentLabel,
    String? segmentTime,
  }) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        // Send separate fields to the background task isolate.
        // We only send keys that are present to allow the handler to be stateful.
        final Map<String, dynamic> data = <String, dynamic>{
          'total': totalTime,
        };

        if (segmentLabel != null) {
          data['segmentLabel'] = segmentLabel;
          data['segmentTime'] = segmentTime ?? '';
        }

        FlutterForegroundTask.sendDataToTask(data);
      }
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to update',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Centralized effect that watches all timer signals and syncs the notification.
  void _setupTimerEffect() {
    effect(() async {
      final bool isTotalRunning = TotalTimer.sTotalTimerRunning.value;
      final int totalSeconds = TotalTimer.sElapsedTotalTime.value;

      final bool isIntervalRunning = IntervalTimer.sIntervalTimerRunning.value;
      final int intervalMs = IntervalTimer.sElapsedIntervalTime.value;

      final bool isRestRunning = RestTimer.sRestTimerRunning.value;
      final int restSeconds = RestTimer.sElapsedRestTime.value;

      final bool isStopwatchRunning = StopwatchTimer.sStopwatchTimerRunning.value;
      final int stopwatchMs = StopwatchTimer.sElapsedStopwatchTime.value;

      // 1. Manage Service Lifecycle based on TotalTimer
      if (isTotalRunning) {
        if (!await FlutterForegroundTask.isRunningService) {
          await startService();
        }
      } else {
        if (await FlutterForegroundTask.isRunningService) {
          await stopService();
        }
        return; // No need to update if service is stopping
      }

      // 2. Determine active segment (Priority: Interval > Rest > Stopwatch)
      String? label;
      String? timeStr;

      if (isIntervalRunning) {
        label = 'INTERVAL';
        timeStr = (intervalMs ~/ 1000).formatHMMSS();
      } else if (isRestRunning) {
        label = 'REST';
        timeStr = restSeconds.formatMSS();
      } else if (isStopwatchRunning) {
        label = 'STOPWATCH';
        timeStr = (stopwatchMs ~/ 1000).formatHMMSS();
      } else {
        // Explicitly clear segment if none are running
        label = '';
        timeStr = '';
      }

      // 3. Dispatch Update
      unawaited(
        updateNotificationDisplay(
          totalTime: totalSeconds.formatHMMSS(),
          segmentLabel: label,
          segmentTime: timeStr,
        ),
      );
    });
  }

  Future<void> startService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) return;

      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: const <ForegroundServiceTypes>[
          ForegroundServiceTypes.dataSync,
        ],
        notificationTitle: 'TOTAL TIME: 00:00:00',
        notificationText: '',
        callback: notificationTaskCallback,
      );
      _logger.i('NotificationService: Started.');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to start',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> stopService() async {
    try {
      await FlutterForegroundTask.stopService();
      _logger.i('NotificationService: Service stopped.');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to stop',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> requestPermissionWithModal(BuildContext context) async {
    try {
      // Check Notification permission only.
      final NotificationPermission notificationPerm =
          await FlutterForegroundTask.checkNotificationPermission();

      // If already granted, we can skip the modal.
      if (notificationPerm == NotificationPermission.granted) {
        if (Platform.isAndroid) await _requestBatteryOptimization();
        return;
      }

      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      final String? hasShown = await secureStorage.read(
        key: 'hasShownTimerPermissionModal',
      );
      if (hasShown == 'true') return;

      await secureStorage.write(
        key: 'hasShownTimerPermissionModal',
        value: 'true',
      );

      if (!context.mounted) return;
      await ModalService.showModal(
        context: context,
        child: const PermissionModal(),
      );
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Permission request failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static Future<void> requestBatteryOptimization() async {
    return _requestBatteryOptimization();
  }

  static Future<void> _requestBatteryOptimization() async {
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  void _onReceiveTaskData(Object data) {}
}

final NotificationService notificationService = NotificationService();
