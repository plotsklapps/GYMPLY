import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SomatotypeModal extends StatelessWidget {
  const SomatotypeModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Fixed header.
        Row(
          children: <Widget>[
            // SizedBox to balance close button.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SOMATOTYPE',
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

        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Somatotypes help GYMPLY refine your body fat percentage '
                'calculation beyond standard BMI formulas.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SomatotypeInfo(
                context: context,
                title: 'ECTOMORPH',
                description:
                    'Lean and long, with difficulty building muscle. '
                    'Naturally low body fat.',
                adjustment: '-2.0% Adjustment',
              ),
              SomatotypeInfo(
                context: context,
                title: 'MESOMORPH',
                description:
                    'Muscular and well-built, with a high metabolism '
                    'and responsive muscle cells.',
                adjustment: '-5.0% Adjustment',
              ),
              SomatotypeInfo(
                context: context,
                title: 'ENDOMORPH',
                description:
                    'Big, high tendency to store body fat. Often '
                    'strong with a slower metabolism.',
                adjustment: '+1.0% Adjustment',
              ),
              const Divider(height: 32),
              Text(
                'CALCULATION FORMULAS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      '1. BMI (Quetelet Index)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BMI = weight (kg) / height (m)²',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 24),
                    Text(
                      '2. BASE BF% (Gallagher Formula)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BF% = (1.46 × BMI) + (0.14 × Age) - '
                      '(11.6 × Sex) - 10.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '*Sex: Male = 1, Female = 0',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      '3. SOMATOTYPE TUNING',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Final BF% = Base BF% ± Somatotype Adjustment',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SomatotypeInfo extends StatelessWidget {
  const SomatotypeInfo({
    required this.context,
    required this.title,
    required this.description,
    required this.adjustment,
    super.key,
  });

  final BuildContext context;
  final String title;
  final String description;
  final String adjustment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                adjustment,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
