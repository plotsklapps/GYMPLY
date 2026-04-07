import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/notification_handler.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;

  // Unique service ID for GYMPLY's foreground service.
  static const int _serviceId = 901;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
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
      _logger.i('NotificationService: Initialized successfully.');
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to initialize',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> updateWorkoutDisplay({
    required String totalTime,
    String? segmentLabel,
    String? segmentTime,
  }) async {
    try {
      final String segmentDisplay =
          (segmentLabel != null && segmentTime != null)
          ? '$segmentLabel: $segmentTime'
          : '';

      if (await FlutterForegroundTask.isRunningService) {
        // Send data to the background task isolate.
        // The NotificationHandler's onRepeatEvent() handles the actual
        // notification update.
        FlutterForegroundTask.sendDataToTask(<String, dynamic>{
          'total': totalTime,
          'segment': segmentDisplay,
        });
      }
    } on Object catch (e, stack) {
      _logger.e(
        'NotificationService: Failed to update',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> startService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) return;

      await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        serviceTypes: const <ForegroundServiceTypes>[
          ForegroundServiceTypes.health,
        ],
        notificationTitle: 'GYMPLY.',
        notificationText: 'Total: 00:00:00',
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
      // Check both Notification and Physical Activity permissions.
      final NotificationPermission notificationPerm =
          await FlutterForegroundTask.checkNotificationPermission();
      final bool activityPermGranted =
          await Permission.activityRecognition.isGranted;

      // If both are already granted, we can skip the modal.
      if (notificationPerm == NotificationPermission.granted &&
          activityPermGranted) {
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

  static Future<void> requestBatteryOptimization() async =>
      _requestBatteryOptimization();

  static Future<void> _requestBatteryOptimization() async {
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  void _onReceiveTaskData(Object data) {}
}

final NotificationService notificationService = NotificationService();
