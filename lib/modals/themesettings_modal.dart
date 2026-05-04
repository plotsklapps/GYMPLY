import 'package:flutter/material.dart';
import 'package:gymply/modals/donation_modal.dart';
import 'package:gymply/services/donation_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/signals/appicon_signal.dart';
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

                // App Icon Picker.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'APP ICON',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AppIconPicker(),
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

class _AppIconPicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isSupporter = donationService.sIsSupporter.watch(context);
    final String currentIcon = sAppIcon.watch(context);

    final List<_IconOption> options = <_IconOption>[
      _IconOption(
        name: 'MainActivityDefault',
        asset: 'assets/icons/gymplyIcon.png',
        label: 'Default',
        isLocked: false,
      ),
      _IconOption(
        name: 'MainActivityPink',
        asset: 'assets/icons/supporterPink.png',
        label: 'Pink',
        isLocked: !isSupporter,
      ),
      _IconOption(
        name: 'MainActivityPurple',
        asset: 'assets/icons/supporterPurple.png',
        label: 'Purple',
        isLocked: !isSupporter,
      ),
      _IconOption(
        name: 'MainActivityOrange',
        asset: 'assets/icons/supporterOrange.png',
        label: 'Orange',
        isLocked: !isSupporter,
      ),
    ];

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: options.map((_IconOption option) {
            final bool isSelected = currentIcon == option.name;

            return InkWell(
              onTap: option.isLocked
                  ? () async {
                      ToastService.showWarning(
                        title: 'Supporter Perk',
                        subtitle: 'Donate to unlock this icon!',
                      );
                      // Open Donation Modal.
                      await ModalService.showModal(
                        context: context,
                        child: const DonationModal(),
                      );
                    }
                  : () async {
                      if (isSelected) return;
                      await settingsService.updateAppIcon(option.name);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        ColorFiltered(
                          colorFilter: option.isLocked
                              ? const ColorFilter.matrix(<double>[
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              option.asset,
                              width: 60,
                              height: 60,
                            ),
                          ),
                        ),
                        if (option.isLocked)
                          const Positioned(
                            right: 4,
                            bottom: 4,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                LucideIcons.lock,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Note: Changing the icon might restart the app to apply the change.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).hintColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _IconOption {
  _IconOption({
    required this.name,
    required this.asset,
    required this.label,
    required this.isLocked,
  });
  final String name;
  final String asset;
  final String label;
  final bool isLocked;
}
