import 'package:flutter/material.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
                          onSelectionChanged: (Set<FlexSchemes> newSelection) {
                            sFlexScheme.value = newSelection.first;
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
                          selected: <String>{sFont.watch(context)},
                          onSelectionChanged: (Set<String> newSelection) {
                            sFont.value = newSelection.first;
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
