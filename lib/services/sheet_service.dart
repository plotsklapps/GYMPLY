import 'package:flutter/material.dart';

class SheetService {
  static Future<void> showSheet({
    required BuildContext context,
    required Widget child,
  }) async {
    await showModalBottomSheet<void>(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: SingleChildScrollView(child: child),
        );
      },
    );
  }
}
