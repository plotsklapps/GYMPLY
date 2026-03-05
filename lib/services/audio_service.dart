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

  /// Initializes the audio player and sets the native Android context.
  Future<void> initialize() async {
    if (_isInitialized) return;
    return _initFuture ??= _performInitialization();
  }

  Future<void> _performInitialization() async {
    try {
      _logger.i('AudioService: Initializing native Android audio context...');

      // Set audio context to Media/Music for maximum compatibility.
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      _isInitialized = true;
      _logger.i('AudioService: Initialized successfully.');
    } on Exception catch (e) {
      _logger.e('AudioService: Failed to initialize: $e');
      _isInitialized = false;
      _initFuture = null;
    }
  }

  /// Plays a sound from assets.
  Future<void> _playSound(String assetPath) async {
    try {
      // Always ensure initialization is complete before playing.
      await initialize();

      _logger.d('AudioService: Preparing to play $assetPath');

      // Stop current playback, set the source, and play.
      await _player.stop();
      await _player.setSource(AssetSource(assetPath));
      await _player.resume();

      _logger.d('AudioService: Playback started for $assetPath');
    } on Exception catch (e) {
      _logger.e('AudioService: Error playing sound: $e');
    }
  }

  /// Play the interval-completed sound.
  void playStartSound() {
    unawaited(_playSound('sounds/startsound.mp3'));
  }

  /// Play the rest-completed sound.
  void playRestSound() {
    unawaited(_playSound('sounds/timerbell.mp3'));
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await _player.dispose();
    _isInitialized = false;
    _initFuture = null;
  }
}
