import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:gymply/modals/donation_modal.dart';
import 'package:gymply/modals/supporterfont_modal.dart';
import 'package:gymply/modals/supportertheme_modal.dart';
import 'package:gymply/services/donation_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:gymply/theme/icons.dart';
import 'package:signals/signals_flutter.dart';

class ThemeSettingsModal extends SignalWidget {
  const ThemeSettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch settings Signals.
    final bool isDarkMode = sDarkMode.value;
    final bool isWakelock = sWakelock.value;
    final bool isUseLbs = sUseLbs.value;
    final FlexScheme flexScheme = sFlexScheme.value;
    final String font = sFont.value;
    final bool isSupporter = donationService.sIsSupporter.value;

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
                'THEME SETTINGS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: const Icon(IconUtils.close),
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
                  secondary: isWakelock
                      ? const Icon(IconUtils.wakelockOn)
                      : const Icon(IconUtils.wakelockOff),
                  value: isWakelock,
                  onChanged: (bool value) async {
                    await settingsService.toggleWakelock(value: value);
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
                  secondary: isDarkMode
                      ? const Icon(IconUtils.darkMode)
                      : const Icon(IconUtils.lightMode),

                  value: isDarkMode,
                  onChanged: (bool value) async {
                    await settingsService.toggleThemeMode(value: value);
                  },
                ),

                // Weight Unit ListTile.
                SwitchListTile(
                  title: isUseLbs
                      ? const Text('Use lbs (pounds)')
                      : const Text('Use kg (kilograms)'),
                  subtitle: isUseLbs
                      ? const Text('Weight metrics shown in pounds')
                      : const Text('Weight metrics shown in kilograms'),
                  secondary: isUseLbs
                      ? const Icon(IconUtils.weightScale)
                      : const Icon(IconUtils.bmi),
                  value: isUseLbs,
                  onChanged: (bool value) async {
                    await settingsService.toggleUseLbs(value: value);
                  },
                ),

                const Divider(),

                if (isSupporter) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'Thank you for supporting GYMPLY.',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                  ListTile(
                    leading: const Icon(IconUtils.palette),
                    title: const Text('Themes'),
                    subtitle: const Text('Change your theme'),
                    trailing: const Icon(IconUtils.chevronRight),
                    onTap: () async {
                      await showModalBottomSheet<void>(
                        showDragHandle: true,
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return const SupporterThemeModal();
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(IconUtils.font),
                    title: const Text('Fonts'),
                    subtitle: const Text('Change your font'),
                    trailing: const Icon(IconUtils.chevronRight),
                    onTap: () async {
                      await showModalBottomSheet<void>(
                        showDragHandle: true,
                        context: context,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return const SupporterFontModal();
                        },
                      );
                    },
                  ),
                ] else ...<Widget>[
                  // Color picker for non-supporters.
                  Column(
                    children: <Widget>[
                      ListTile(
                        onTap: () async {
                          await ModalService.showModal(
                            context: context,
                            child: const DonationModal(),
                          );
                        },
                        leading: const Icon(IconUtils.like),
                        title: const Text('Become a GYMPLY supporter'),
                        subtitle: const Text(
                          'Get access to 50+ themes and 100+ '
                          'fonts!',
                        ),
                        trailing: const Icon(IconUtils.chevronRight),
                      ),
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
                              child: SegmentedButton<FlexScheme>(
                                segments: const <ButtonSegment<FlexScheme>>[
                                  ButtonSegment<FlexScheme>(
                                    value: FlexScheme.shark,
                                    label: Text('Orange'),
                                    icon: Icon(
                                      IconUtils.color,
                                      color: kOrange,
                                    ),
                                  ),
                                  ButtonSegment<FlexScheme>(
                                    value: FlexScheme.greyLaw,
                                    label: Text('Purple'),
                                    icon: Icon(
                                      IconUtils.color,
                                      color: kPurple,
                                    ),
                                  ),
                                  ButtonSegment<FlexScheme>(
                                    value: FlexScheme.sanJuanBlue,
                                    label: Text('Pink'),
                                    icon: Icon(
                                      IconUtils.color,
                                      color: kPink,
                                    ),
                                  ),
                                ],
                                selected: <FlexScheme>{flexScheme},
                                onSelectionChanged:
                                    (Set<FlexScheme> newSelection) async {
                                      await settingsService.updateFlexScheme(
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

                  // Font Picker for non-supporters.
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
                                value: 'Teko',
                                label: Text('Teko'),
                                icon: Icon(IconUtils.fontOne),
                              ),
                              ButtonSegment<String>(
                                value: 'Kanit',
                                label: Text('Kanit'),
                                icon: Icon(IconUtils.fontTwo),
                              ),
                              ButtonSegment<String>(
                                value: 'Bebas Neue',
                                label: Text('Bebas'),
                                icon: Icon(IconUtils.fontThree),
                              ),
                            ],
                            selected: <String>{font},
                            onSelectionChanged:
                                (Set<String> newSelection) async {
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
