import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:logger/logger.dart';

// Unique service ID for GYMPLY's foreground service.
const int kGymplyServiceId = 901;

// Top-level entry point for the foreground service isolate.
@pragma('vm:entry-point')
void gymplyTaskCallback() {
  FlutterForegroundTask.setTaskHandler(GymplyTaskHandler());
}

// Private TaskHandler — runs in the foreground service isolate.
class GymplyTaskHandler extends TaskHandler {
  String _totalText = '00:00:00';
  String _segmentText = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Re-sync logic: If the main isolate hasn't sent data yet, it defaults to 'Total'.
    final String body = _segmentText.isNotEmpty
        ? 'Total: $_totalText | $_segmentText'
        : 'Total: $_totalText';

    unawaited(FlutterForegroundTask.updateService(notificationText: body));
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map<String, dynamic>) return;
    _totalText = data['total'] as String? ?? _totalText;
    _segmentText = data['segment'] as String? ?? '';
  }
}

class ForegroundService {
  factory ForegroundService() => _instance;
  ForegroundService._internal();
  static final ForegroundService _instance = ForegroundService._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'gymply_timer_channel',
          channelName: 'GYMPLY Timer',
          channelDescription: 'Shows the live timer status.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          showWhen: false,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(1000),
          allowWakeLock: true,
        ),
      );
      _isInitialized = true;
      _logger.i('ForegroundService: Initialized successfully.');
    } on Object catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to initialize',
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
        // The TaskHandler's onRepeatEvent() handles the actual notification update.
        FlutterForegroundTask.sendDataToTask(<String, dynamic>{
          'total': totalTime,
          'segment': segmentDisplay,
        });
      }
    } on Object catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to update',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> startService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) return;

      await FlutterForegroundTask.startService(
        serviceId: kGymplyServiceId,
        serviceTypes: const <ForegroundServiceTypes>[
          ForegroundServiceTypes.health,
        ],
        notificationTitle: 'GYMPLY.',
        notificationText: 'Total: 00:00:00',
        callback: gymplyTaskCallback,
      );
      _logger.i('ForegroundService: Started.');
    } on Object catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to start',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> stopService() async {
    try {
      await FlutterForegroundTask.stopService();
      _logger.i('ForegroundService: Service stopped.');
    } on Object catch (e, stack) {
      _logger.e(
        'ForegroundService: Failed to stop',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> requestPermissionWithDialog(BuildContext context) async {
    try {
      final NotificationPermission permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission == NotificationPermission.granted) {
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
        'ForegroundService: Permission request failed',
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

final ForegroundService foregroundService = ForegroundService();
