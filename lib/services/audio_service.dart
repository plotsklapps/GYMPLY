import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioService {
  // Create a singleton instance of AudioService.
  factory AudioService() {
    return _instance;
  }
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();

  AudioPlayer? _silentPlayer; // Keeps AudioContext alive.
  AudioPlayer? _fxPlayer; // Plays actual sounds.

  bool _isPrimed = false;
  bool _isSilentLoopRunning = false;

  // Initialize both players + AudioContext.
  Future<void> _init() async {
    if (_silentPlayer != null && _fxPlayer != null) return;

    _silentPlayer = AudioPlayer();
    _fxPlayer = AudioPlayer();

    // Shared audio context for both players.
    final AudioContext ctx = AudioContext(
      android: const AudioContextAndroid(
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    );

    await _silentPlayer!.setAudioContext(ctx);
    await _fxPlayer!.setAudioContext(ctx);
  }

  // Prime the audio context so Chrome/Firefox/Edge do not suspend it.
  Future<void> _prime() async {
    if (_isPrimed || _fxPlayer == null) return;

    // Silent prime sequence.
    unawaited(_fxPlayer!.setVolume(0));
    unawaited(_fxPlayer!.play(AssetSource('sounds/startsound.mp3')));
    unawaited(_fxPlayer!.stop());
    unawaited(_fxPlayer!.setVolume(1));

    _isPrimed = true;
  }

  // Start a silent loop to keep the AudioContext alive.
  Future<void> _startSilentLoop() async {
    if (_isSilentLoopRunning || _silentPlayer == null) return;

    await _silentPlayer!.setVolume(0);
    await _silentPlayer!.setReleaseMode(ReleaseMode.loop);

    // Play silent audio forever.
    unawaited(
      _silentPlayer!.play(
        AssetSource('sounds/onesecsilence.mp3'),
      ),
    );

    _isSilentLoopRunning = true;
  }

  // Prepare the FX player before each sound.
  Future<void> _prepareFxPlayer() async {
    if (_fxPlayer == null) return;

    // Reset FX player state.
    // ignore: unawaited_futures
    _fxPlayer!.stop();
    await _fxPlayer!.setVolume(1);
    await _fxPlayer!.setReleaseMode(ReleaseMode.stop);
  }

  // Internal helper to ensure everything is ready before each play.
  Future<void> _prepare() async {
    await _init();
    await _prime();
    await _startSilentLoop();
    await _prepareFxPlayer();
  }

  // Play the interval-completed sound.
  Future<void> playStartSound() async {
    await _prepare();
    unawaited(_fxPlayer?.play(AssetSource('sounds/startsound.mp3')));
  }

  // Play the rest-completed sound.
  Future<void> playRestSound() async {
    await _prepare();
    unawaited(_fxPlayer?.play(AssetSource('sounds/timerbell.mp3')));
  }

  // Optional: dispose if needed (not required for PWA).
  Future<void> dispose() async {
    await _silentPlayer?.dispose();
    await _fxPlayer?.dispose();

    _silentPlayer = null;
    _fxPlayer = null;

    _isPrimed = false;
    _isSilentLoopRunning = false;
  }
}
