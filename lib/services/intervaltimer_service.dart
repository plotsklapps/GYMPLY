import 'dart:async';
import 'dart:convert';
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
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/signals/selectedexercise_signal.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
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
        } else {
          _activeExerciseId = null;
          unawaited(clearIOSBackgroundState());
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
          saveIOSBackgroundStateIfActive();
        } else if (_isIntervalSequenceActive &&
            RestTimer.sRestTimerRunning.value &&
            restTimer.endTime != null) {
          if (autoOn) {
            refreshBackgroundAlerts();
          } else {
            unawaited(_switchToSingleRestAlert());
          }
          saveIOSBackgroundStateIfActive();
        }
      });
    });
  }

  static const String _iosStateBoxName = 'ios_interval_state';
  static const String _iosStateKey = 'active_sequence';
  static const Duration _iosRecoveryMaxAge = Duration(hours: 3);
  static const int _iosKillRecoveryMaxSets = 32;

  void _recordCompletedSet() {
    WorkoutExercise? exercise;
    if (!kIsWeb && Platform.isIOS && _activeExerciseId != null) {
      for (final WorkoutExercise ex in sActiveWorkout.value.exercises) {
        if (ex.id == _activeExerciseId) {
          exercise = ex;
          break;
        }
      }
    }
    exercise ??= sSelectedExercise.value;

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

  Future<void> _scheduleSingleIntervalAlerts(DateTime intervalEndTime) async {
    if (kIsWeb || !Platform.isIOS) return;

    final DateTime now = DateTime.now();
    final int baseTotalSeconds = TotalTimer.sElapsedTotalTime.value;
    final bool isTotalRunning = TotalTimer.sTotalTimerRunning.value;
    final int restSec = RestTimer.sInitialRestTime.value;

    final int projectedIntervalTotal = isTotalRunning
        ? baseTotalSeconds +
              intervalEndTime.difference(now).inSeconds.clamp(0, 86400)
        : baseTotalSeconds;

    await notificationService.scheduleTimerAlert(
      id: NotificationService.intervalTimerNotificationId,
      scheduledDate: intervalEndTime,
      title: 'GYMPLY • INTERVAL FINISHED',
      body:
          'TOTAL TIME: ${projectedIntervalTotal.formatHMMSS()}\n'
          '${restSec > 0 ? 'Time to rest!' : 'Interval complete!'}',
    );

    if (restSec > 0) {
      final DateTime restEndTime = intervalEndTime.add(
        Duration(seconds: restSec),
      );
      final int projectedRestTotal = isTotalRunning
          ? baseTotalSeconds +
                restEndTime.difference(now).inSeconds.clamp(0, 86400)
          : baseTotalSeconds;

      await notificationService.scheduleTimerAlert(
        id: NotificationService.restTimerNotificationId,
        scheduledDate: restEndTime,
        title: 'GYMPLY • REST FINISHED',
        body:
            'TOTAL TIME: ${projectedRestTotal.formatHMMSS()}\n'
            'Interval complete!',
      );
    }
  }

  Future<void> _switchToSingleIntervalAlert() async {
    await notificationService.cancelAutoIntervalAlerts();
    if (!sIntervalTimerRunning.value || _endTime == null) return;
    await _scheduleSingleIntervalAlerts(_endTime!);
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
  int? _activeExerciseId;
  Box<String>? _iosStateBox;

  DateTime? get endTime => _endTime;
  bool get isIntervalSequenceActive => _isIntervalSequenceActive;
  bool get isAutoIntervalBatchManaged =>
      _isIntervalSequenceActive && sAutoIntervalOn.value;

  /// Called on iOS when the app moves to background
  /// (`AppLifecycleState.paused`). Stops Dart periodic timers cleanly (so
  /// overdue ticks cannot fire before `AppLifecycleState.resumed`), refreshes
  /// the 64 auto-interval alerts, and persists the active sequence snapshot to
  /// survive an OS kill.
  void onEnterBackground() {
    if (kIsWeb || !Platform.isIOS) return;

    _timer?.cancel();
    _timer = null;
    restTimer.suspendTickForIOSBackground();

    refreshBackgroundAlerts();
    saveIOSBackgroundStateIfActive();
  }

  /// Persists the active interval/rest sequence snapshot on iOS so completed
  /// sets can still be recovered if iOS terminates the suspended app.
  void saveIOSBackgroundStateIfActive() {
    if (kIsWeb || !Platform.isIOS) return;

    final bool inInterval = sIntervalTimerRunning.value && _endTime != null;
    final bool inRest =
        _isIntervalSequenceActive &&
        RestTimer.sRestTimerRunning.value &&
        restTimer.endTime != null;

    if (!inInterval && !inRest) return;

    final DateTime phaseEndTime = inInterval ? _endTime! : restTimer.endTime!;
    final int? exerciseId = _activeExerciseId ?? sSelectedExercise.value?.id;
    final String workoutId = sActiveWorkout.value.id;
    if (exerciseId == null) return;

    final Map<String, Object> payload = <String, Object>{
      'phaseEndTimeMs': phaseEndTime.millisecondsSinceEpoch,
      'inInterval': inInterval,
      'autoInterval': sAutoIntervalOn.value,
      'intervalMs': sInitialIntervalTime.value,
      'restSec': RestTimer.sInitialRestTime.value,
      'exerciseId': exerciseId,
      'workoutId': workoutId,
      'savedAtMs': DateTime.now().millisecondsSinceEpoch,
    };

    unawaited(_writeIOSStatePayload(jsonEncode(payload)));
  }

  Future<void> clearIOSBackgroundState() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final Box<String> box = await _openIOSStateBox();
      await box.delete(_iosStateKey);
    } on Object catch (e, stack) {
      _logger.e(
        'IntervalTimer: Failed to clear iOS background state',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<Box<String>> _openIOSStateBox() async {
    if (_iosStateBox != null && _iosStateBox!.isOpen) {
      return _iosStateBox!;
    }
    _iosStateBox = await Hive.openBox<String>(_iosStateBoxName);
    return _iosStateBox!;
  }

  Future<void> _writeIOSStatePayload(String encoded) async {
    try {
      final Box<String> box = await _openIOSStateBox();
      await box.put(_iosStateKey, encoded);
    } on Object catch (e, stack) {
      _logger.e(
        'IntervalTimer: Failed to save iOS background state',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Recovers an active interval sequence on iOS if the OS killed the app
  /// while it was suspended in the background.
  Future<void> restoreAfterOSKillIfNeeded() async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final Box<String> box = await _openIOSStateBox();
      final String? raw = box.get(_iosStateKey);
      if (raw == null || raw.isEmpty) return;

      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final int? phaseEndTimeMs = data['phaseEndTimeMs'] as int?;
      final bool? inInterval = data['inInterval'] as bool?;
      final bool? autoInterval = data['autoInterval'] as bool?;
      final int? intervalMs = data['intervalMs'] as int?;
      final int? restSec = data['restSec'] as int?;
      final int? exerciseId = data['exerciseId'] as int?;
      final String? workoutId = data['workoutId'] as String?;
      final int? savedAtMs = data['savedAtMs'] as int?;

      if (phaseEndTimeMs == null ||
          inInterval == null ||
          autoInterval == null ||
          intervalMs == null ||
          restSec == null ||
          exerciseId == null ||
          workoutId == null ||
          savedAtMs == null ||
          intervalMs <= 0) {
        await clearIOSBackgroundState();
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
      if (now.difference(savedAt) > _iosRecoveryMaxAge) {
        _logger.i('IntervalTimer: Saved iOS state expired, clearing.');
        await clearIOSBackgroundState();
        unawaited(notificationService.cancelAutoIntervalAlerts());
        return;
      }

      final Workout activeWorkout = sActiveWorkout.value;
      if (activeWorkout.id != workoutId) {
        await clearIOSBackgroundState();
        return;
      }

      WorkoutExercise? exercise;
      for (final WorkoutExercise ex in activeWorkout.exercises) {
        if (ex.id == exerciseId) {
          exercise = ex;
          break;
        }
      }
      if (exercise == null) {
        await clearIOSBackgroundState();
        return;
      }

      // Restore exercise context and configured durations.
      _activeExerciseId = exerciseId;
      sSelectedExercise.value = exercise;
      sInitialIntervalTime.value = intervalMs;
      RestTimer.sInitialRestTime.value = restSec;
      sAutoIntervalOn.value = autoInterval;
      _isIntervalSequenceActive = true;

      final DateTime phaseEndTime = DateTime.fromMillisecondsSinceEpoch(
        phaseEndTimeMs,
      );

      if (autoInterval) {
        _fastForwardAutoInterval(
          phaseEndTime: phaseEndTime,
          inInterval: inInterval,
          maxSetsCap: _iosKillRecoveryMaxSets,
        );
      } else {
        _recoverSingleInterval(
          phaseEndTime: phaseEndTime,
          inInterval: inInterval,
        );
      }

      _logger.i('IntervalTimer: Recovered iOS interval state after OS kill.');
    } on Object catch (e, stack) {
      _logger.e(
        'IntervalTimer: Failed to restore iOS state after OS kill',
        error: e,
        stackTrace: stack,
      );
      await clearIOSBackgroundState();
    }
  }

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
      _activeExerciseId = sSelectedExercise.value?.id;
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
        unawaited(_scheduleSingleIntervalAlerts(_endTime!));
      }

      saveIOSBackgroundStateIfActive();

      // Set a high-frequency timer (100ms) to support responsive updates.
      _startPeriodicTick();
      _logger.i('IntervalTimer: Started.');
    } on Object catch (e, stack) {
      // Log error.
      _logger.e('IntervalTimer: Failed to start', error: e, stackTrace: stack);
    }
  }

  void _startPeriodicTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (
      Timer timer,
    ) async {
      if (_endTime == null) return;

      final Duration remaining = _endTime!.difference(DateTime.now());
      final int remainingMs = remaining.inMilliseconds;

      if (remainingMs > 0) {
        sElapsedIntervalTime.value = remainingMs;
      } else {
        // On iOS, if this tick fired overdue while waking from background
        // suspension, delegate to syncOnResume() so all elapsed rounds are
        // logged instead of treating it as a single normal tick.
        if (!kIsWeb && Platform.isIOS) {
          final int overdueMs = -remainingMs;
          final bool isForeground =
              WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed;
          if (!isForeground || overdueMs > 2000) {
            syncOnResume();
            return;
          }
        }

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
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
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
  }

  /// Syncs timer state after returning from background.
  /// On iOS, returns true if an active interval sequence (interval or rest
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
        _fastForwardAutoInterval(
          phaseEndTime: inInterval ? _endTime! : restTimer.endTime!,
          inInterval: inInterval,
        );
        return true;
      }
    }

    if (!sIntervalTimerRunning.value || _endTime == null) return false;

    final DateTime now = DateTime.now();
    final Duration remaining = _endTime!.difference(now);
    final int remainingMs = remaining.inMilliseconds;

    if (remainingMs <= 0) {
      final DateTime finishedAt = _endTime!;
      _timer?.cancel();
      _timer = null;
      _endTime = null;
      sIntervalTimerRunning.value = false;
      sElapsedIntervalTime.value = 0;
      sIntervalTimerCompleted.value = true;
      sElapsedIntervalTime.value = sInitialIntervalTime.value;

      // On iOS, account for rest time already elapsed while the app was
      // suspended during a single interval (work + rest).
      if (!kIsWeb && Platform.isIOS) {
        _recoverSingleInterval(phaseEndTime: finishedAt, inInterval: true);
        return true;
      }

      unawaited(RestTimer().startTimer());
    } else {
      sElapsedIntervalTime.value = remainingMs;
      if (!kIsWeb && Platform.isIOS && _timer == null) {
        _startPeriodicTick();
      }
    }
    return false;
  }

  void _recoverSingleInterval({
    required DateTime phaseEndTime,
    required bool inInterval,
  }) {
    final DateTime now = DateTime.now();
    final int intervalMs = sInitialIntervalTime.value;
    final int restSec = RestTimer.sInitialRestTime.value;
    final int restMs = restSec * 1000;

    if (inInterval) {
      if (now.isBefore(phaseEndTime)) {
        final int remainingMs = phaseEndTime.difference(now).inMilliseconds;
        sElapsedIntervalTime.value = remainingMs.clamp(100, intervalMs);
        unawaited(startTimer(silent: true));
        return;
      }

      final int overdueMs = now.difference(phaseEndTime).inMilliseconds;
      if (restMs > 0 && overdueMs < restMs) {
        final int remainingRestSec = ((restMs - overdueMs) / 1000).ceil().clamp(
          1,
          restSec,
        );
        sElapsedIntervalTime.value = intervalMs;
        RestTimer.sElapsedRestTime.value = remainingRestSec;
        unawaited(restTimer.startTimer(silent: true));
        return;
      }
    } else if (now.isBefore(phaseEndTime)) {
      final int remainingRestSec =
          (phaseEndTime.difference(now).inMilliseconds / 1000).ceil().clamp(
            1,
            restSec,
          );
      sElapsedIntervalTime.value = intervalMs;
      RestTimer.sElapsedRestTime.value = remainingRestSec;
      unawaited(restTimer.startTimer(silent: true));
      return;
    }

    // Both interval and rest already completed in the background.
    _isIntervalSequenceActive = false;
    _recordCompletedSet();
    _activeExerciseId = null;
    restTimer.stopForAutoIntervalSync();
    sElapsedIntervalTime.value = intervalMs;
    RestTimer.sElapsedRestTime.value = restSec;
    unawaited(clearIOSBackgroundState());
    unawaited(
      notificationService.cancelTimerAlert(
        NotificationService.intervalTimerNotificationId,
      ),
    );
    unawaited(
      notificationService.cancelTimerAlert(
        NotificationService.restTimerNotificationId,
      ),
    );
  }

  void _fastForwardAutoInterval({
    required DateTime phaseEndTime,
    required bool inInterval,
    int? maxSetsCap,
  }) {
    final DateTime now = DateTime.now();

    // Still inside the same phase: update display, restart tick if suspended,
    // and refill all 64 iOS alerts.
    if (now.isBefore(phaseEndTime)) {
      final Duration remaining = phaseEndTime.difference(now);
      if (inInterval) {
        sElapsedIntervalTime.value = remaining.inMilliseconds.clamp(
          100,
          sInitialIntervalTime.value,
        );
        if (sIntervalTimerRunning.value) {
          if (_timer == null) _startPeriodicTick();
          refreshBackgroundAlerts();
        } else {
          unawaited(startTimer(silent: true));
        }
      } else {
        RestTimer.sElapsedRestTime.value = (remaining.inMilliseconds / 1000)
            .ceil()
            .clamp(1, RestTimer.sInitialRestTime.value);
        if (RestTimer.sRestTimerRunning.value) {
          restTimer.resumeTickForIOSForeground();
          refreshBackgroundAlerts();
        } else {
          unawaited(restTimer.startTimer(silent: true));
        }
      }
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

    if (maxSetsCap != null && completedSets > maxSetsCap) {
      completedSets = maxSetsCap;
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
    // (which also schedules a fresh batch of 64 iOS alerts and saves state).
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
      if (!kIsWeb && Platform.isIOS) {
        unawaited(
          notificationService.cancelTimerAlert(
            NotificationService.restTimerNotificationId,
          ),
        );
        unawaited(clearIOSBackgroundState());
      }
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
      _activeExerciseId = null;

      // Give a bigger bzzz.
      await HapticFeedback.mediumImpact();

      // Cancel OS scheduled alert(s).
      unawaited(
        notificationService.cancelTimerAlert(
          NotificationService.intervalTimerNotificationId,
        ),
      );
      if (!kIsWeb && Platform.isIOS) {
        unawaited(
          notificationService.cancelTimerAlert(
            NotificationService.restTimerNotificationId,
          ),
        );
        unawaited(clearIOSBackgroundState());
      }
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
