import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Shows a bottom sheet to choose between Camera and Gallery.
Future<ImageSource?> addImageModal(BuildContext context) async {
  final ThemeData theme = Theme.of(context);

  return showModalBottomSheet<ImageSource>(
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: SafeArea(
          left: false,
          top: false,
          right: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Empty SizedBox to balance Icon and Text.
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'ADD PHOTO',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Pop and return false.
                        Navigator.pop(context);
                      },
                      icon: const Icon(LucideIcons.circleX),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(LucideIcons.image),
                          title: const Text('Photo Library'),
                          onTap: () {
                            // Pop and return gallery.
                            Navigator.of(context).pop(ImageSource.gallery);
                          },
                          trailing: const Icon(LucideIcons.circleChevronRight),
                        ),
                        ListTile(
                          leading: const Icon(LucideIcons.camera),
                          title: const Text('(Selfie) Camera'),
                          onTap: () {
                            // Pop and return camera.
                            Navigator.of(context).pop(ImageSource.camera);
                          },
                          trailing: const Icon(LucideIcons.circleChevronRight),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
