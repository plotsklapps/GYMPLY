import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/services/foreground_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

class TotalTimer {
  // Singleton pattern.
  factory TotalTimer() {
    return _instance;
  }

  TotalTimer._internal();
  static final TotalTimer _instance = TotalTimer._internal();

  final Logger _logger = Logger();

  // Int Signal to track initial total time.
  static final Signal<int> sInitialTotalTime = Signal<int>(
    0,
    debugLabel: 'sInitialTotalTime',
  );

  // Int Signal to track elapsed total time (in seconds).
  static final Signal<int> sElapsedTotalTime = Signal<int>(
    0,
    debugLabel: 'sElapsedTotalTime',
  );

  // Bool Signal to track if total timer is running.
  static final Signal<bool> sTotalTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sTotalTimerRunning',
  );

  Timer? _timer;
  DateTime? _startTime;

  Future<void> startTimer() async {
    // Prevent multiple timers from running at once.
    if (_timer != null) return;

    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      sTotalTimerRunning.value = true;

      // Calculate start time based on current elapsed time to allow
      // accurate resumption.
      _startTime = DateTime.now().subtract(
        Duration(seconds: sElapsedTotalTime.value),
      );

      // Start the foreground service for total workout duration.
      await foregroundService.startService();

      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (_startTime != null) {
          sElapsedTotalTime.value = DateTime.now()
              .difference(_startTime!)
              .inSeconds;

          // Update notification
          unawaited(
            foregroundService.updateWorkoutDisplay(
              totalTime: sElapsedTotalTime.value.formatHMMSS(),
              segmentLabel: null,
              segmentTime: null,
            ),
          );
        }
      });
      _logger.i('TotalTimer: Started.');
    } catch (e, stack) {
      _logger.e('TotalTimer: Failed to start', error: e, stackTrace: stack);
    }
  }

  // Safely updates the timer's duration.
  void syncTotalTime(int seconds) {
    sElapsedTotalTime.value = seconds;
    if (_startTime != null) {
      _startTime = DateTime.now().subtract(Duration(seconds: seconds));
      // Update foreground service if running.
      unawaited(
        foregroundService.updateWorkoutDisplay(
          totalTime: sElapsedTotalTime.value.formatHMMSS(),
          segmentLabel: null,
          segmentTime: null,
        ),
      );
    }
  }

  Future<void> pauseTimer() async {
    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Cancel timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      sTotalTimerRunning.value = false;
      _startTime = null;

      // Stop the foreground service (will revert to total if another timer
      // isn't overriding, but here we stop it entirely if pause is called).
      unawaited(foregroundService.stopService());
      _logger.i('TotalTimer: Paused.');
    } catch (e, stack) {
      _logger.e('TotalTimer: Failed to pause', error: e, stackTrace: stack);
    }
  }

  Future<void> resetTimer() async {
    try {
      // Give a bigger bzzz.
      await HapticFeedback.mediumImpact();

      // Cancel timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      _startTime = null;
      sElapsedTotalTime.value = sInitialTotalTime.value;
      sTotalTimerRunning.value = false;

      unawaited(foregroundService.stopService());
      _logger.i('TotalTimer: Reset.');
    } catch (e, stack) {
      _logger.e('TotalTimer: Failed to reset', error: e, stackTrace: stack);
    }
  }
}

// Globalize TotalTimer.
final TotalTimer totalTimer = TotalTimer();
