import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  // Create a singleton instance of AudioService.
  factory AudioService() {
    return _instance;
  }
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();

  AudioPlayer? _player;
  bool _isPrimed = false;

  // Initialize the shared AudioPlayer + AudioContext.
  Future<void> _init() async {
    if (_player != null) return;

    _player = AudioPlayer();

    await _player!.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
  }

  // Prime the audio context so Chrome/Firefox/Edge do not suspend it.
  Future<void> _prime() async {
    if (_isPrimed || _player == null) return;

    // Silent prime sequence.
    unawaited(_player!.setVolume(0));
    unawaited(_player!.play(AssetSource('sounds/startsound.mp3')));
    unawaited(_player!.stop());
    unawaited(_player!.setVolume(1));

    _isPrimed = true;
  }

  // Internal helper to ensure the player is ready before each play.
  Future<void> _prepare() async {
    await _init();
    await _prime();

    // Reset state before each play.
    await _player?.stop();
  }

  // Play the interval-completed sound.
  Future<void> playStartSound() async {
    await _prepare();
    unawaited(_player?.play(AssetSource('sounds/startsound.mp3')));
  }

  // Play the rest-completed sound.
  Future<void> playRestSound() async {
    await _prepare();
    unawaited(_player?.play(AssetSource('sounds/timerbell.mp3')));
  }

  // Optional: dispose if needed (not required for PWA).
  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _isPrimed = false;
  }
}
