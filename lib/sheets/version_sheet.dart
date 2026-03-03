import 'package:flutter/material.dart';

class VersionSheet extends StatelessWidget {
  const VersionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'VERSION',
              style: theme.textTheme.titleLarge,
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
