import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/haptic_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:signals/signals_flutter.dart';

class IntervalTimer {
  // Create a singleton instance of IntervalTimer.
  factory IntervalTimer() {
    return _instance;
  }

  IntervalTimer._internal() {
    effect(() async {
      final bool isRestDone = RestTimer.sRestTimerCompleted.value;

      if (isRestDone && _isIntervalSequenceActive) {
        // 1. Immediately prevent re-entry.
        _isIntervalSequenceActive = false;

        final WorkoutExercise? exercise =
            workoutService.sSelectedExercise.value;

        if (exercise is CardioExercise) {
          workoutService.addCardioSet(
            exercise,
            cardioDuration: Duration(seconds: sInitialIntervalTime.value),
            restDuration: Duration(seconds: RestTimer.sInitialRestTime.value),
            totalDuration: Duration(
              seconds:
                  sInitialIntervalTime.value + RestTimer.sInitialRestTime.value,
            ),
          );
        }

        // 2. Reset the signal.
        RestTimer.sRestTimerCompleted.value = false;

        // 3. Auto-restart if enabled.
        if (sAutoIntervalOn.value) {
          await startTimer();
        }
      }
    });
  }

  bool _isIntervalSequenceActive = false;

  static final IntervalTimer _instance = IntervalTimer._internal();

  // Signals.
  static final Signal<int> sInitialIntervalTime = Signal<int>(
    60,
    debugLabel: 'sInitialIntervalTime',
  );

  static final Signal<int> sElapsedIntervalTime = Signal<int>(
    60,
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

  Timer? _timer;
  DateTime? _endTime;
  AudioPlayer? _audioPlayer;

  Future<void> startTimer() async {
    // Synchronous check to prevent multiple timers.
    if (_timer != null || sIntervalTimerRunning.value) return;

    _isIntervalSequenceActive = true;
    sIntervalTimerRunning.value = true;
    sIntervalTimerCompleted.value = false;

    // Initialize AudioPlayer.
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    }

    await HapticService.light();

    // Calculate when the interval should end.
    _endTime = DateTime.now().add(
      Duration(seconds: sElapsedIntervalTime.value),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (_endTime == null) return;

      final Duration remaining = _endTime!.difference(DateTime.now());
      final int remainingSeconds = remaining.inSeconds;

      if (remainingSeconds > 0) {
        sElapsedIntervalTime.value = remainingSeconds;
      } else {
        // Stop this timer immediately.
        _timer?.cancel();
        _timer = null;
        _endTime = null;
        sIntervalTimerRunning.value = false;

        sElapsedIntervalTime.value = 0;

        // Play audio.
        await _audioPlayer?.play(AssetSource('sounds/startsound.mp3'));

        // Wait to finish before clean up or allow re-start.
        await Future<void>.delayed(const Duration(milliseconds: 500));

        sIntervalTimerCompleted.value = true;
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

    await _audioPlayer?.dispose();
    _audioPlayer = null;

    sElapsedIntervalTime.value = sInitialIntervalTime.value;
    sIntervalTimerRunning.value = false;
    sIntervalTimerCompleted.value = false;
  }
}
