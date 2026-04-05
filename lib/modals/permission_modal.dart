import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

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
            'GYMPLY. uses local notifications so your '
            'timers can reliably play their custom alarm sounds even '
            'while the app is running in the background.\n\n'
            'This operates 100% offline, securely on your device, and '
            'never tracks or transmits any personal data anywhere.',
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
                  // Request OS permission then close modal
                  await Permission.notification.request();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('UNDERSTOOD'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
