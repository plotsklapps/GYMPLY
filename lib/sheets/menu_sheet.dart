import 'package:flutter/material.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:signals/signals_flutter.dart';

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final bool isDarkMode = sDarkMode.watch(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'MENU',
            style: theme.textTheme.titleLarge,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Theme Mode'),
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            value: isDarkMode,
            onChanged: (bool value) {
              sDarkMode.value = value;
            },
          ),
        ],
      ),
    );
  }
}
