import 'package:flutter/material.dart';

// Service to show consistent modal sheets that return a bool (when needed).
class ModalService {
  static Future<bool> showModal({
    required BuildContext context,
    required Widget child,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        // Keyboard and system gesture/navigation bar.
        final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, viewInsets.bottom + 16),
          child: SafeArea(
            left: false,
            top: false,
            right: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: child,
            ),
          ),
        );
      },
    );
    return result ?? false;
  }
}
