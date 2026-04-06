import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:gymply/services/foreground_service.dart';
import 'package:gymply/services/timeformat_service.dart';
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
    debugLabel: 'sInitialRestTime',
  );

  // Int Signal to track elapsed rest time.
  static final Signal<int> sElapsedRestTime = Signal<int>(
    60,
    debugLabel: 'sElapsedRestTime',
  );

  // Bool Signal to track if resttimer has completed.
  static final Signal<bool> sRestTimerCompleted = Signal<bool>(
    false,
    debugLabel: 'sRestTimerCompleted',
  );

  // Bool Signal to track if resttimer is running.
  static final Signal<bool> sRestTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sRestTimerRunning',
  );

  Timer? _timer;
  DateTime? _endTime;

  Future<void> startTimer() async {
    // Synchronous check to prevent multiple timers.
    if (_timer != null || sRestTimerRunning.value) return;

    try {
      // Ensure Audio engine is primed while in the tap callback.
      unawaited(AudioService().initialize());

      // Set Signals.
      sRestTimerRunning.value = true;
      sRestTimerCompleted.value = false;

      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Calculate when resttimer should end.
      _endTime = DateTime.now().add(Duration(seconds: sElapsedRestTime.value));

      // Always start the foreground service.
      await foregroundService.startService();

      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
        if (_endTime == null) return;

        final Duration remaining = _endTime!.difference(DateTime.now());
        final int remainingSeconds = (remaining.inMilliseconds / 1000).ceil();

        // Update notification
        final String totalStr = TotalTimer.sElapsedTotalTime.value
            .formatHMMSS();
        unawaited(
          foregroundService.updateWorkoutDisplay(
            totalTime: totalStr,
            segmentLabel: 'Rest',
            segmentTime: (remainingSeconds > 0 ? remainingSeconds : 0)
                .formatMSS(),
          ),
        );

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

          // Play rest-completed sound first.
          unawaited(AudioService().playTimerBell());

          // Reset Signals.
          sRestTimerCompleted.value = true;
          sElapsedRestTime.value = sInitialRestTime.value;
        }
      });
      _logger.i('RestTimer: Started.');
    } catch (e, stack) {
      _logger.e('RestTimer: Failed to start', error: e, stackTrace: stack);
    }
  }

  Future<void> pauseTimer() async {
    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Cancel timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      sRestTimerRunning.value = false;

      if (TotalTimer.sTotalTimerRunning.value) {
        await totalTimer.startTimer();
      } else {
        unawaited(foregroundService.stopService());
      }
      _logger.i('RestTimer: Paused.');
    } catch (e, stack) {
      _logger.e('RestTimer: Failed to pause', error: e, stackTrace: stack);
    }
  }

  // Resets Timer state.
  Future<void> resetTimer() async {
    try {
      // Give a bigger bzzz.
      await HapticFeedback.mediumImpact();

      // Reset timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      _endTime = null;

      if (TotalTimer.sTotalTimerRunning.value) {
        await totalTimer.startTimer();
      } else {
        unawaited(foregroundService.stopService());
      }

      // Reset to initial seconds.
      sElapsedRestTime.value = sInitialRestTime.value;
      sRestTimerRunning.value = false;
      sRestTimerCompleted.value = false;
      _logger.i('RestTimer: Reset.');
    } catch (e, stack) {
      _logger.e('RestTimer: Failed to reset', error: e, stackTrace: stack);
    }
  }
}

// Globalize RestTimer.
final RestTimer restTimer = RestTimer();
