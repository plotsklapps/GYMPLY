import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

// Enables touch, mouse, trackpad, and stylus drag scrolling across all devices.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices {
    return const <PointerDeviceKind>{
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
      PointerDeviceKind.unknown,
    };
  }
}

const AppScrollBehavior appScrollBehavior = AppScrollBehavior();
