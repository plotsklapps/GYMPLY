import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gymply/modals/about_modal.dart';
import 'package:gymply/modals/bodymetrics_modal.dart';
import 'package:gymply/modals/restorebackup_modal.dart';
import 'package:gymply/modals/themesettings_modal.dart';
import 'package:gymply/screens/profilescreen/profile_screen.dart';
import 'package:gymply/services/backup_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/signals/backup_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

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

    // Master processing state to disable all buttons during any activity.
    final bool isAnyProcessing = isChecking || isBackingUp || isRestoring;

    final double backupProgress = sProgress.watch(context);

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
                // Pop the modal.
                Navigator.pop(context);
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
                  leading: const Icon(LucideIcons.hatGlasses),
                  title: const Text('Nostr Profile'),
                  subtitle: const Text('Manage your Nostr settings'),
                  trailing: const Icon(LucideIcons.circleChevronRight),
                ),

                // BodyMetrics ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      child: const BodyMetricsModal(),
                    );
                  },
                  leading: const Icon(LucideIcons.personStanding),
                  title: const Text('Body Metrics'),
                  subtitle: const Text('Age, height, weight and more'),
                  trailing: const Icon(LucideIcons.circleChevronRight),
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
                  trailing: const Icon(LucideIcons.circleChevronRight),
                ),

                const Divider(),

                // ProgressIndicator (Conditional).
                if (backupProgress > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(value: backupProgress),
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

                // About GYMPLY ListTile.
                ListTile(
                  onTap: () async {
                    // Close MenuModal first.
                    Navigator.pop(context);
                    // Open AboutModal.
                    await ModalService.showModal(
                      context: context,
                      child: const AboutModal(),
                    );
                  },
                  leading: const Icon(LucideIcons.info),
                  title: const Text('About GYMPLY.'),
                  subtitle: const Text('Source Code, Updates, Licenses'),
                  trailing: const Icon(LucideIcons.circleChevronRight),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
