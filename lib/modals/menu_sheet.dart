import 'package:flutter/material.dart';
import 'package:gymply/services/backup_service.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
            secondary: Icon(
              isWakelock
                  ? LucideIcons.smartphoneCharging
                  : LucideIcons.smartphone,
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
            subtitle: isDarkMode
                ? const Text('Dark theme for all screens')
                : const Text('Light theme for all screens'),
            secondary: Icon(
              isDarkMode ? LucideIcons.moon : LucideIcons.sun,
            ),
            value: isDarkMode,
            onChanged: (bool value) {
              sDarkMode.value = value;
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.save),
            title: const Text('Backup Data'),
            subtitle: const Text('Save your workout history to a .zip file'),
            onTap: () async {
              await backupService.backupData(context);
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.fileUp),
            title: const Text('Restore Data'),
            subtitle: const Text('Load data from a previous backup'),
            onTap: () async {
              await backupService.restoreData(context);
            },
          ),
          const Divider(),
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
                        : () async {
                            await UpdateService().checkForUpdates();
                          },
                    leading: isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.cloudSync),
                    title: const Text('Check for Updates'),
                    subtitle: Text('Current Version: $versionDisplay'),
                    trailing: const Icon(LucideIcons.chevronRight),
                  );
                },
          ),
          const ListTile(
            leading: Icon(LucideIcons.github),
            title: Text('Source Code'),
            subtitle: Text('GitHub Repository'),
          ),
        ],
      ),
    );
  }
}
