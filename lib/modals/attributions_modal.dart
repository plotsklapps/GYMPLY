import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AttributionsModal extends StatelessWidget {
  const AttributionsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'ATTRIBUTIONS',
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
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'GYMPLY would not be possible without the exceptional work of these talented individuals. '
                    'This section is dedicated to them with my sincere thanks.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const AttributionSection(
                  title: 'Anatomy Assets',
                  content:
                      'Human Body Atlas diagrams by Ryan Graves. '
                      'Licensed under CC BY 4.0.',
                  url: 'https://pub.dev/packages/flutter_body_atlas',
                ),
                const AttributionSection(
                  title: 'Theme Engine',
                  content:
                      'Flex Color Scheme package by Mike Rydstrom. '
                      'Licensed under BSD 3-Clause.',
                  url: 'https://pub.dev/packages/flex_color_scheme',
                ),
                const AttributionSection(
                  title: 'State Management',
                  content:
                      'Signals package by Rod Brown. '
                      'Licensed under MIT.',
                  url: 'https://pub.dev/packages/signals',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AttributionSection extends StatelessWidget {
  const AttributionSection({
    required this.title,
    required this.content,
    this.url,
    super.key,
  });

  final String title;
  final String content;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: url != null ? () => launchUrl(Uri.parse(url!)) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: url != null ? theme.colorScheme.primary : null,
                  decoration: url != null ? TextDecoration.underline : null,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Text(content, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
      ],
    );
  }
}
