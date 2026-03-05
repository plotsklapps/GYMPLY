import 'dart:ui';

import 'package:flutter/material.dart';

class ScrollService extends StatelessWidget {
  const ScrollService({
    required this.child,
    required this.scrollDirection,
    super.key,
  });

  final Widget child;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: <PointerDeviceKind>{
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: scrollDirection,
        child: child,
      ),
    );
  }
}
