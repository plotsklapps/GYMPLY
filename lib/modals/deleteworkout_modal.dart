import 'package:flutter/material.dart';

class DeleteWorkoutModal extends StatelessWidget {
  const DeleteWorkoutModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('Delete Workout'),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Are you sure you want to delete this workout? '
          'This action cannot be undone.',
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
                onPressed: () {
                  // Pop and return true.
                  Navigator.pop(context, true);
                },
                child: const Text('DELETE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
