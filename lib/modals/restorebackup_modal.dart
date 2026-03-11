import 'package:flutter/material.dart';

class RestoreBackupModal extends StatelessWidget {
  const RestoreBackupModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('Restore Backup'),
        const Divider(),
        const Text(
          'This will overwrite all current data. This action '
          'cannot be undone.',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('RESTORE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
