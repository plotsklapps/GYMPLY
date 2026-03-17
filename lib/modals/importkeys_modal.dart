import 'package:flutter/material.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:toastification/toastification.dart';

class ImportKeysModal extends StatelessWidget {
  const ImportKeysModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextEditingController controller = TextEditingController();

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'IMPORT KEYS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Enter your nsec for full access or npub for watch-only mode.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'nsec or npub',
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Pop and return false.
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  final String input = controller.text.trim();
                  final bool success = await nostrService.useExistingKeys(
                    input,
                  );
                  if (context.mounted) {
                    Navigator.pop(context, success);
                    if (success) {
                      toastification.show(
                        context: context,
                        type: ToastificationType.success,
                        title: const Text('Keys Imported!'),
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                    } else {
                      toastification.show(
                        context: context,
                        type: ToastificationType.error,
                        title: const Text('Invalid Key!'),
                        description: const Text(
                          'Please check your npub or nsec.',
                        ),
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                    }
                  }
                },
                child: const Text('IMPORT'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
