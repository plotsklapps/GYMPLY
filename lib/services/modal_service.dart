import 'package:flutter/material.dart';

// Service to show consistent modal sheets that return a bool (when needed).
class ModalService {
  static Future<bool> showModal({
    required BuildContext context,
    required Widget child,
    bool scrollable = false,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        // Keyboard and system gesture/navigation bar.
        final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

        final double bottomPadding = scrollable ? viewInsets.bottom + 16 : 16;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
          child: SafeArea(
            left: false,
            top: false,
            right: false,
            child: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        );
      },
    );
    return result ?? false;
  }
}
