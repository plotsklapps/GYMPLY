import 'dart:io';

import 'package:flutter/foundation.dart';
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

  // Track last sent payload so high-frequency ticks (e.g. 10ms stopwatch)
  // don't spam ActivityKit with identical update calls.
  int? _lastTotalStartTimeMs;
  String? _lastSegmentLabel;
  String? _lastSegmentDetail;
  int? _lastSegmentStartTimeMs;
  int? _lastSegmentEndTimeMs;
  int? _lastStaleDateMs;
  String? _lastExerciseName;

  Future<bool> areActivitiesEnabled() async {
    if (kIsWeb || !Platform.isIOS) return false;

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
    String? segmentDetail,
    DateTime? segmentStartTime,
    DateTime? segmentEndTime,
    DateTime? staleDate,
    String? exerciseName,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final int totalStartTimeMs = totalStartTime.millisecondsSinceEpoch;
      final int? segmentStartTimeMs = segmentStartTime?.millisecondsSinceEpoch;
      final int? segmentEndTimeMs = segmentEndTime?.millisecondsSinceEpoch;
      final int? staleDateMs = staleDate?.millisecondsSinceEpoch;

      final Map<String, dynamic> args = <String, dynamic>{
        'totalStartTimeMs': totalStartTimeMs,
        'segmentLabel': segmentLabel,
        'segmentDetail': segmentDetail,
        'segmentStartTimeMs': segmentStartTimeMs,
        'segmentEndTimeMs': segmentEndTimeMs,
        'staleDateMs': staleDateMs,
        'exerciseName': ?exerciseName,
      };

      await _channel.invokeMethod<bool>('startActivity', args);
      _isActivityActive = true;
      _lastTotalStartTimeMs = totalStartTimeMs;
      _lastSegmentLabel = segmentLabel;
      _lastSegmentDetail = segmentDetail;
      _lastSegmentStartTimeMs = segmentStartTimeMs;
      _lastSegmentEndTimeMs = segmentEndTimeMs;
      _lastStaleDateMs = staleDateMs;
      _lastExerciseName = exerciseName;
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
    required DateTime totalStartTime,
    required String segmentLabel,
    String? segmentDetail,
    DateTime? segmentStartTime,
    DateTime? segmentEndTime,
    DateTime? staleDate,
    String? exerciseName,
  }) async {
    if (kIsWeb || !Platform.isIOS || !_isActivityActive) return;

    final int totalStartTimeMs = totalStartTime.millisecondsSinceEpoch;
    final int? segmentStartTimeMs = segmentStartTime?.millisecondsSinceEpoch;
    final int? segmentEndTimeMs = segmentEndTime?.millisecondsSinceEpoch;
    final int? staleDateMs = staleDate?.millisecondsSinceEpoch;

    if (_lastTotalStartTimeMs == totalStartTimeMs &&
        _lastSegmentLabel == segmentLabel &&
        _lastSegmentDetail == segmentDetail &&
        _lastSegmentStartTimeMs == segmentStartTimeMs &&
        _lastSegmentEndTimeMs == segmentEndTimeMs &&
        _lastStaleDateMs == staleDateMs &&
        _lastExerciseName == exerciseName) {
      return;
    }

    try {
      final Map<String, dynamic> args = <String, dynamic>{
        'totalStartTimeMs': totalStartTimeMs,
        'segmentLabel': segmentLabel,
        'segmentDetail': segmentDetail,
        'segmentStartTimeMs': segmentStartTimeMs,
        'segmentEndTimeMs': segmentEndTimeMs,
        'staleDateMs': staleDateMs,
        'exerciseName': ?exerciseName,
      };

      await _channel.invokeMethod<bool>('updateActivity', args);
      _lastTotalStartTimeMs = totalStartTimeMs;
      _lastSegmentLabel = segmentLabel;
      _lastSegmentDetail = segmentDetail;
      _lastSegmentStartTimeMs = segmentStartTimeMs;
      _lastSegmentEndTimeMs = segmentEndTimeMs;
      _lastStaleDateMs = staleDateMs;
      _lastExerciseName = exerciseName;
    } on Object catch (e, stack) {
      _logger.e(
        'LiveActivityService: Failed to update activity',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> stopActivity() async {
    if (kIsWeb || !Platform.isIOS || !_isActivityActive) return;

    try {
      await _channel.invokeMethod<bool>('stopActivity');
      _isActivityActive = false;
      _lastTotalStartTimeMs = null;
      _lastSegmentLabel = null;
      _lastSegmentDetail = null;
      _lastSegmentStartTimeMs = null;
      _lastSegmentEndTimeMs = null;
      _lastStaleDateMs = null;
      _lastExerciseName = null;
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
