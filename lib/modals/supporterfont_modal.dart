import 'package:flutter/material.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:gymply/theme/icons.dart';
import 'package:signals/signals_flutter.dart';

class SupporterFontModal extends SignalWidget {
  const SupporterFontModal({super.key});

  static const List<String> _fonts = <String>[
    'League Gothic',
    'Bebas Neue',
    'Oswald',
    'Fjalla One',
    'Anton',
    'Inter',
    'Roboto',
    'Poppins',
    'Montserrat',
    'Lato',
    'Nunito',
    'Open Sans',
    'Rubik',
    'Work Sans',
    'Barlow',
    'Kanit',
    'Teko',
    'Quicksand',
    'Exo 2',
    'Fira Sans',
    'Raleway',
    'PT Sans',
    'Ubuntu',
    'Outfit',
    'Plus Jakarta Sans',
    'DM Sans',
    'Manrope',
    'Cabin',
    'Titillium Web',
    'Space Grotesk',
    'Archivo',
    'Archivo Black',
    'Urbanist',
    'Sora',
    'Lexend',
    'Asap',
    'Barlow Condensed',
    'Chakra Petch',
    'Saira',
    'Red Hat Display',
    'Public Sans',
    'Figtree',
    'Instrument Sans',
    'Noto Sans',
    'Overpass',
    'Mukta',
    'Blinker',
    'Josefin Sans',
    'Syne',
    'Anek Latin',
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String currentFont = sFont.value;

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
                    'SUPPORTER FONTS',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(IconUtils.close),
                ),
              ],
            ),
            const Divider(),

            // List Body
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _fonts.length,
                itemBuilder: (BuildContext context, int index) {
                  final String fontName = _fonts[index];
                  final bool isSelected = currentFont == fontName;

                  final TextStyle fontStyle = TextStyle(fontFamily: fontName);

                  return ListTile(
                    leading: isSelected
                        ? Icon(
                            IconUtils.check,
                            color: theme.colorScheme.secondary,
                          )
                        : const SizedBox(
                            width: 24,
                          ),
                    title: Text(
                      fontName,
                      style: fontStyle.copyWith(
                        fontSize: 20,
                        color: isSelected ? theme.colorScheme.secondary : null,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () async {
                      await settingsService.updateFont(fontName);
                    },
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
