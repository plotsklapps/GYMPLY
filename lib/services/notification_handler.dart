import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Top-level entry point for the foreground service isolate.
@pragma('vm:entry-point')
void notificationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(NotificationHandler());
}

// Background TaskHandler — runs in the foreground service isolate.
class NotificationHandler extends TaskHandler {
  String _totalTime = '00:00:00';
  String _statusText = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'TOTAL TIME: $_totalTime',
        notificationText: _statusText,
      ),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map<String, dynamic>) return;

    // 1. Always update total time if present.
    if (data.containsKey('total')) {
      _totalTime = data['total'] as String? ?? _totalTime;
    }

    // 2. Update segment logic.
    // If the key is missing, we keep the previous _statusText (prevents flickering).
    if (data.containsKey('segmentLabel')) {
      final String? label = data['segmentLabel'] as String?;
      final String? time = data['segmentTime'] as String?;

      if (label != null && label.isNotEmpty) {
        if (time != null && time.isNotEmpty) {
          _statusText = '$label: $time';
        } else {
          _statusText = label;
        }
      } else {
        _statusText = '';
      }
    }
  }
}
