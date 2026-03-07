import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';

class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final bool isDarkMode = sDarkMode.watch(context);
    final bool isWakelock = sWakelock.watch(context);
    final bool isChecking = UpdateService().sIsCheckingForUpdate.watch(context);
    final double progress = UpdateService().sDownloadProgress.watch(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('MENU', style: theme.textTheme.titleLarge),
          const Divider(),
          SwitchListTile(
            title: isWakelock
                ? const Text('Keep screen on')
                : const Text('Use screensaver'),
            subtitle: isWakelock
                ? const Text('Prevent screen from turning off')
                : const Text('Screen will automatically turn off'),
            secondary: FaIcon(
              isWakelock
                  ? FontAwesomeIcons.mobile
                  : FontAwesomeIcons.mobileScreen,
            ),
            value: isWakelock,
            onChanged: (bool value) {
              sWakelock.value = value;
            },
          ),
          SwitchListTile(
            title: isDarkMode
                ? const Text('Use dark mode')
                : const Text('Use light mode'),
            subtitle: isDarkMode ? const Text('Dark theme for all screens') :
            const Text('Light theme for all screens'),
            secondary: FaIcon(
              isDarkMode ? FontAwesomeIcons.solidMoon : FontAwesomeIcons.sun,
            ),
            value: isDarkMode,
            onChanged: (bool value) {
              sDarkMode.value = value;
            },
          ),
          if (progress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(value: progress),
            ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder:
                (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                  final String versionDisplay = snapshot.hasData
                      ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                      : 'Checking...';

                  return ListTile(
                    onTap: isChecking
                        ? null
                        : () {
                            UpdateService().checkForUpdates();
                          },
                    leading: isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const FaIcon(FontAwesomeIcons.arrowsRotate),
                    title: const Text('Check for Updates'),
                    subtitle: Text('Current Version: $versionDisplay'),
                    trailing: const FaIcon(FontAwesomeIcons.chevronRight),
                  );
                },
          ),
          const ListTile(
            leading: FaIcon(FontAwesomeIcons.github),
            title: Text('Source Code'),
            subtitle: Text('GitHub Repository'),
          ),
        ],
      ),
    );
  }
}
