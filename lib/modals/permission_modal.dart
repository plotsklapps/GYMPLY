import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:gymply/services/foreground_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Explains GYMPLY's background timer approach and requests the two Android
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
            'Android will ask for two permissions:\n\n'
            '• Notification access — to display the live timer in your '
            'status bar.\n\n'
            '• Allow unrestricted battery usage — this is ESSENTIAL for '
            'timer accuracy and to ensure alarms play when the screen '
            'is locked.\n\n'
            'Allowing this does NOT change the fact that GYMPLY. is '
            'strictly offline-first. Your data never leaves your device, '
            'and no metrics are ever transmitted — ever.',
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
                  // 1. Request notification permission (OS dialog).
                  await FlutterForegroundTask.requestNotificationPermission();

                  // 2. Request battery optimisation ignore (opens Settings).
                  //    Only run on Android — platform-specific behaviour.
                  if (Platform.isAndroid) {
                    await ForegroundService.requestBatteryOptimization();
                  }

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
