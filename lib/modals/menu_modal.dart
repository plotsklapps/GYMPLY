import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gymply/modals/restorebackup_modal.dart';
import 'package:gymply/screens/profile_screen.dart';
import 'package:gymply/services/backup_service.dart';
import 'package:gymply/services/modal_service.dart';
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

    // Watch settings Signals.
    final bool isDarkMode = sDarkMode.watch(context);
    final bool isWakelock = sWakelock.watch(context);
    final FlexSchemes flexScheme = sFlexScheme.watch(context);

    // Watch update Signals.
    final bool isChecking = UpdateService().sIsCheckingForUpdate.watch(context);
    final double updateProgress = UpdateService().sDownloadProgress.watch(
      context,
    );

    // Watch backup/restore Signals.
    final bool isBackingUp = backupService.sIsBackingUp.watch(context);
    final bool isRestoring = backupService.sIsRestoring.watch(context);
    final double backupProgress = backupService.sProgress.watch(context);

    // Master processing state to disable all buttons during any activity.
    final bool isAnyProcessing = isChecking || isBackingUp || isRestoring;

    // Use whichever progress is active.
    final double currentProgress = updateProgress > 0
        ? updateProgress
        : backupProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SETTINGS MENU',
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

        ListTile(
          onTap: () async {
            // Pop the modal first.
            Navigator.pop(context);
            // Push the ProfileScreen.
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return const ProfileScreen();
                },
              ),
            );
          },
          leading: const Icon(LucideIcons.userRound),
          title: const Text('Account'),
          subtitle: const Text('Manage your account settings'),
          trailing: const Icon(LucideIcons.chevronRight),
        ),

        // Wakelock ListTile.
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

        // ThemeMode ListTile.
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

        // Colors ListTile.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<FlexSchemes>(
                  segments: const <ButtonSegment<FlexSchemes>>[
                    ButtonSegment<FlexSchemes>(
                      value: FlexSchemes.shark,
                      label: Text('Orange'),
                      icon: Icon(LucideIcons.citrus),
                    ),
                    ButtonSegment<FlexSchemes>(
                      value: FlexSchemes.greyLaw,
                      label: Text('Purple'),
                      icon: Icon(LucideIcons.brush),
                    ),
                    ButtonSegment<FlexSchemes>(
                      value: FlexSchemes.sanJuanBlue,
                      label: Text('Red'),
                      icon: Icon(LucideIcons.wine),
                    ),
                  ],
                  selected: <FlexSchemes>{flexScheme},
                  onSelectionChanged: (Set<FlexSchemes> newSelection) {
                    sFlexScheme.value = newSelection.first;
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        // ProgressIndicator (Conditional).
        if (currentProgress > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(value: currentProgress),
          ),

        // Backup ListTile.
        ListTile(
          onTap: isAnyProcessing
              ? null
              : () async {
                  await backupService.backupToLocal();
                },
          leading: isBackingUp
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Icon(LucideIcons.hardDriveDownload),
          title: const Text('Backup Data'),
          subtitle: const Text('Save your workout history to device'),
        ),

        // Restore ListTile.
        ListTile(
          onTap: isAnyProcessing
              ? null
              : () async {
                  final Uint8List? bytes = await backupService
                      .pickLocalBackup();
                  if (bytes != null && context.mounted) {
                    final bool confirm = await ModalService.showModal(
                      context: context,
                      child: const RestoreBackupModal(),
                    );
                    if (confirm) {
                      await backupService.applyRestore(bytes);
                    } else {
                      // User cancelled confirmation, reset signal.
                      backupService.cancelRestore();
                    }
                  }
                },
          leading: isRestoring
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Icon(LucideIcons.hardDriveUpload),
          title: const Text('Restore Data'),
          subtitle: const Text('Load data from a backup file'),
        ),
        const Divider(),

        // App Update ListTile.
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
            final String versionDisplay = snapshot.hasData
                ? '${snapshot.data!.version}+'
                      '${snapshot.data!.buildNumber}'
                : 'Checking...';

            return ListTile(
              onTap: isAnyProcessing
                  ? null
                  : () async {
                      await UpdateService().checkForUpdates();
                    },
              leading: isChecking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Icon(LucideIcons.cloudSync),
              title: const Text('Check for Updates'),
              subtitle: Text('Current Version: $versionDisplay'),
              trailing: const Icon(LucideIcons.chevronRight),
            );
          },
        ),

        // GitHub ListTile.
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

        // Licenses ListTile.
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
    );
  }
}
