import 'package:flutter/material.dart';

// Service to show consistent modal sheets that return a bool.
class ModalService {
  static Future<bool> showModal({
    required BuildContext context,
    required Widget child,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
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
    return result ?? false;
  }
}
