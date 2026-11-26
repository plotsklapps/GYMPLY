import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class AudioService {
  // Singleton pattern.
  factory AudioService() {
    return _instance;
  }

  AudioService._internal();
  static final AudioService _instance = AudioService._internal();

  static const MethodChannel _iosAudioChannel = MethodChannel(
    'dev.plotsklapps.gymply/audio',
  );

  final Logger _logger = Logger();
  final AudioPlayer _player = AudioPlayer();

  bool _isInitialized = false;
  Future<void>? _initFuture;

  // Initializes audioplayer and sets Android context.
  Future<void> initialize() async {
    if (_isInitialized) return;
    return await (_initFuture ??= _performInitialization());
  }

  Future<void> _performInitialization() async {
    // On iOS, native AVAudioPlayer handles timerbell playback and ducking on
    // demand so Spotify/Apple Music is never ducked before a bell actually
    // plays and always unducks cleanly via notifyOthersOnDeactivation.
    if (!kIsWeb && Platform.isIOS) {
      _isInitialized = true;
      return;
    }

    try {
      _logger.i('AudioService: Initializing native Android audio context...');

      // Make phone audio duck on Android.
      if (!kIsWeb) {
        await _player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        );
      }

      // Keep player intact after sound completes so audio tail is not clipped.
      await _player.setReleaseMode(ReleaseMode.stop);

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

    // On iOS, delegate to native AVAudioPlayer so AVAudioSession activates
    // with duckOthers for the bell and immediately deactivates with
    // notifyOthersOnDeactivation when the bell finishes.
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _iosAudioChannel.invokeMethod<bool>('playTimerBell');
        _logger.i('AudioService: Native iOS timerbell playback started.');
      } on Object catch (e) {
        _logger.e('AudioService: Error playing native iOS sound: $e');
      }
      return;
    }

    try {
      // Always ensure initialization is complete before playing.
      await initialize();

      // Play sound directly from AssetSource.
      await _player.play(AssetSource(assetPath));

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
