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
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      context: context,
      builder: (BuildContext context) {
        // Keeps bottom modal above OS navigation (gesture or buttons).
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        );
      },
    );
    return result ?? false;
  }
}
