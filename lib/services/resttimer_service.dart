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

    // Ensure Audio engine is primed while in the tap callback.
    unawaited(AudioService().initialize());

    // Set Signals.
    sRestTimerRunning.value = true;
    sRestTimerCompleted.value = false;

    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    // Calculate when resttimer should end.
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

        // Reset Signals.
        _timer = null;
        _endTime = null;
        sRestTimerRunning.value = false;
        sElapsedRestTime.value = 0;

        // Play rest-completed sound.
        AudioService().playRestSound();

        // Short pause to allow sound to start before state transition.
        await Future<void>.delayed(const Duration(milliseconds: 400));

        // Reset Signals.
        sRestTimerCompleted.value = true;
        sElapsedRestTime.value = sInitialRestTime.value;
      }
    });
  }

  Future<void> pauseTimer() async {
    // Give a little bzzz.
    await HapticFeedback.lightImpact();

    // Cancel timer and reset Signals.
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    sRestTimerRunning.value = false;
  }

  // Resets Timer state.
  Future<void> resetTimer() async {
    // Give a bigger bzzz.
    await HapticFeedback.mediumImpact();

    // Reset timer and reset Signals.
    _timer?.cancel();
    _timer = null;
    _endTime = null;

    // Reset to initial seconds.
    sElapsedRestTime.value = sInitialRestTime.value;
    sRestTimerRunning.value = false;
    sRestTimerCompleted.value = false;
  }
}

// Globalize RestTimer.
final RestTimer restTimer = RestTimer();
