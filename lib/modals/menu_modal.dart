import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gymply/modals/bodymetrics_modal.dart';
import 'package:gymply/modals/restorebackup_modal.dart';
import 'package:gymply/modals/themesettings_modal.dart';
import 'package:gymply/screens/profilescreen/profile_screen.dart';
import 'package:gymply/services/backup_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/signals/backup_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuModal extends StatelessWidget {
  const MenuModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch update Signals.
    final bool isChecking = UpdateService().sIsCheckingForUpdate.watch(context);

    // Watch backup/restore Signals.
    final bool isBackingUp = sIsBackingUp.watch(context);
    final bool isRestoring = sIsRestoring.watch(context);
    final double backupProgress = sProgress.watch(context);

    // Master processing state to disable all buttons during any activity.
    final bool isAnyProcessing = isChecking || isBackingUp || isRestoring;

    // The progress indicator now only tracks backups, since updates are
    //handled by the browser.
    final double currentProgress = backupProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // --- FIXED HEADER ---
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

        // --- SCROLLABLE BODY ---
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Nostr ListTile.
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
                  leading: const Icon(LucideIcons.user),
                  title: const Text('Account'),
                  subtitle: const Text('Manage your account settings'),
                  trailing: const Icon(LucideIcons.chevronRight),
                ),

                // BodyMetrics ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      scrollable: false,
                      child: const BodyMetricsModal(),
                    );
                  },
                  leading: const Icon(LucideIcons.personStanding),
                  title: const Text('Body Metrics'),
                  subtitle: const Text('Age, height, weight and more'),
                  trailing: const Icon(LucideIcons.chevronRight),
                ),

                // Theme settings ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      scrollable: false,
                      child: const ThemeSettingsModal(),
                    );
                  },
                  leading: const Icon(LucideIcons.paintbrush),
                  title: const Text('Theme Settings'),
                  subtitle: const Text('Set up your GYMPLY experience'),
                  trailing: const Icon(LucideIcons.chevronRight),
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
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<PackageInfo> snapshot,
                      ) {
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
                  leading: const Icon(LucideIcons.code),
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
            ),
          ),
        ),
      ],
    );
  }
}
