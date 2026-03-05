import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:signals/signals_flutter.dart';

class RestTimer {
  // Create a singleton instance of RestTimer.
  factory RestTimer() {
    return _instance;
  }
  RestTimer._internal();
  static final RestTimer _instance = RestTimer._internal();

  // Signals.
  static final Signal<int> sInitialRestTime = Signal<int>(
    60,
    debugLabel: 'sInitialRestTime',
  );

  static final Signal<int> sElapsedRestTime = Signal<int>(
    60,
    debugLabel: 'sElapsedRestTime',
  );

  static final Signal<bool> sRestTimerCompleted = Signal<bool>(
    false,
    debugLabel: 'sRestTimerCompleted',
  );

  static final Signal<bool> sRestTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sRestTimerRunning',
  );

  Timer? _timer;
  DateTime? _endTime;

  Future<void> startTimer() async {
    // Immediate guard to prevent concurrent timers during async gaps.
    if (_timer != null || sRestTimerRunning.value) return;

    // Critical: Ensure Audio context is primed while we are in the tap callback.
    unawaited(AudioService().initialize());

    sRestTimerRunning.value = true;
    sRestTimerCompleted.value = false;

    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    // Calculate when the timer should end.
    _endTime = DateTime.now().add(Duration(seconds: sElapsedRestTime.value));

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
        _timer = null;
        _endTime = null;
        sRestTimerRunning.value = false;

        sElapsedRestTime.value = 0;

        // Play rest-completed sound (Non-blocking).
        AudioService().playRestSound();

        // Wait to finish before clean up or allow re-start.
        await Future<void>.delayed(const Duration(milliseconds: 500));

        sRestTimerCompleted.value = true;
        sElapsedRestTime.value = sInitialRestTime.value;
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    sRestTimerRunning.value = false;
  }

  // Resets Timer state.
  Future<void> resetTimer() async {
    // Give a bigger bzzz.
    await HapticFeedback.heavyImpact();

    _timer?.cancel();
    _timer = null;
    _endTime = null;

    sElapsedRestTime.value = sInitialRestTime.value;
    sRestTimerRunning.value = false;
    sRestTimerCompleted.value = false;
  }
}
