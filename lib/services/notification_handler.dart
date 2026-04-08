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
  String _segmentBody = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Show total always, segment only if it has content.
    final String body = _segmentBody.isNotEmpty
        ? 'TOTAL: $_totalTime | $_segmentBody'
        : 'TOTAL: $_totalTime';

    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'GYMPLY.',
        notificationText: body,
      ),
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map<String, dynamic>) return;

    // 1. Always update total time if present
    if (data.containsKey('total')) {
      _totalTime = data['total'] as String? ?? _totalTime;
    }

    // 2. Update segment logic
    final String? label = data['segmentLabel'] as String?;
    final String? time = data['segment'] as String?;

    if (label != null) {
      if (time != null && time.isNotEmpty) {
        _segmentBody = '$label: $time';
      } else {
        _segmentBody = label;
      }
    } else {
      _segmentBody = '';
    }
  }
}
