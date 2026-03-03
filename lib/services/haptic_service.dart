import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

@JS('navigator.vibrate')
external bool _vibrate(JSAny pattern);

class HapticService {
  /// Triggers a light haptic feedback.
  static Future<void> light() async {
    if (kIsWeb) {
      try {
        // On web, we use the Vibration API. 10ms is a light tap.
        _vibrate(10.toJS);
      } catch (_) {
        // Fail silently if not supported.
      }
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Triggers a heavy haptic feedback.
  static Future<void> heavy() async {
    if (kIsWeb) {
      try {
        // On web, we use the Vibration API. 50ms is a heavier tap.
        _vibrate(50.toJS);
      } catch (_) {
        // Fail silently if not supported.
      }
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
}
