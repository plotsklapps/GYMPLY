import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:gymply/services/backup_service.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuModal extends StatelessWidget {
  const MenuModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final bool isDarkMode = sDarkMode.watch(context);
    final bool isWakelock = sWakelock.watch(context);
    final FlexScheme flexScheme = sFlexScheme.watch(context);

    // Update Signals.
    final bool isChecking = UpdateService().sIsCheckingForUpdate.watch(context);
    final double updateProgress = UpdateService().sDownloadProgress.watch(
      context,
    );

    // Backup Signals.
    final bool isBackupProcessing = backupService.sIsProcessing.watch(context);
    final double backupProgress = backupService.sProgress.watch(context);

    // Use whichever progress is active.
    final double currentProgress = updateProgress > 0
        ? updateProgress
        : backupProgress;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<FlexScheme>(
                    segments: const <ButtonSegment<FlexScheme>>[
                      ButtonSegment<FlexScheme>(
                        value: FlexScheme.shark,
                        label: Text('Orange'),
                        icon: Icon(LucideIcons.citrus),
                      ),
                      ButtonSegment<FlexScheme>(
                        value: FlexScheme.indigo,
                        label: Text('Purple'),
                        icon: Icon(LucideIcons.brush),
                      ),
                      ButtonSegment<FlexScheme>(
                        value: FlexScheme.redWine,
                        label: Text('Red'),
                        icon: Icon(LucideIcons.wine),
                      ),
                    ],
                    selected: <FlexScheme>{flexScheme},
                    onSelectionChanged: (Set<FlexScheme> newSelection) {
                      sFlexScheme.value = newSelection.first;
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (currentProgress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(value: currentProgress),
            ),
          ListTile(
            onTap: (isChecking || isBackupProcessing)
                ? null
                : () => _showBackupOptions(context),
            leading: isBackupProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            title: const Text('Backup Data'),
            subtitle: const Text('Save your workout history'),
          ),
          ListTile(
            onTap: (isChecking || isBackupProcessing)
                ? null
                : () => _showRestoreOptions(context),
            leading: isBackupProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.fileUp),
            title: const Text('Restore Data'),
            subtitle: const Text('Load data from a backup'),
          ),
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder:
                (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                  final String versionDisplay = snapshot.hasData
                      ? '${snapshot.data!.version}+'
                            '${snapshot.data!.buildNumber}'
                      : 'Checking...';

                  return ListTile(
                    onTap: (isChecking || isBackupProcessing)
                        ? null
                        : () async {
                            await UpdateService().checkForUpdates();
                          },
                    leading: isChecking
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.cloudSync),
                    title: const Text('Check for Updates'),
                    subtitle: Text('Current Version: $versionDisplay'),
                    trailing: const Icon(LucideIcons.chevronRight),
                  );
                },
          ),
          ListTile(
            onTap: () async {
              await launchUrl(
                Uri.parse('https://github.com/plotsklapps/gymply'),
              );
            },
            leading: const Icon(LucideIcons.github),
            title: const Text('Github Repository'),
            subtitle: const Text('Source code, file issues'),
            trailing: const Icon(LucideIcons.chevronRight),
          ),
          ListTile(
            onTap: () async {
              showLicensePage(context: context);
            },
            leading: const Icon(LucideIcons.fileBraces),
            title: const Text('Licenses'),
            subtitle: const Text('Third party packages used by GYMPLY.'),
            trailing: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Backup Destination'),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.smartphone),
                title: const Text('Save to Device'),
                subtitle: const Text('Store a .zip file on your phone'),
                onTap: () async {
                  Navigator.pop(context);
                  await backupService.backupToLocal(context);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.cloud),
                title: const Text('Google Drive Sync'),
                subtitle: const Text(
                  'Store your data in your private Drive folder',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await backupService.backupToCloud(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRestoreOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Restore Source'),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.file),
                title: const Text('From Local File'),
                subtitle: const Text('Select a .zip file from your phone'),
                onTap: () async {
                  Navigator.pop(context);
                  await backupService.restoreFromLocal(context);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.cloud),
                title: const Text('From Google Drive'),
                subtitle: const Text('Download your data from the cloud'),
                onTap: () async {
                  Navigator.pop(context);
                  await backupService.restoreFromCloud(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
