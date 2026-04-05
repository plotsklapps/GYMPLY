import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Central provider for local device notifications.
// It handles background timer execution via native APIs.
class NotificationService {
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Constants for our specific notification IDs.
  static const int chronometerId = 1;
  static const int alarmId = 2;

  Future<void> init() async {
    if (_isInitialized) return;

    // Required initialization for zonedSchedule (exact alarms).
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _logger.i('NotificationService: Notification tapped.');
      },
    );

    _isInitialized = true;
    _logger.i('NotificationService: Initialized');
  }

  // Method to start both the chronometer and the final alarm.
  Future<void> startTimerNotification({
    required String title,
    required String body,
    required int durationSeconds,
  }) async {
    if (!_isInitialized) return;

    final DateTime endTime = DateTime.now().add(
      Duration(seconds: durationSeconds),
    );

    // 1. Show the Chronometer Notification (Silently counts down).
    final AndroidNotificationDetails chronometerAndroidDetails =
        AndroidNotificationDetails(
          'timer_chronometer_channel',
          'Active Timer',
          channelDescription: 'Shows the active ticking timer for your workout',
          // Low importance so it stays in the tray cleanly without vibrating.
          importance: Importance.low,
          priority: Priority.low,
          color: const Color(0xFFFCB075), // GYMPLY primary accent color.
          usesChronometer: true,
          chronometerCountDown: true,
          when: endTime.millisecondsSinceEpoch,
          ongoing: true, // Prevents easy swiping while active.
          playSound: false,
        );

    await flutterLocalNotificationsPlugin.show(
      id: chronometerId,
      title: title,
      body: 'Counting down...',
      notificationDetails: NotificationDetails(
        android: chronometerAndroidDetails,
      ),
    );

    // 2. Schedule the Exact Alarm Notification.
    const AndroidNotificationDetails alarmAndroidDetails =
        AndroidNotificationDetails(
          'timer_alarm_channel',
          'Timer Complete Alerts',
          channelDescription: 'Plays the alert sound when a timer finishes',
          importance: Importance.max,
          priority: Priority.max,
          color: Color(0xFFFCB075),
          // Assign custom MP3 from android raw directory.
          sound: RawResourceAndroidNotificationSound('timerbell'),
        );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: alarmId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(endTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: alarmAndroidDetails,
      ),
      // Critical for precise alarms in Android >= 12.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    _logger.i(
      'NotificationService: Scheduled notifications for '
      '$durationSeconds seconds.',
    );
  }

  // Clear any active or scheduled notifications.
  Future<void> cancelTimerNotifications() async {
    if (!_isInitialized) return;
    await flutterLocalNotificationsPlugin.cancel(id: chronometerId);
    await flutterLocalNotificationsPlugin.cancel(id: alarmId);
    _logger.i('NotificationService: Timer notifications cancelled');
  }

  // Safe UI helper to organically request permissions from existing users
  // exactly when they press 'Play' on a respective timer widget.
  Future<void> requestPermissionWithDialog(BuildContext context) async {
    // If the user already granted permission, completely bypass everything.
    if (await Permission.notification.isGranted) {
      return;
    }

    // Wait until widget is ready since we might be called synchronously
    // from a button tap without an immediate context update.
    if (!context.mounted) return;

    // Show the modal to explain the permission before asking the OS.
    await ModalService.showModal(
      context: context,
      child: const PermissionModal(),
    );
  }
}

// Globalize NotificationService.
final NotificationService notificationService = NotificationService();
