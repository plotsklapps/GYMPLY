import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';

class AudioService {
  // Singleton pattern.
  factory AudioService() {
    return _instance;
  }

  AudioService._internal();
  static final AudioService _instance = AudioService._internal();

  final Logger _logger = Logger();
  final AudioPlayer _player = AudioPlayer();

  bool _isInitialized = false;
  Future<void>? _initFuture;

  /// Initializes audioplayer and sets Android context.
  Future<void> initialize() async {
    if (_isInitialized) return;
    return _initFuture ??= _performInitialization();
  }

  Future<void> _performInitialization() async {
    try {
      _logger.i('AudioService: Initializing native Android audio context...');

      // Make phone audio 'duck' GYMPLY sounds.
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      _isInitialized = true;

      // Log success.
      _logger.i('AudioService: Initialized successfully.');
    } on Exception catch (e) {
      // Log error.
      _logger.e('AudioService: Failed to initialize: $e');

      // Reset variables.
      _isInitialized = false;
      _initFuture = null;
    }
  }

  // Play sound from assets.
  Future<void> playTimerBell() async {
    const String assetPath = 'sounds/timerbell.wav';

    try {
      // Always ensure initialization is complete before playing.
      await initialize();

      // Stop current playback -> set source -> play.
      await _player.stop();
      await _player.setSource(AssetSource(assetPath));
      await _player.resume();

      // Log success.
      _logger.i('AudioService: Playback started for $assetPath');
    } on Exception catch (e) {
      // Log error.
      _logger.e('AudioService: Error playing sound: $e');
    }
  }

  // Clean up and kill.
  Future<void> dispose() async {
    await _player.dispose();
    _isInitialized = false;
    _initFuture = null;
  }
}
