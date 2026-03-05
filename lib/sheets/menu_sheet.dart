import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:signals/signals_flutter.dart';
import 'package:web/web.dart' as web;

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final bool isDarkMode = sDarkMode.watch(context);

    Future<void> updateApp() async {
      // Get the Service Worker registration.
      // Convert the JSPromise .toDart Future.
      final web.ServiceWorkerRegistration? registration = await web
          .window
          .navigator
          .serviceWorker
          .getRegistration()
          .toDart;

      if (registration != null) {
        // Trigger manual update check on Service Worker.
        // Convert the JSPromise .toDart Future again.
        await registration.update().toDart;
      }

      // Ctrl + F5 the PWA.
      web.window.location.reload();
    }

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
          ListTile(
            onTap: updateApp,
            leading: const FaIcon(FontAwesomeIcons.github),
            title: const Text('Current Version: 0.0.1+3 TEST2'),
            subtitle: const Text('Deployed 20260305'),
            trailing: const FaIcon(FontAwesomeIcons.arrowsRotate),
          ),
        ],
      ),
    );
  }
}
