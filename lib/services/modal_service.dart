import 'package:flutter/material.dart';

// Service to show consistent modal sheets that return a bool (when needed).
class ModalService {
  static Future<bool> showModal({
    required BuildContext context,
    required Widget child,
    bool scrollable = true,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
      showDragHandle: true,
      isScrollControlled: true,
      // Keeps top modal below status bar.
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height,
        minHeight: MediaQuery.sizeOf(context).height,
      ),
      context: context,
      builder: (BuildContext context) {
        // Keeps bottom modal above OS navigation (gesture or buttons).
        return SafeArea(
          top: false,
          child: child,
        );
      },
    );
    return result ?? false;
  }
}
