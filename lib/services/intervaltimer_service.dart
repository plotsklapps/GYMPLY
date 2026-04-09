import 'dart:async';

import 'package:flutter/services.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/selectedexercise_signal.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

class IntervalTimer {
  // Singleton pattern.
  factory IntervalTimer() {
    return _instance;
  }

  // Constructor.
  IntervalTimer._internal() {
    // Effect to handle transition from Rest to Interval.
    effect(() async {
      final bool isRestDone = RestTimer.sRestTimerCompleted.value;

      if (isRestDone && _isIntervalSequenceActive) {
        // Immediately prevent re-entry.
        _isIntervalSequenceActive = false;

        final WorkoutExercise? exercise = sSelectedExercise.value;

        // Add CardioSet to CardioExercise.
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
            intensity: exercise.intensityInput ?? 1,
          );
        }
        // Add StretchSet to StretchExercise.
        else if (exercise is StretchExercise) {
          workoutService.addStretchSet(
            exercise,
            stretchDuration: Duration(
              milliseconds: sInitialIntervalTime.value,
            ),
            restDuration: Duration(seconds: RestTimer.sInitialRestTime.value),
            totalDuration: Duration(
              milliseconds:
                  sInitialIntervalTime.value +
                  (RestTimer.sInitialRestTime.value * 1000),
            ),
            intensity: exercise.intensityInput ?? 1,
          );
        }

        // Reset Signal.
        RestTimer.sRestTimerCompleted.value = false;

        // Auto-restart or fallback.
        if (sAutoIntervalOn.value) {
          await startTimer();
        }
      }
    });
  }

  static final IntervalTimer _instance = IntervalTimer._internal();

  final Logger _logger = Logger();

  Timer? _timer;
  DateTime? _endTime;
  bool _isIntervalSequenceActive = false;

  // Int Signal to track initial interval time (in milliseconds).
  static final Signal<int> sInitialIntervalTime = Signal<int>(
    60000,
    debugLabel: 'sInitialIntervalTime',
  );

  // Int Signal to track elapsed interval time (in milliseconds).
  static final Signal<int> sElapsedIntervalTime = Signal<int>(
    60000,
    debugLabel: 'sElapsedIntervalTime',
  );

  // Bool Signal to track if interval timer has completed.
  static final Signal<bool> sIntervalTimerCompleted = Signal<bool>(
    false,
    debugLabel: 'sIntervalTimerCompleted',
  );

  // Bool Signal to track if interval timer is running.
  static final Signal<bool> sIntervalTimerRunning = Signal<bool>(
    false,
    debugLabel: 'sIntervalTimerRunning',
  );

  // Bool Signal to track if auto-interval is enabled.
  static final Signal<bool> sAutoIntervalOn = Signal<bool>(
    false,
    debugLabel: 'sAutoIntervalOn',
  );

  // Computed Signal for formatted time (watches sElapsedIntervalTime Signal).
  static final Computed<String> cFormattedIntervalTime = Computed<String>(
    () {
      return sElapsedIntervalTime.value.formatHMMSSCC();
    },
    debugLabel: 'cFormattedIntervalTime',
  );

  Future<void> startTimer() async {
    // Synchronous check to prevent multiple timers.
    if (_timer != null || sIntervalTimerRunning.value) return;

    try {
      // Mutual Exclusion Guard.
      if (StopwatchTimer.sStopwatchTimerRunning.value) {
        ToastService.showWarning(
          title: 'Timer already running',
          subtitle: 'Please stop the Stopwatch before starting an Interval.',
        );
        return;
      }

      // Ensure Audio engine is primed while in tap callback.
      unawaited(AudioService().initialize());

      // Set Signals.
      _isIntervalSequenceActive = true;
      sIntervalTimerRunning.value = true;
      sIntervalTimerCompleted.value = false;

      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Calculate when interval should end.
      _endTime = DateTime.now().add(
        Duration(milliseconds: sElapsedIntervalTime.value),
      );

      // Set a high-frequency timer (10ms) to support centisecond updates.
      _timer = Timer.periodic(const Duration(milliseconds: 100), (
        Timer timer,
      ) async {
        if (_endTime == null) return;

        final Duration remaining = _endTime!.difference(DateTime.now());
        final int remainingMs = remaining.inMilliseconds;

        if (remainingMs > 0) {
          sElapsedIntervalTime.value = remainingMs;
        } else {
          // Stop timer immediately.
          _timer?.cancel();

          // Reset Signals.
          _timer = null;
          _endTime = null;
          sIntervalTimerRunning.value = false;
          sElapsedIntervalTime.value = 0;

          // Play interval-completed sound.
          unawaited(AudioService().playTimerBell());

          // Short pause to allow sound to start before state transition.
          await Future<void>.delayed(const Duration(milliseconds: 800));

          // Reset Signals.
          sIntervalTimerCompleted.value = true;
          sElapsedIntervalTime.value = sInitialIntervalTime.value;

          // Start the rest period. RestTimer will handle service updates.
          await RestTimer().startTimer();
        }
      });
      _logger.i('IntervalTimer: Started.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('IntervalTimer: Failed to start', error: e, stackTrace: stack);
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
      sIntervalTimerRunning.value = false;

      _logger.i('IntervalTimer: Paused.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('IntervalTimer: Failed to pause', error: e, stackTrace: stack);
    }
  }

  Future<void> resetTimer() async {
    try {
      _isIntervalSequenceActive = false;

      // Give a bigger bzzz.
      await HapticFeedback.mediumImpact();

      // Reset timer and reset Signals.
      _timer?.cancel();
      _timer = null;
      _endTime = null;

      // Reset to initial milliseconds.
      sElapsedIntervalTime.value = sInitialIntervalTime.value;
      sIntervalTimerRunning.value = false;
      sIntervalTimerCompleted.value = false;
      _logger.i('IntervalTimer: Reset.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('IntervalTimer: Failed to reset', error: e, stackTrace: stack);
    }
  }
}

// Globalize IntervalTimer.
final IntervalTimer intervalTimer = IntervalTimer();
