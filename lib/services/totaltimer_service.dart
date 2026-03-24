import 'dart:async';

import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';

class TotalTimer {
  // Create a singleton instance of TotalTimer.
  factory TotalTimer() {
    return _instance;
  }

  TotalTimer._internal();
  static final TotalTimer _instance = TotalTimer._internal();

  // Signals.
  static final Signal<int> sInitialTotalTime = Signal<int>(
    0,
    debugLabel: 'sInitialTotalTime',
  );

  static final Signal<int> sElapsedTotalTime = Signal<int>(
    0,
    debugLabel: 'sElapsedTotalTime',
  );

  static final Signal<bool> sTotalTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sTotalTimerRunning',
  );

  Timer? _timer;
  DateTime? _startTime;

  Future<void> startTimer() async {
    // Prevent multiple timers from running at once.
    if (_timer != null) {
      return;
    }

    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    sTotalTimerRunning.value = true;

    // Calculate start time based on current elapsed time to allow
    // accurate resumption.
    _startTime = DateTime.now().subtract(
      Duration(seconds: sElapsedTotalTime.value),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_startTime != null) {
        sElapsedTotalTime.value = DateTime.now()
            .difference(_startTime!)
            .inSeconds;
      }
    });
  }

  Future<void> pauseTimer() async {
    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    _timer?.cancel();
    _timer = null;
    sTotalTimerRunning.value = false;
    _startTime = null;
  }

  Future<void> resetTimer() async {
    // Give a bigger bzzz.
    await HapticFeedback.mediumImpact();

    _timer?.cancel();
    _timer = null;
    _startTime = null;
    sElapsedTotalTime.value = sInitialTotalTime.value;
    sTotalTimerRunning.value = false;
  }
}

// Globalize TotalTimer.
final TotalTimer totalTimer = TotalTimer();
