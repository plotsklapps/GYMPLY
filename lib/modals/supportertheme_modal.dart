import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class SupporterThemeModal extends StatelessWidget {
  const SupporterThemeModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = sDarkMode.watch(context);
    final FlexScheme currentScheme = sFlexScheme.watch(context);

    // Get all valid schemes (exclude custom if it's there and empty)
    final List<FlexScheme> schemes = FlexScheme.values
        .where((FlexScheme s) => s != FlexScheme.custom)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            // Fixed Header.
            Row(
              children: <Widget>[
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'SUPPORTER THEMES',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.circleX),
                ),
              ],
            ),
            const Divider(),

            // Grid Body
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: schemes.length,
                itemBuilder: (BuildContext context, int index) {
                  final FlexScheme scheme = schemes[index];
                  final FlexSchemeData? schemeData = FlexColor.schemes[scheme];
                  if (schemeData == null) {
                    return const SizedBox();
                  }

                  final FlexSchemeColor schemeColor = isDark
                      ? schemeData.dark
                      : schemeData.light;
                  final bool isSelected = currentScheme == scheme;

                  return InkWell(
                    onTap: () async {
                      await settingsService.updateFlexScheme(scheme);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? schemeColor.secondary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            schemeData.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? schemeColor.secondary : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              _ColorBox(color: schemeColor.primary),
                              const SizedBox(width: 4),
                              _ColorBox(color: schemeColor.secondary),
                              const SizedBox(width: 4),
                              _ColorBox(color: schemeColor.tertiary),
                              const SizedBox(width: 4),
                              _ColorBox(color: schemeColor.error ?? Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ColorBox extends StatelessWidget {
  const _ColorBox({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
