import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:gymply/services/notification_service.dart';
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

        _recordCompletedSet();

        // Reset Signal.
        RestTimer.sRestTimerCompleted.value = false;

        // Auto-restart or fallback.
        if (sAutoIntervalOn.value) {
          await startTimer();
        }
      }
    });

    // Effect to keep iOS scheduled notifications in sync if auto-interval
    // is toggled on or off while a timer sequence is already running.
    effect(() {
      final bool autoOn = sAutoIntervalOn.value;
      if (kIsWeb || !Platform.isIOS) return;

      untracked(() {
        if (sIntervalTimerRunning.value && _endTime != null) {
          if (autoOn) {
            refreshBackgroundAlerts();
          } else {
            unawaited(_switchToSingleIntervalAlert());
          }
        } else if (_isIntervalSequenceActive &&
            RestTimer.sRestTimerRunning.value &&
            restTimer.endTime != null) {
          if (autoOn) {
            refreshBackgroundAlerts();
          } else {
            unawaited(_switchToSingleRestAlert());
          }
        }
      });
    });
  }

  void _recordCompletedSet() {
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
        stretchDuration: Duration(milliseconds: sInitialIntervalTime.value),
        restDuration: Duration(seconds: RestTimer.sInitialRestTime.value),
        totalDuration: Duration(
          milliseconds:
              sInitialIntervalTime.value +
              (RestTimer.sInitialRestTime.value * 1000),
        ),
        intensity: exercise.intensityInput ?? 1,
      );
    }
  }

  Future<void> _switchToSingleIntervalAlert() async {
    await notificationService.cancelAutoIntervalAlerts();
    if (!sIntervalTimerRunning.value || _endTime == null) return;
    final int totalSeconds = TotalTimer.sElapsedTotalTime.value;
    await notificationService.scheduleTimerAlert(
      id: NotificationService.intervalTimerNotificationId,
      scheduledDate: _endTime!,
      title: 'GYMPLY • INTERVAL FINISHED',
      body: 'TOTAL TIME: ${totalSeconds.formatHMMSS()}\nTime to rest!',
    );
  }

  Future<void> _switchToSingleRestAlert() async {
    await notificationService.cancelAutoIntervalAlerts();
    final DateTime? restEnd = restTimer.endTime;
    if (!RestTimer.sRestTimerRunning.value || restEnd == null) return;
    final int totalSeconds = TotalTimer.sElapsedTotalTime.value;
    await notificationService.scheduleTimerAlert(
      id: NotificationService.restTimerNotificationId,
      scheduledDate: restEnd,
      title: 'GYMPLY • REST FINISHED',
      body:
          'TOTAL TIME: ${totalSeconds.formatHMMSS()}\n'
          'Time for your next set!',
    );
  }

  static final IntervalTimer _instance = IntervalTimer._internal();

  final Logger _logger = Logger();

  Timer? _timer;
  DateTime? _endTime;
  bool _isIntervalSequenceActive = false;

  DateTime? get endTime => _endTime;
  bool get isIntervalSequenceActive => _isIntervalSequenceActive;
  bool get isAutoIntervalBatchManaged =>
      _isIntervalSequenceActive && sAutoIntervalOn.value;

  // Schedules a fresh batch of up to 64 alternating iOS alerts starting from
  // whichever phase (interval or rest) is currently running.
  void refreshBackgroundAlerts() {
    if (kIsWeb || !Platform.isIOS || !sAutoIntervalOn.value) return;

    final Duration intervalDuration = Duration(
      milliseconds: sInitialIntervalTime.value,
    );
    final Duration restDuration = Duration(
      seconds: RestTimer.sInitialRestTime.value,
    );

    if (sIntervalTimerRunning.value && _endTime != null) {
      unawaited(
        notificationService.scheduleAutoIntervalAlerts(
          currentPhaseEndTime: _endTime!,
          startingInIntervalPhase: true,
          intervalDuration: intervalDuration,
          restDuration: restDuration,
        ),
      );
    } else if (_isIntervalSequenceActive &&
        RestTimer.sRestTimerRunning.value &&
        restTimer.endTime != null) {
      unawaited(
        notificationService.scheduleAutoIntervalAlerts(
          currentPhaseEndTime: restTimer.endTime!,
          startingInIntervalPhase: false,
          intervalDuration: intervalDuration,
          restDuration: restDuration,
        ),
      );
    }
  }

  // Int Signal to track initial interval time (in milliseconds).
  static final Signal<int> sInitialIntervalTime = Signal<int>(
    60000,
    options: const SignalOptions<int>(name: 'sInitialIntervalTime'),
  );

  // Int Signal to track elapsed interval time (in milliseconds).
  static final Signal<int> sElapsedIntervalTime = Signal<int>(
    60000,
    options: const SignalOptions<int>(name: 'sElapsedIntervalTime'),
  );

  // Bool Signal to track if interval timer has completed.
  static final Signal<bool> sIntervalTimerCompleted = Signal<bool>(
    false,
    options: const SignalOptions<bool>(name: 'sIntervalTimerCompleted'),
  );

  // Bool Signal to track if interval timer is running.
  static final Signal<bool> sIntervalTimerRunning = Signal<bool>(
    false,
    options: const SignalOptions<bool>(name: 'sIntervalTimerRunning'),
  );

  // Bool Signal to track if auto-interval is enabled.
  static final Signal<bool> sAutoIntervalOn = Signal<bool>(
    false,
    options: const SignalOptions<bool>(name: 'sAutoIntervalOn'),
  );

  // Computed Signal for formatted time (watches sElapsedIntervalTime Signal).
  static final Computed<String> cFormattedIntervalTime = Computed<String>(() {
    return sElapsedIntervalTime.value.formatHMMSSD();
  }, options: const ComputedOptions<String>(name: 'cFormattedIntervalTime'));

  Future<void> startTimer({bool silent = false}) async {
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

      // Calculate when interval should end BEFORE updating signals.
      _endTime = DateTime.now().add(
        Duration(milliseconds: sElapsedIntervalTime.value),
      );

      // Set Signals.
      _isIntervalSequenceActive = true;
      sIntervalTimerCompleted.value = false;
      sIntervalTimerRunning.value = true;

      // Give a little bzzz.
      if (!silent) {
        await HapticFeedback.lightImpact();
      }

      // Schedule OS alert(s) with custom timer bell sound for background/iOS.
      if (sAutoIntervalOn.value) {
        refreshBackgroundAlerts();
      } else {
        unawaited(notificationService.cancelAutoIntervalAlerts());
        final int totalSeconds = TotalTimer.sElapsedTotalTime.value;
        unawaited(
          notificationService.scheduleTimerAlert(
            id: NotificationService.intervalTimerNotificationId,
            scheduledDate: _endTime!,
            title: 'GYMPLY • INTERVAL FINISHED',
            body: 'TOTAL TIME: ${totalSeconds.formatHMMSS()}\nTime to rest!',
          ),
        );
      }

      // Set a high-frequency timer (100ms) to support responsive updates.
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

          // Only play sound via AudioPlayer if app is in foreground on iOS.
          // On iOS in background, scheduled OS notification handles sound.
          // On Android, background service handles audio.
          final bool isForeground =
              WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed;
          if (kIsWeb || !Platform.isIOS || isForeground) {
            unawaited(AudioService().playTimerBell());
            // Short pause to allow sound to start before state transition.
            if (isForeground) {
              await Future<void>.delayed(const Duration(milliseconds: 800));
            }
          }

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

  /// Syncs timer state after returning from background.
  /// On iOS, returns true if an active auto-interval sequence (interval or rest
  /// phase) was handled so RestTimer does not duplicate resume logic.
  bool syncOnResume() {
    if (!kIsWeb &&
        Platform.isIOS &&
        sAutoIntervalOn.value &&
        _isIntervalSequenceActive) {
      final bool inInterval = sIntervalTimerRunning.value && _endTime != null;
      final bool inRest =
          RestTimer.sRestTimerRunning.value && restTimer.endTime != null;

      if (inInterval || inRest) {
        _syncAutoIntervalOnResume(inInterval: inInterval);
        return true;
      }
    }

    if (!sIntervalTimerRunning.value || _endTime == null) return false;

    final Duration remaining = _endTime!.difference(DateTime.now());
    final int remainingMs = remaining.inMilliseconds;

    if (remainingMs <= 0) {
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      sIntervalTimerRunning.value = false;
      sElapsedIntervalTime.value = 0;
      sIntervalTimerCompleted.value = true;
      sElapsedIntervalTime.value = sInitialIntervalTime.value;

      unawaited(RestTimer().startTimer());
    } else {
      sElapsedIntervalTime.value = remainingMs;
    }
    return false;
  }

  void _syncAutoIntervalOnResume({required bool inInterval}) {
    final DateTime now = DateTime.now();
    final DateTime? phaseEndTime = inInterval ? _endTime : restTimer.endTime;
    if (phaseEndTime == null) return;

    // Still inside the same phase: update display and refill all 64 iOS alerts.
    if (now.isBefore(phaseEndTime)) {
      final Duration remaining = phaseEndTime.difference(now);
      if (inInterval) {
        sElapsedIntervalTime.value = remaining.inMilliseconds;
      } else {
        RestTimer.sElapsedRestTime.value =
            (remaining.inMilliseconds / 1000).ceil();
      }
      refreshBackgroundAlerts();
      return;
    }

    final int intervalMs = sInitialIntervalTime.value;
    final int restMs = RestTimer.sInitialRestTime.value * 1000;
    final int cycleMs = intervalMs + restMs;
    if (intervalMs <= 0 || cycleMs <= 0) return;

    final int overdueMs = now.difference(phaseEndTime).inMilliseconds;
    int completedSets = 0;
    bool resumeInInterval = true;
    int remainingMs = intervalMs;

    if (inInterval) {
      if (restMs > 0 && overdueMs < restMs) {
        // Finished the interval, currently inside its rest phase.
        completedSets = 0;
        resumeInInterval = false;
        remainingMs = restMs - overdueMs;
      } else {
        // Finished the interval + its rest phase (1 completed set) plus any
        // additional full cycles.
        final int afterFirstRest = overdueMs - restMs;
        completedSets = 1 + (afterFirstRest ~/ cycleMs);
        final int remainder = afterFirstRest % cycleMs;
        if (restMs == 0 || remainder < intervalMs) {
          resumeInInterval = true;
          remainingMs = intervalMs - remainder;
        } else {
          resumeInInterval = false;
          remainingMs = restMs - (remainder - intervalMs);
        }
      }
    } else {
      // Finished the rest phase (1 completed set) plus any additional cycles.
      completedSets = 1 + (overdueMs ~/ cycleMs);
      final int remainder = overdueMs % cycleMs;
      if (restMs == 0 || remainder < intervalMs) {
        resumeInInterval = true;
        remainingMs = intervalMs - remainder;
      } else {
        resumeInInterval = false;
        remainingMs = restMs - (remainder - intervalMs);
      }
    }

    // Stop active timers cleanly without firing completion side effects.
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    sIntervalTimerRunning.value = false;
    restTimer.stopForAutoIntervalSync();

    // Log every round that finished while the app was suspended.
    for (int i = 0; i < completedSets; i++) {
      _recordCompletedSet();
    }

    // Keep sequence active and resume the exact current phase silently
    // (which also schedules a fresh batch of 64 iOS alerts).
    _isIntervalSequenceActive = true;
    if (resumeInInterval) {
      sElapsedIntervalTime.value = remainingMs.clamp(100, intervalMs);
      RestTimer.sElapsedRestTime.value = RestTimer.sInitialRestTime.value;
      unawaited(startTimer(silent: true));
    } else {
      sElapsedIntervalTime.value = intervalMs;
      final int remainingSec = (remainingMs / 1000).ceil().clamp(
        1,
        RestTimer.sInitialRestTime.value,
      );
      RestTimer.sElapsedRestTime.value = remainingSec;
      unawaited(restTimer.startTimer(silent: true));
    }
  }

  Future<void> pauseTimer() async {
    try {
      // Give a little bzzz.
      await HapticFeedback.lightImpact();

      // Cancel OS scheduled alert(s).
      unawaited(
        notificationService.cancelTimerAlert(
          NotificationService.intervalTimerNotificationId,
        ),
      );
      unawaited(notificationService.cancelAutoIntervalAlerts());

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

      // Cancel OS scheduled alert(s).
      unawaited(
        notificationService.cancelTimerAlert(
          NotificationService.intervalTimerNotificationId,
        ),
      );
      unawaited(notificationService.cancelAutoIntervalAlerts());

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
