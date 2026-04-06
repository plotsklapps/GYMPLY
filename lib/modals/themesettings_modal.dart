import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymply/modals/permission_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals/signals_flutter.dart';

class ThemeSettingsModal extends StatelessWidget {
  const ThemeSettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch settings Signals.
    final bool isDarkMode = sDarkMode.watch(context);
    final bool isWakelock = sWakelock.watch(context);
    final FlexSchemes flexScheme = sFlexScheme.watch(context);
    final String font = sFont.watch(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Fixed Header.
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

        // Scrollable Body.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
                  onChanged: (bool value) async {
                    await settingsService.toggleWakelock(value: value);
                  },
                ),

                // Notification ListTile.
                const _NotificationSwitchTile(),

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
                  onChanged: (bool value) async {
                    await settingsService.toggleThemeMode(value: value);
                  },
                ),

                // Color picker.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                              label: Text('Pink'),
                              icon: Icon(LucideIcons.wine),
                            ),
                          ],
                          selected: <FlexSchemes>{flexScheme},
                          onSelectionChanged:
                              (Set<FlexSchemes> newSelection) async {
                                await settingsService.updateFlexScheme(
                                  newSelection.first,
                                );
                              },
                        ),
                      ),
                    ],
                  ),
                ),

                // Font Picker.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment<String>(
                              value: 'LeagueGothic',
                              label: Text('Gothic'),
                              icon: Icon(LucideIcons.church),
                            ),
                            ButtonSegment<String>(
                              value: 'Lato',
                              label: Text('Lato'),
                              icon: Icon(LucideIcons.signature),
                            ),
                            ButtonSegment<String>(
                              value: 'FjallaOne',
                              label: Text('Fjalla'),
                              icon: Icon(LucideIcons.squareLibrary),
                            ),
                          ],
                          selected: <String>{font},
                          onSelectionChanged: (Set<String> newSelection) async {
                            await settingsService.updateFont(
                              newSelection.first,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationSwitchTile extends StatefulWidget {
  const _NotificationSwitchTile();

  @override
  State<_NotificationSwitchTile> createState() =>
      _NotificationSwitchTileState();
}

class _NotificationSwitchTileState extends State<_NotificationSwitchTile>
    with WidgetsBindingObserver {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_checkPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final bool isGranted = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        _isGranted = isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Allow notifications'),
      subtitle: const Text('Required for background timer sounds'),
      secondary: Icon(
        _isGranted ? LucideIcons.bellRing : LucideIcons.bellOff,
      ),
      value: _isGranted,
      onChanged: (bool value) async {
        if (value) {
          // Show custom permission modal first.
          await ModalService.showModal(
            context: context,
            child: const PermissionModal(),
          );

          // The modal requests the permission when "UNDERSTOOD" is pressed.
          // Check the final status after the modal closes.
          final PermissionStatus status = await Permission.notification.status;

          if (status.isGranted) {
            await _checkPermission();
          } else if (status.isPermanentlyDenied) {
            // If the OS blocked the prompt completely, send them to settings.
            await openAppSettings();
          } else {
            // If they just closed the modal or denied the prompt,
            // revert switch.
            await _checkPermission();
          }
        } else {
          // Android doesn't let apps revoke their own permissions.
          // Redirect to settings so they can disable it manually.
          await openAppSettings();
        }
      },
    );
  }
}
