import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'package:gymply/signals/selectedexercise_signal.dart';
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
  static const int autoIntervalNotificationBaseId = 2000;
  static const int maxAutoIntervalNotifications = 64;

  int _autoIntervalScheduleGeneration = 0;

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
      if (!kIsWeb && Platform.isAndroid) {
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
      if (!kIsWeb && Platform.isIOS) {
        final bool handledByAutoInterval = intervalTimer.syncOnResume();
        if (!handledByAutoInterval) {
          restTimer.syncOnResume();
        }
      } else {
        restTimer.syncOnResume();
        intervalTimer.syncOnResume();
      }
    } else if (state == AppLifecycleState.paused &&
        !kIsWeb &&
        Platform.isIOS) {
      intervalTimer.refreshBackgroundAlerts();
    }
  }

  // Schedules a native OS alert that plays `timerbell.wav` when the timer
  // reaches zero, even if the app is suspended in the background or killed.
  Future<void> scheduleTimerAlert({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      if (scheduledDate.isBefore(DateTime.now())) return;

      final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: 'timerbell.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'gymply_timer_alerts',
            'GYMPLY Timer Alerts',
            channelDescription:
                'Alerts when your rest or interval timer completes',
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

  // Cancels a scheduled local notification.
  Future<void> cancelTimerAlert(int id) async {
    if (kIsWeb || !Platform.isIOS) return;

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

  /// Schedules up to 64 alternating interval/rest local notifications on iOS
  /// so Auto-Interval continues playing timer alerts while the app is
  /// suspended in the background or on the Lock Screen.
  Future<void> scheduleAutoIntervalAlerts({
    required DateTime currentPhaseEndTime,
    required bool startingInIntervalPhase,
    required Duration intervalDuration,
    required Duration restDuration,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;
    if (intervalDuration.inMilliseconds <= 0) return;

    final int generation = ++_autoIntervalScheduleGeneration;

    try {
      await _cancelPendingAutoIntervalIds(includeSingleAlerts: true);
      if (generation != _autoIntervalScheduleGeneration) return;

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: 'timerbell.wav',
        threadIdentifier: 'gymply_auto_interval',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'gymply_timer_alerts',
            'GYMPLY Timer Alerts',
            channelDescription:
                'Alerts when your rest or interval timer completes',
            importance: Importance.max,
            priority: Priority.high,
          );

      const NotificationDetails details = NotificationDetails(
        iOS: darwinDetails,
        android: androidDetails,
      );

      final DateTime now = DateTime.now();
      final int baseTotalSeconds = TotalTimer.sElapsedTotalTime.value;
      final bool isTotalRunning = TotalTimer.sTotalTimerRunning.value;

      DateTime nextFireTime = currentPhaseEndTime;
      bool isIntervalPhase = startingInIntervalPhase;
      int scheduledCount = 0;

      for (int i = 0; i < maxAutoIntervalNotifications; i++) {
        if (generation != _autoIntervalScheduleGeneration) return;

        if (nextFireTime.isAfter(now)) {
          final int projectedTotal = isTotalRunning
              ? baseTotalSeconds + nextFireTime.difference(now).inSeconds
              : baseTotalSeconds;

          final String title = isIntervalPhase
              ? 'GYMPLY • INTERVAL FINISHED'
              : 'GYMPLY • REST FINISHED';
          final String prompt = isIntervalPhase
              ? (restDuration > Duration.zero
                    ? 'Time to rest!'
                    : 'Next interval starting!')
              : 'Time for your next interval!';

          final tz.TZDateTime tzDate = tz.TZDateTime.from(
            nextFireTime,
            tz.local,
          );

          await _localNotifications.zonedSchedule(
            id: autoIntervalNotificationBaseId + i,
            title: title,
            body: 'TOTAL TIME: ${projectedTotal.formatHMMSS()}\n$prompt',
            scheduledDate: tzDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          scheduledCount++;
        }

        if (isIntervalPhase) {
          if (restDuration > Duration.zero) {
            isIntervalPhase = false;
            nextFireTime = nextFireTime.add(restDuration);
          } else {
            isIntervalPhase = true;
            nextFireTime = nextFireTime.add(intervalDuration);
          }
        } else {
          isIntervalPhase = true;
          nextFireTime = nextFireTime.add(intervalDuration);
        }
      }

      _logger.i(
        'NotificationService: Scheduled $scheduledCount auto-interval alerts.',
      );
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to schedule auto-interval alerts',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Cancels all pending Auto-Interval batch notifications on iOS.
  Future<void> cancelAutoIntervalAlerts() async {
    if (kIsWeb || !Platform.isIOS) return;

    _autoIntervalScheduleGeneration++;

    try {
      await _cancelPendingAutoIntervalIds(includeSingleAlerts: false);
      _logger.i('NotificationService: Cancelled auto-interval alerts.');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to cancel auto-interval alerts',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _cancelPendingAutoIntervalIds({
    required bool includeSingleAlerts,
  }) async {
    final List<PendingNotificationRequest> pending = await _localNotifications
        .pendingNotificationRequests();

    for (final PendingNotificationRequest request in pending) {
      final bool isBatchId =
          request.id >= autoIntervalNotificationBaseId &&
          request.id <
              autoIntervalNotificationBaseId + maxAutoIntervalNotifications;
      final bool isSingleId =
          includeSingleAlerts &&
          (request.id == restTimerNotificationId ||
              request.id == intervalTimerNotificationId);

      if (isBatchId || isSingleId) {
        await _localNotifications.cancel(id: request.id);
      }
    }
  }

  Future<void> updateNotificationDisplay({
    required String totalTime,
    String? segmentLabel,
    String? segmentTime,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

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
      if (!kIsWeb && Platform.isAndroid) {
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
      if (!kIsWeb && Platform.isIOS) {
        if (isTotalRunning) {
          final DateTime totalStartTime =
              totalTimer.startTime ?? DateTime.now();
          final String? exerciseName = sSelectedExercise.value?.exerciseName;
          final bool isAutoInterval = IntervalTimer.sAutoIntervalOn.value;
          final bool inIntervalSequence =
              isIntervalRunning ||
              (isRestRunning && intervalTimer.isIntervalSequenceActive);

          String iosSegmentLabel = label;
          String? iosSegmentDetail;
          DateTime? iosSegmentStartTime;
          DateTime? iosSegmentEndTime;
          DateTime? iosStaleDate;

          if (inIntervalSequence) {
            final int workSec =
                IntervalTimer.sInitialIntervalTime.value ~/ 1000;
            final int restSec = RestTimer.sInitialRestTime.value;
            final String workStr = workSec >= 3600
                ? workSec.formatHMMSS()
                : workSec.formatMSS();
            final String restStr = restSec >= 3600
                ? restSec.formatHMMSS()
                : restSec.formatMSS();

            iosSegmentLabel = isAutoInterval ? 'AUTO-INTERVAL' : 'INTERVAL';
            iosSegmentDetail = '$workStr / $restStr';
            if (!isAutoInterval) {
              if (isIntervalRunning && intervalTimer.endTime != null) {
                iosStaleDate = intervalTimer.endTime!.add(
                  Duration(seconds: restSec),
                );
              } else if (isRestRunning && restTimer.endTime != null) {
                iosStaleDate = restTimer.endTime;
              }
            }
          } else if (isRestRunning) {
            iosSegmentEndTime = segmentEndTime;
            iosStaleDate = segmentEndTime;
          } else if (isStopwatchRunning) {
            iosSegmentStartTime = stopwatchTimer.startTime;
          }

          if (!liveActivityService.isActivityActive) {
            await liveActivityService.startActivity(
              totalStartTime: totalStartTime,
              segmentLabel: iosSegmentLabel,
              segmentDetail: iosSegmentDetail,
              segmentStartTime: iosSegmentStartTime,
              segmentEndTime: iosSegmentEndTime,
              staleDate: iosStaleDate,
              exerciseName: exerciseName,
            );
          } else {
            await liveActivityService.updateActivity(
              totalStartTime: totalStartTime,
              segmentLabel: iosSegmentLabel,
              segmentDetail: iosSegmentDetail,
              segmentStartTime: iosSegmentStartTime,
              segmentEndTime: iosSegmentEndTime,
              staleDate: iosStaleDate,
              exerciseName: exerciseName,
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
    if (kIsWeb || !Platform.isAndroid) return;

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
    if (kIsWeb || !Platform.isAndroid) return;

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
      if (kIsWeb) return;
      final PermissionStatus status = await Permission.notification.status;
      if (status.isGranted) {
        if (!kIsWeb && Platform.isAndroid) await _requestBatteryOptimization();
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

  Future<void> requestIOSPermissions() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to request iOS permissions',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static Future<void> requestBatteryOptimization() async {
    await _requestBatteryOptimization();
  }

  static Future<void> _requestBatteryOptimization() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  void _onReceiveTaskData(Object data) {}
}

final NotificationService notificationService = NotificationService();
