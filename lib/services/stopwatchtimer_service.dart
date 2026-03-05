import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:signals/signals_flutter.dart';

class StopwatchTimer {
  // Create a singleton instance of StopwatchTimer.
  factory StopwatchTimer() {
    return _instance;
  }

  StopwatchTimer._internal();
  static final StopwatchTimer _instance = StopwatchTimer._internal();

  // Signals.
  static final Signal<int> sElapsedStopwatchTime = Signal<int>(
    0,
    debugLabel: 'sElapsedStopwatchTime',
  );

  // Computed signal for the formatted time.
  // Using CC (centiseconds) provides that fast-moving, smooth stopwatch feel.
  static final Computed<String> cFormattedStopwatchTime = Computed<String>(
    () {
      return sElapsedStopwatchTime.value.formatHMMSSCC();
    },
    debugLabel: 'sFormattedStopwatchTime',
  );

  static final Signal<bool> sStopwatchTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sStopwatchTimerRunning',
  );

  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _baseTime = 0;

  Future<void> startTimer() async {
    // Prevent multiple timers from running at once.
    if (_timer != null) {
      return;
    }

    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    sStopwatchTimerRunning.value = true;
    _stopwatch.start();

    // Tick every 10ms to perfectly capture every centisecond.
    // This is the frequency needed to see every digit move without jumping.
    _timer = Timer.periodic(const Duration(milliseconds: 10), (Timer timer) {
      sElapsedStopwatchTime.value = _baseTime + _stopwatch.elapsedMilliseconds;
    });
  }

  Future<void> pauseTimer() async {
    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    _stopwatch.stop();
    _baseTime += _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();

    _timer?.cancel();
    _timer = null;
    sStopwatchTimerRunning.value = false;

    // Sync final value.
    sElapsedStopwatchTime.value = _baseTime;
  }

  Future<void> resetTimer() async {
    // Give a bigger bzzz.
    await HapticFeedback.heavyImpact();

    _timer?.cancel();
    _timer = null;

    _stopwatch
      ..stop()
      ..reset();
    _baseTime = 0;

    sElapsedStopwatchTime.value = 0;
    sStopwatchTimerRunning.value = false;
  }
}
