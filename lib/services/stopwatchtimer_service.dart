import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/services/foreground_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/totaltimer_service.dart'; // To revert to total timer when stopped.
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

class StopwatchTimer {
  // Singleton pattern.
  factory StopwatchTimer() {
    return _instance;
  }

  StopwatchTimer._internal();
  static final StopwatchTimer _instance = StopwatchTimer._internal();

  final Logger _logger = Logger();

  // Int Signal to track elapsed stopwatch time.
  static final Signal<int> sElapsedStopwatchTime = Signal<int>(
    0,
    debugLabel: 'sElapsedStopwatchTime',
  );

  // Computed Signal for formatted time.
  static final Computed<String> cFormattedStopwatchTime = Computed<String>(
    () {
      // Using centiseconds to provide stopwatch 'feel'.
      return sElapsedStopwatchTime.value.formatHMMSSCC();
    },
    debugLabel: 'sFormattedStopwatchTime',
  );

  // Bool Signal to track if stopwatch is running.
  static final Signal<bool> sStopwatchTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sStopwatchTimerRunning',
  );

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _baseTime = 0;

  Future<void> startTimer() async {
    // Prevent multiple timers from running at once.
    if (_timer != null) return;

    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      sStopwatchTimerRunning.value = true;
      _stopwatch.start();

      // Always start the foreground service.
      await foregroundService.startService();

      // 10ms ticks to capture every centisecond.
      _timer = Timer.periodic(const Duration(milliseconds: 100), (Timer timer) {
        sElapsedStopwatchTime.value =
            _baseTime + _stopwatch.elapsedMilliseconds;

        // Update notification with live TotalTimer value.
        unawaited(
          foregroundService.updateWorkoutDisplay(
            totalTime: TotalTimer.sElapsedTotalTime.value.formatHMMSS(),
            segmentLabel: 'Stopwatch',
            segmentTime: (sElapsedStopwatchTime.value ~/ 1000).formatHMMSS(),
          ),
        );
      });
      _logger.i('StopwatchTimer: Started.');
    } catch (e, stack) {
      _logger.e('StopwatchTimer: Failed to start', error: e, stackTrace: stack);
    }
  }

  Future<void> pauseTimer() async {
    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Cancel timer and reset Signals.
      _stopwatch.stop();
      _baseTime += _stopwatch.elapsedMilliseconds;
      _stopwatch.reset();

      _timer?.cancel();
      _timer = null;
      sStopwatchTimerRunning.value = false;

      // Sync final value.
      sElapsedStopwatchTime.value = _baseTime;

      // Revert the foreground service back to "Total" mode if workout timer is running.
      if (TotalTimer.sTotalTimerRunning.value) {
        await totalTimer.startTimer();
      } else {
        unawaited(foregroundService.stopService());
      }
      _logger.i('StopwatchTimer: Paused.');
    } catch (e, stack) {
      _logger.e('StopwatchTimer: Failed to pause', error: e, stackTrace: stack);
    }
  }

  // Update baseTime to allow for manual setting.
  void setManualTime(int milliseconds) {
    _baseTime = milliseconds;
    _stopwatch.reset();
    sElapsedStopwatchTime.value = milliseconds;
  }

  Future<void> resetTimer() async {
    try {
      // Give a bigger bzzz.
      await HapticFeedback.mediumImpact();

      // Cancel timer and reset Signals.
      _timer?.cancel();
      _timer = null;

      _stopwatch
        ..stop()
        ..reset();
      _baseTime = 0;

      sElapsedStopwatchTime.value = 0;
      sStopwatchTimerRunning.value = false;

      // Revert back or stop service entirely.
      if (TotalTimer.sTotalTimerRunning.value) {
        await totalTimer.startTimer();
      } else {
        unawaited(foregroundService.stopService());
      }
      _logger.i('StopwatchTimer: Reset.');
    } catch (e, stack) {
      _logger.e('StopwatchTimer: Failed to reset', error: e, stackTrace: stack);
    }
  }
}

// Globalize StopwatchTimer.
final StopwatchTimer stopwatchTimer = StopwatchTimer();
