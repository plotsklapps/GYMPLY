import 'package:flutter/material.dart';

// Service to show consistent modal sheets that return a bool.
class ModalService {
  static Future<bool> showModal({
    required BuildContext context,
    required Widget child,
    bool scrollable = true,
  }) async {
    final bool? result = await showModalBottomSheet<bool>(
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: scrollable ? SingleChildScrollView(child: child) : child,
        );
      },
    );
    return result ?? false;
  }
}
