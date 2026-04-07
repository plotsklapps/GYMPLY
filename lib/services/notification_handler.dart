import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// Top-level entry point for the foreground service isolate.
@pragma('vm:entry-point')
void notificationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(NotificationHandler());
}

// Background TaskHandler — runs in the foreground service isolate.
class NotificationHandler extends TaskHandler {
  String _totalText = '00:00:00';
  String _segmentText = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Re-sync logic: If the main isolate hasn't sent data yet, it
    //defaults to 'Total'.
    final String body = _segmentText.isNotEmpty
        ? 'Total: $_totalText | $_segmentText'
        : 'Total: $_totalText';

    unawaited(FlutterForegroundTask.updateService(notificationText: body));
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    if (data is! Map<String, dynamic>) return;
    _totalText = data['total'] as String? ?? _totalText;
    _segmentText = data['segment'] as String? ?? '';
  }
}
