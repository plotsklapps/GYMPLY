import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

// Explains GYMPLY's background timer approach and requests the
// permissions needed to keep timers running reliably.
class PermissionModal extends StatelessWidget {
  const PermissionModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'BACKGROUND TIMERS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop cleanly.
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'GYMPLY. uses a foreground service to keep your timers '
            'accurate and audible even when the app is minimised or '
            'your screen is off.\n\n'
            'Android will ask for the following permissions:\n\n'
            '• Notification access - to display the live timer in your '
            'status bar and keep the timer running.\n\n'
            '• Physical Activity - required by Android to allow fitness '
            'apps to run these timers in the background.\n\n'
            'Allowing these does NOT change the fact that GYMPLY. is '
            'strictly offline-first. Your data never leaves your device, '
            'and no metrics are ever transmitted.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: FilledButton.tonal(
                onPressed: () async {
                  // 1. Request permissions (OS dialogs).
                  await <Permission>[
                    Permission.notification,
                    Permission.activityRecognition,
                  ].request();

                  // Close the modal.
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('UNDERSTOOD'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
