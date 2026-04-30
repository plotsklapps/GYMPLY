import 'package:flutter/material.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ImportKeysModal extends StatelessWidget {
  const ImportKeysModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextEditingController keyController = TextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),
                const Text(
                  'Enter your npub for read-only or nsec for full access.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'npub or nsec',
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
                          final String input = keyController.text.trim();
                          final bool success = await nostrService
                              .useExistingKeys(input);
                          if (context.mounted) {
                            Navigator.pop(context, success);
                          }
                        },
                        child: const Text('IMPORT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
