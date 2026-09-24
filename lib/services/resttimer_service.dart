import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/notification_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

class RestTimer {
  // Create a singleton instance of RestTimer.
  factory RestTimer() {
    return _instance;
  }
  RestTimer._internal();
  static final RestTimer _instance = RestTimer._internal();

  final Logger _logger = Logger();

  // Int Signal to track initial rest time.
  static final Signal<int> sInitialRestTime = Signal<int>(
    60,
    options: const SignalOptions<int>(name: 'sInitialRestTime'),
  );

  // Int Signal to track elapsed rest time.
  static final Signal<int> sElapsedRestTime = Signal<int>(
    60,
    options: const SignalOptions<int>(name: 'sElapsedRestTime'),
  );

  // Bool Signal to track if resttimer has completed.
  static final Signal<bool> sRestTimerCompleted = Signal<bool>(
    false,
    options: const SignalOptions<bool>(name: 'sRestTimerCompleted'),
  );

  // Bool Signal to track if resttimer is running.
  static final Signal<bool> sRestTimerRunning = Signal<bool>(
    false,
    options: const SignalOptions<bool>(name: 'sRestTimerRunning'),
  );

  Timer? _timer;
  DateTime? _endTime;

  DateTime? get endTime => _endTime;

  Future<void> startTimer() async {
    // Synchronous check to prevent multiple timers.
    if (_timer != null || sRestTimerRunning.value) return;

    try {
      // Mutual Exclusion Guard.
      if (StopwatchTimer.sStopwatchTimerRunning.value ||
          IntervalTimer.sIntervalTimerRunning.value) {
        ToastService.showWarning(
          title: 'Timer already running',
          subtitle:
              'Please stop the active timer before starting a rest period.',
        );
        return;
      }

      // Ensure Audio engine is primed while in the tap callback.
      unawaited(AudioService().initialize());

      // Set Signals.
      sRestTimerRunning.value = true;
      sRestTimerCompleted.value = false;

      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Calculate when resttimer should end.
      _endTime = DateTime.now().add(Duration(seconds: sElapsedRestTime.value));

      // Schedule OS alert with custom timer bell sound for background/iOS.
      final int totalSeconds = TotalTimer.sElapsedTotalTime.value;
      unawaited(
        notificationService.scheduleTimerAlert(
          id: NotificationService.restTimerNotificationId,
          scheduledDate: _endTime!,
          title: 'GYMPLY • REST FINISHED',
          body: 'TOTAL TIME: ${totalSeconds.formatHMMSS()}\n'
              'Time for your next set!',
        ),
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
        if (_endTime == null) return;

        final Duration remaining = _endTime!.difference(DateTime.now());
        // Use ceil() to ensure that even 8.9 seconds is shown as 9 seconds.
        final int remainingSeconds = (remaining.inMilliseconds / 1000).ceil();

        if (remainingSeconds > 0) {
          sElapsedRestTime.value = remainingSeconds;
        } else {
          // Stop timer immediately.
          _timer?.cancel();

          // Reset Signals.
          _timer = null;
          _endTime = null;
          sRestTimerRunning.value = false;
          sElapsedRestTime.value = 0;

          // Cancel any pending alert so it doesn't double-trigger.
          unawaited(
            notificationService.cancelTimerAlert(
              NotificationService.restTimerNotificationId,
            ),
          );

          // Only play sound via AudioPlayer if app is in foreground on iOS.
          // On iOS in background, scheduled OS notification handles the sound.
          // On Android, background service handles audio.
          final bool isForeground =
              WidgetsBinding.instance.lifecycleState ==
                  AppLifecycleState.resumed;
          if (!Platform.isIOS || isForeground) {
            unawaited(AudioService().playTimerBell());
          }

          // Reset Signals.
          sRestTimerCompleted.value = true;
          sElapsedRestTime.value = sInitialRestTime.value;
        }
      });
      _logger.i('RestTimer: Started.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('RestTimer: Failed to start', error: e, stackTrace: stack);
    }
  }

  void syncOnResume() {
    if (!sRestTimerRunning.value || _endTime == null) return;

    final Duration remaining = _endTime!.difference(DateTime.now());
    final int remainingSeconds = (remaining.inMilliseconds / 1000).ceil();

    if (remainingSeconds <= 0) {
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      sRestTimerRunning.value = false;
      sElapsedRestTime.value = 0;
      sRestTimerCompleted.value = true;
      sElapsedRestTime.value = sInitialRestTime.value;
      unawaited(
        notificationService.cancelTimerAlert(
          NotificationService.restTimerNotificationId,
        ),
      );
    } else {
      sElapsedRestTime.value = remainingSeconds;
    }
  }

  Future<void> pauseTimer() async {
    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Cancel OS scheduled alert.
      unawaited(
        notificationService.cancelTimerAlert(
          NotificationService.restTimerNotificationId,
        ),
      );

      // Cancel timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      sRestTimerRunning.value = false;

      _logger.i('RestTimer: Paused.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('RestTimer: Failed to pause', error: e, stackTrace: stack);
    }
  }

  // Resets Timer state.
  Future<void> resetTimer() async {
    try {
      // Give a bigger bzzz.
      await HapticFeedback.mediumImpact();

      // Cancel OS scheduled alert.
      unawaited(
        notificationService.cancelTimerAlert(
          NotificationService.restTimerNotificationId,
        ),
      );

      // Reset timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      _endTime = null;

      // Reset to initial seconds.
      sElapsedRestTime.value = sInitialRestTime.value;
      sRestTimerRunning.value = false;
      sRestTimerCompleted.value = false;
      _logger.i('RestTimer: Reset.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('RestTimer: Failed to reset', error: e, stackTrace: stack);
    }
  }
}

// Globalize RestTimer.
final RestTimer restTimer = RestTimer();
