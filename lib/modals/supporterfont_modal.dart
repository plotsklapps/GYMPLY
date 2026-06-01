import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class SupporterFontModal extends SignalWidget {
  const SupporterFontModal({super.key});

  static const List<String> _fonts = <String>[
    'League Gothic',
    'Bebas Neue',
    'Fjalla One',
    'Lato',
    'Roboto',
    'Open Sans',
    'Montserrat',
    'Oswald',
    'Source Sans 3',
    'Raleway',
    'Poppins',
    'Inter',
    'Playfair Display',
    'Ubuntu',
    'Merriweather',
    'Nunito',
    'Lora',
    'PT Sans',
    'Mukta',
    'Rubik',
    'Work Sans',
    'Fira Sans',
    'Quicksand',
    'Inconsolata',
    'Kanit',
    'Anton',
    'Josefin Sans',
    'Dancing Script',
    'Prompt',
    'Exo 2',
    'Pacifico',
    'Titillium Web',
    'Karla',
    'Heebo',
    'Barlow',
    'PT Serif',
    'Cabin',
    'Abel',
    'Hind',
    'Bitter',
    'Varela Round',
    'Dosis',
    'Arimo',
    'Noto Sans',
    'Noto Serif',
    'Crimson Text',
    'Yanone Kaffeesatz',
    'Righteous',
    'Teko',
    'Caveat',
    'Alfa Slab One',
    'Acme',
    'Fascinate Inline',
    'Changa One',
    'Permanent Marker',
    'Fredoka One',
    'Bangers',
    'Creepster',
    'Lobster',
    'Comfortaa',
    'Amatic SC',
    'Shadows Into Light',
    'Courgette',
    'Abril Fatface',
    'Cinzel',
    'Bree Serif',
    'Satisfy',
    'Russo One',
    'Kaushan Script',
    'Monoton',
    'Audiowide',
    'Kalam',
    'Orbitron',
    'Carter One',
    'Press Start 2P',
    'Signika',
    'Sriracha',
    'Patua One',
    'Zilla Slab',
    'Rokkitt',
    'Monda',
    'Black Ops One',
    'Rampart One',
    'Saira Stencil One',
    'Tourney',
    'Monofett',
    'Freckle Face',
    'Bungee',
    'Shrikhand',
    'VT323',
    'Modak',
    'Ewert',
    'Vampiro One',
    'Fruktur',
    'Piedra',
    'Plaster',
    'Nosifer',
    'Bungee Shade',
    'Frijole',
    'Eater',
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
                  icon: const Icon(LucideIcons.circleX),
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

                  // Get the text style for this font from GoogleFonts
                  TextStyle fontStyle;
                  try {
                    fontStyle = GoogleFonts.getFont(fontName);
                  } on Exception catch (_) {
                    // Fallback in case a font name is misspelled
                    fontStyle = const TextStyle();
                  }

                  return ListTile(
                    leading: isSelected
                        ? Icon(
                            LucideIcons.check,
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
