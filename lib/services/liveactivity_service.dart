import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class LiveActivityService {
  factory LiveActivityService() {
    return _instance;
  }

  LiveActivityService._internal();
  static final LiveActivityService _instance = LiveActivityService._internal();

  final Logger _logger = Logger();
  static const MethodChannel _channel = MethodChannel(
    'dev.plotsklapps.gymply/live_activity',
  );

  bool _isActivityActive = false;
  bool get isActivityActive => _isActivityActive;

  Future<bool> areActivitiesEnabled() async {
    if (!Platform.isIOS) return false;

    try {
      final bool? enabled = await _channel.invokeMethod<bool>(
        'areActivitiesEnabled',
      );
      return enabled ?? false;
    } on Object catch (e, stack) {
      _logger.e(
        'LiveActivityService: areActivitiesEnabled failed',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }

  Future<void> startActivity({
    required DateTime totalStartTime,
    required String segmentLabel,
    DateTime? segmentEndTime,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final Map<String, dynamic> args = <String, dynamic>{
        'totalStartTimeMs': totalStartTime.millisecondsSinceEpoch,
        'segmentLabel': segmentLabel,
        'segmentEndTimeMs': segmentEndTime?.millisecondsSinceEpoch,
      };

      await _channel.invokeMethod<bool>('startActivity', args);
      _isActivityActive = true;
      _logger.i('LiveActivityService: Activity started successfully.');
    } on Object catch (e, stack) {
      _logger.e(
        'LiveActivityService: Failed to start activity',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> updateActivity({
    required String segmentLabel,
    DateTime? segmentEndTime,
  }) async {
    if (!Platform.isIOS || !_isActivityActive) return;

    try {
      final Map<String, dynamic> args = <String, dynamic>{
        'segmentLabel': segmentLabel,
        'segmentEndTimeMs': segmentEndTime?.millisecondsSinceEpoch,
      };

      await _channel.invokeMethod<bool>('updateActivity', args);
    } on Object catch (e, stack) {
      _logger.e(
        'LiveActivityService: Failed to update activity',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> stopActivity() async {
    if (!Platform.isIOS || !_isActivityActive) return;

    try {
      await _channel.invokeMethod<bool>('stopActivity');
      _isActivityActive = false;
      _logger.i('LiveActivityService: Activity stopped.');
    } on Object catch (e, stack) {
      _logger.e(
        'LiveActivityService: Failed to stop activity',
        error: e,
        stackTrace: stack,
      );
    }
  }
}

final LiveActivityService liveActivityService = LiveActivityService();
