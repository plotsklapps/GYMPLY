import 'package:flutter/material.dart';
import 'package:gymply/modals/attributions_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/update_service.dart';
import 'package:gymply/signals/backup_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutModal extends SignalWidget {
  const AboutModal({super.key});

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'ABOUT GYMPLY.',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: IconUtils.close,
            ),
          ],
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),

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
                              : IconUtils.sync,
                          title: const Text('Check for Updates'),
                          subtitle: Text('Current Version: $versionDisplay'),
                          trailing: IconUtils.circleRight,
                        );
                      },
                ),

                // GitHub SourceCode ListTile.
                ListTile(
                  onTap: () async {
                    await launchUrl(
                      Uri.parse('https://github.com/plotsklapps/gymply'),
                    );
                  },
                  leading: IconUtils.github,
                  title: const Text('Github Repository'),
                  subtitle: const Text('Source code, file issues'),
                  trailing: IconUtils.circleRight,
                ),

                // GitHub ChangeLog ListTile.
                ListTile(
                  onTap: () async {
                    await launchUrl(
                      Uri.parse(
                        'https://github.com/plotsklapps/GYMPLY./blob/master/CHANGELOG.md',
                      ),
                    );
                  },
                  leading: IconUtils.codeCompare,
                  title: const Text('Github Changelog'),
                  subtitle: const Text('See changes made in the last version'),
                  trailing: IconUtils.circleRight,
                ),

                // Licenses ListTile.
                ListTile(
                  onTap: () async {
                    showLicensePage(context: context);
                  },
                  leading: IconUtils.copyright,
                  title: const Text('Licenses'),
                  subtitle: const Text('Third party packages used by GYMPLY.'),
                  trailing: IconUtils.circleRight,
                ),

                // Attributions ListTile.
                ListTile(
                  onTap: () async {
                    await ModalService.showModal(
                      context: context,
                      child: const AttributionsModal(),
                    );
                  },
                  leading: IconUtils.handshake,
                  title: const Text('Attributions'),
                  subtitle: const Text('Attributions for assets and packages.'),
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
