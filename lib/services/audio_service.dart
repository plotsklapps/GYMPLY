import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

class AudioService {
  // Singleton pattern.
  factory AudioService() => _instance;
  AudioService._internal();
  static final AudioService _instance = AudioService._internal();

  final Logger _logger = Logger();

  AudioPlayer? _keepAlivePlayer;
  AudioPlayer? _fxPlayer;

  Future<void>? _initFuture;
  bool _isInitialized = false;

  /// Ensures audio players and context are initialized exactly once.
  /// This should be called on the very first user interaction (e.g., Start Button).
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Ensure only one initialization process runs at a time.
    return _initFuture ??= _performInitialization();
  }

  Future<void> _performInitialization() async {
    _logger.i('AudioService: Starting robust initialization...');
    try {
      _keepAlivePlayer = AudioPlayer();
      _fxPlayer = AudioPlayer();

      // Set audio context to duck other audio and handle backgrounding.
      final AudioContext ctx = AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      );

      await _keepAlivePlayer!.setAudioContext(ctx);
      await _fxPlayer!.setAudioContext(ctx);

      // 1. "Unlock" the AudioContext with a silent play.
      // This is the most critical part for PWAs.
      await _keepAlivePlayer!.setVolume(0);
      await _keepAlivePlayer!.play(AssetSource('sounds/onesecsilence.mp3'));

      // 2. Setup the silent keep-alive loop.
      await _keepAlivePlayer!.setReleaseMode(ReleaseMode.loop);

      _isInitialized = true;
      _logger.i('AudioService: Initialization complete and context unlocked.');
    } catch (e) {
      _logger.e('AudioService: Initialization failed: $e');
      _initFuture = null; // Allow retry.
    }
  }

  /// Internal helper to ensure FX player is ready for a specific sound.
  Future<void> _playFx(String assetPath) async {
    try {
      // Ensure we are initialized.
      await initialize();

      if (_fxPlayer == null) return;

      // Stop any current sound and reset for next.
      await _fxPlayer!.stop();
      await _fxPlayer!.setVolume(1.0);
      await _fxPlayer!.play(AssetSource(assetPath));
      _logger.d('AudioService: Playing FX: $assetPath');
    } catch (e) {
      _logger.w('AudioService: Playback blocked or failed: $e');
    }
  }

  /// Play the interval-completed sound (Non-blocking).
  void playStartSound() {
    unawaited(_playFx('sounds/startsound.mp3'));
  }

  /// Play the rest-completed sound (Non-blocking).
  void playRestSound() {
    unawaited(_playFx('sounds/timerbell.mp3'));
  }

  Future<void> dispose() async {
    await _keepAlivePlayer?.dispose();
    await _fxPlayer?.dispose();
    _isInitialized = false;
    _initFuture = null;
  }
}
