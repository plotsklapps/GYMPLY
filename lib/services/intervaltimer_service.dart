import 'dart:async';

import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:gymply/services/haptic_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:signals/signals_flutter.dart';

class IntervalTimer {
  // Create a singleton instance of IntervalTimer.
  factory IntervalTimer() {
    return _instance;
  }

  IntervalTimer._internal() {
    // This effect handles the transition from Rest back to Interval.
    effect(() async {
      final bool isRestDone = RestTimer.sRestTimerCompleted.value;

      if (isRestDone && _isIntervalSequenceActive) {
        // Immediately prevent re-entry.
        _isIntervalSequenceActive = false;

        final WorkoutExercise? exercise =
            workoutService.sSelectedExercise.value;

        if (exercise is CardioExercise) {
          workoutService.addCardioSet(
            exercise,
            cardioDuration: Duration(milliseconds: sInitialIntervalTime.value),
            restDuration: Duration(seconds: RestTimer.sInitialRestTime.value),
            totalDuration: Duration(
              milliseconds:
                  sInitialIntervalTime.value +
                  (RestTimer.sInitialRestTime.value * 1000),
            ),
          );
        }

        // Reset the signal.
        RestTimer.sRestTimerCompleted.value = false;

        // Auto-restart if enabled.
        if (sAutoIntervalOn.value) {
          await startTimer();
        }
      }
    });
  }

  bool _isIntervalSequenceActive = false;

  static final IntervalTimer _instance = IntervalTimer._internal();

  // Signals.
  // Initial time in MILLISECONDS.
  static final Signal<int> sInitialIntervalTime = Signal<int>(
    60000,
    debugLabel: 'sInitialIntervalTime',
  );

  // Elapsed time in MILLISECONDS.
  static final Signal<int> sElapsedIntervalTime = Signal<int>(
    60000,
    debugLabel: 'sElapsedIntervalTime',
  );

  static final Signal<bool> sIntervalTimerCompleted = Signal<bool>(
    false,
    debugLabel: 'sIntervalTimerCompleted',
  );

  static final Signal<bool> sIntervalTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sIntervalTimerRunning',
  );

  static final Signal<bool> sAutoIntervalOn = Signal<bool>(
    false,
    debugLabel: 'sAutoIntervalOn',
  );

  // Computed signal for the formatted time.
  static final Computed<String> cFormattedIntervalTime = Computed<String>(
    () {
      return sElapsedIntervalTime.value.formatHMMSSCC();
    },
    debugLabel: 'cFormattedIntervalTime',
  );

  Timer? _timer;
  DateTime? _endTime;

  Future<void> startTimer() async {
    // Synchronous check to prevent multiple timers.
    if (_timer != null || sIntervalTimerRunning.value) return;

    _isIntervalSequenceActive = true;
    sIntervalTimerRunning.value = true;
    sIntervalTimerCompleted.value = false;

    await HapticService.light();

    // Calculate when the interval should end based on current elapsed ms.
    _endTime = DateTime.now().add(
      Duration(milliseconds: sElapsedIntervalTime.value),
    );

    // Set a high-frequency timer (10ms) to support centisecond updates.
    _timer = Timer.periodic(const Duration(milliseconds: 10), (
      Timer timer,
    ) async {
      if (_endTime == null) return;

      final Duration remaining = _endTime!.difference(DateTime.now());
      final int remainingMs = remaining.inMilliseconds;

      if (remainingMs > 0) {
        sElapsedIntervalTime.value = remainingMs;
      } else {
        // Stop this timer immediately.
        _timer?.cancel();
        _timer = null;
        _endTime = null;
        sIntervalTimerRunning.value = false;

        sElapsedIntervalTime.value = 0;

        // Play interval-completed sound. Do NOT await.
        // ignore: unawaited_futures
        AudioService().playStartSound();

        // Wait to finish before clean up or allow re-start.
        await Future<void>.delayed(const Duration(milliseconds: 500));

        sIntervalTimerCompleted.value = true;

        // Reset to initial milliseconds.
        sElapsedIntervalTime.value = sInitialIntervalTime.value;

        // Start the rest period.
        await RestTimer().startTimer();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    sIntervalTimerRunning.value = false;
  }

  Future<void> resetTimer() async {
    _isIntervalSequenceActive = false;
    await HapticService.heavy();

    _timer?.cancel();
    _timer = null;
    _endTime = null;

    // Reset to initial milliseconds.
    sElapsedIntervalTime.value = sInitialIntervalTime.value;
    sIntervalTimerRunning.value = false;
    sIntervalTimerCompleted.value = false;
  }
}
