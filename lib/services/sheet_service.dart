import 'package:flutter/material.dart';
import 'package:gymply/services/scroll_service.dart';

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
          child: ScrollService(scrollDirection: Axis.vertical, child: child),
        );
      },
    );
  }
}
