import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/modals/about_modal.dart';
import 'package:gymply/modals/bodymetrics_modal.dart';
import 'package:gymply/modals/donation_modal.dart';
import 'package:gymply/modals/restorebackup_modal.dart';
import 'package:gymply/modals/themesettings_modal.dart';
import 'package:gymply/screens/profilescreen/profile_screen.dart';
import 'package:gymply/services/backup_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/signals/backup_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:signals/signals_flutter.dart';

class MenuModal extends SignalWidget {
  const MenuModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch update Signals.
    final bool isChecking = UpdateService().sIsCheckingForUpdate.value;

    // Watch backup/restore Signals.
    final bool isBackingUp = sIsBackingUp.value;
    final bool isRestoring = sIsRestoring.value;

    // Master processing state to disable all buttons during any activity.
    final bool isAnyProcessing = isChecking || isBackingUp || isRestoring;

    final double backupProgress = sProgress.value;

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
              icon: IconUtils.close,
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
                  leading: IconUtils.incognito,
                  title: const Text('Nostr Profile'),
                  subtitle: const Text('Manage your Nostr settings'),
                  trailing: IconUtils.circleRight,
                ),

                // BodyMetrics ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      child: const BodyMetricsModal(),
                    );
                  },
                  leading: IconUtils.body,
                  title: const Text('Body Metrics'),
                  subtitle: const Text('Age, height, weight and more'),
                  trailing: IconUtils.circleRight,
                ),

                // Theme settings ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      child: const ThemeSettingsModal(),
                    );
                  },
                  leading: IconUtils.palette,
                  title: const Text('Theme Settings'),
                  subtitle: const Text('Set up your GYMPLY experience'),
                  trailing: IconUtils.circleRight,
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
                      : IconUtils.download,
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
                      : IconUtils.upload,
                  title: const Text('Restore Data'),
                  subtitle: const Text('Load data from a backup file'),
                ),
                // Support GYMPLY. ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      child: const DonationModal(),
                    );
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.heart,
                    color: theme.colorScheme.secondary,
                  ),
                  title: const Text('Support GYMPLY.'),
                  subtitle: const Text('Help keep this app free and private'),
                  trailing: IconUtils.circleRight,
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
                  leading: IconUtils.info,
                  title: const Text('About GYMPLY.'),
                  subtitle: const Text('Source Code, Updates, Licenses'),
                  trailing: IconUtils.circleRight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
