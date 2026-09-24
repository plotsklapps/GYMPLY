import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/liveactivity_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/notification_handler.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals/signals_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService with WidgetsBindingObserver {
  // Singleton pattern.
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;

  // Unique service ID for Android foreground service.
  static const int _serviceId = 901;

  // IDs for scheduled local notification alerts.
  static const int restTimerNotificationId = 1001;
  static const int intervalTimerNotificationId = 1002;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Add lifecycle observer to resync timers when returning from other apps.
      WidgetsBinding.instance.addObserver(this);

      // Initialize timezone database for scheduled notifications.
      tz.initializeTimeZones();

      // Configure local notification plugin.
      const DarwinInitializationSettings darwinInit =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: darwinInit,
      );

      await _localNotifications.initialize(settings: initSettings);

      // Initialize Android foreground service on Android only.
      if (Platform.isAndroid) {
        FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'gymply_timer_channel',
            channelName: 'GYMPLY Timer',
            channelDescription: 'Shows the live timer status.',
          ),
          iosNotificationOptions: const IOSNotificationOptions(),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(1000),
          ),
        );
      }

      _isInitialized = true;
      _setupTimerEffect();

      _logger.i('NotificationService: Initialized successfully.');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to initialize',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _logger.i('NotificationService: App resumed, syncing active timers.');
      restTimer.syncOnResume();
      intervalTimer.syncOnResume();
    }
  }

  /// Schedules a native OS alert that plays `timerbell.wav` when the timer
  /// reaches zero, even if the app is suspended in the background or killed.
  Future<void> scheduleTimerAlert({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    if (!Platform.isIOS) return;

    try {
      if (scheduledDate.isBefore(DateTime.now())) return;

      final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
        sound: 'timerbell.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'gymply_timer_alerts',
        'GYMPLY Timer Alerts',
        channelDescription: 'Alerts when your rest or interval timer completes',
        importance: Importance.max,
        priority: Priority.high,
      );

      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: const NotificationDetails(
          iOS: darwinDetails,
          android: androidDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      _logger.i(
        'NotificationService: Alert ($id) scheduled for $scheduledDate',
      );
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to schedule alert',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Cancels a scheduled local notification.
  Future<void> cancelTimerAlert(int id) async {
    if (!Platform.isIOS) return;

    try {
      await _localNotifications.cancel(id: id);
      _logger.i('NotificationService: Cancelled alert ($id)');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to cancel alert',
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
    if (!Platform.isAndroid) return;

    try {
      if (await FlutterForegroundTask.isRunningService) {
        final Map<String, dynamic> data = <String, dynamic>{'total': totalTime};

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

  // Centralized effect that watches all timer signals and syncs notification
  // across Android Foreground Task and iOS Live Activity.
  void _setupTimerEffect() {
    effect(() async {
      final bool isTotalRunning = TotalTimer.sTotalTimerRunning.value;
      final int totalSeconds = TotalTimer.sElapsedTotalTime.value;

      final bool isIntervalRunning = IntervalTimer.sIntervalTimerRunning.value;
      final int intervalMs = IntervalTimer.sElapsedIntervalTime.value;

      final bool isRestRunning = RestTimer.sRestTimerRunning.value;
      final int restSeconds = RestTimer.sElapsedRestTime.value;

      final bool isStopwatchRunning =
          StopwatchTimer.sStopwatchTimerRunning.value;
      final int stopwatchMs = StopwatchTimer.sElapsedStopwatchTime.value;

      // 1. Determine active segment (Priority: Interval > Rest > Stopwatch)
      String? label;
      String? timeStr;
      DateTime? segmentEndTime;

      if (isIntervalRunning) {
        label = 'INTERVAL';
        timeStr = (intervalMs ~/ 1000).formatHMMSS();
        segmentEndTime = intervalTimer.endTime;
      } else if (isRestRunning) {
        label = 'REST';
        timeStr = restSeconds.formatMSS();
        segmentEndTime = restTimer.endTime;
      } else if (isStopwatchRunning) {
        label = 'STOPWATCH';
        timeStr = (stopwatchMs ~/ 1000).formatHMMSS();
      } else {
        label = '';
        timeStr = '';
      }

      // 2. Manage Android Foreground Service Lifecycle
      if (Platform.isAndroid) {
        if (isTotalRunning) {
          if (!await FlutterForegroundTask.isRunningService) {
            await startService();
          }
          unawaited(
            updateNotificationDisplay(
              totalTime: totalSeconds.formatHMMSS(),
              segmentLabel: label,
              segmentTime: timeStr,
            ),
          );
        } else {
          if (await FlutterForegroundTask.isRunningService) {
            await stopService();
          }
        }
      }

      // 3. Manage iOS Live Activity Lifecycle
      if (Platform.isIOS) {
        if (isTotalRunning) {
          final DateTime totalStartTime =
              totalTimer.startTime ?? DateTime.now();
          if (!liveActivityService.isActivityActive) {
            await liveActivityService.startActivity(
              totalStartTime: totalStartTime,
              segmentLabel: label,
              segmentEndTime: segmentEndTime,
            );
          } else {
            await liveActivityService.updateActivity(
              segmentLabel: label,
              segmentEndTime: segmentEndTime,
            );
          }
        } else {
          if (liveActivityService.isActivityActive) {
            await liveActivityService.stopActivity();
          }
        }
      }
    });
  }

  Future<void> startService() async {
    if (!Platform.isAndroid) return;

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
      _logger.i('NotificationService: Android service started.');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to start',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> stopService() async {
    if (!Platform.isAndroid) return;

    try {
      await FlutterForegroundTask.stopService();
      _logger.i('NotificationService: Android service stopped.');
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
      // Check Notification permission across platforms.
      final PermissionStatus status = await Permission.notification.status;
      if (status.isGranted) {
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
    await _requestBatteryOptimization();
  }

  static Future<void> _requestBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  void _onReceiveTaskData(Object data) {}
}

final NotificationService notificationService = NotificationService();
