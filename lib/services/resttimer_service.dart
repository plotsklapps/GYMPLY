import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:gymply/services/haptic_service.dart';
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
  AudioPlayer? _audioPlayer;

  Future<void> startTimer() async {
    // Immediate guard to prevent concurrent timers during async gaps.
    if (_timer != null || sRestTimerRunning.value) return;

    sRestTimerRunning.value = true;
    sRestTimerCompleted.value = false;

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

    // Give a little bzzz.
    await HapticService.light();

    // Calculate when the timer should end.
    _endTime = DateTime.now().add(Duration(seconds: sElapsedRestTime.value));

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (_endTime == null) return;

      final Duration remaining = _endTime!.difference(DateTime.now());
      final int remainingSeconds = remaining.inSeconds;

      if (remainingSeconds > 0) {
        sElapsedRestTime.value = remainingSeconds;
      } else {
        // Stop timer immediately.
        _timer?.cancel();
        _timer = null;
        _endTime = null;
        sRestTimerRunning.value = false;

        sElapsedRestTime.value = 0;

        // Play audio.
        await _audioPlayer?.play(AssetSource('sounds/timerbell.mp3'));

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

  // Resets Timer state and cleans up Audioplayer.
  Future<void> resetTimer() async {
    // Give a bigger bzzz.
    await HapticService.heavy();

    _timer?.cancel();
    _timer = null;
    _endTime = null;

    // Kill Audioplayer.
    await _audioPlayer?.dispose();
    _audioPlayer = null;

    sElapsedRestTime.value = sInitialRestTime.value;
    sRestTimerRunning.value = false;
    sRestTimerCompleted.value = false;
  }
}
