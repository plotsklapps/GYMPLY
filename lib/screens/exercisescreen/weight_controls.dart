import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WeightControls extends StatelessWidget {
  const WeightControls({
    required this.currentValue,
    required this.onDecrementLarge,
    required this.onDecrementSmall,
    required this.onIncrementSmall,
    required this.onIncrementLarge,
    super.key,
  });

  final double? currentValue;
  final VoidCallback onDecrementLarge;
  final VoidCallback onDecrementSmall;
  final VoidCallback onIncrementSmall;
  final VoidCallback onIncrementLarge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? displayLargeStyle = theme.textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Row(
      children: <Widget>[
        FloatingActionButton(
          heroTag: 'WeightDecrement10',
          elevation: 0,
          onPressed: () async {
            // Give a bigger bzzz.
            await HapticFeedback.mediumImpact();

            onDecrementLarge();
          },
          child: const Icon(LucideIcons.chevronsDown),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightDecrement1',
          elevation: 0,
          onPressed: () async {
            // Give a little bzzz.
            await HapticFeedback.lightImpact();

            onDecrementSmall();
          },
          child: const Icon(LucideIcons.chevronDown),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            currentValue == null ? 'WEIGHT' : currentValue!.toStringAsFixed(0),
            style:
                (currentValue == null
                        ? theme.textTheme.displayMedium
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
            // StrutStyle to ensure height stays consistent.
            strutStyle: StrutStyle.fromTextStyle(displayLargeStyle!),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightIncrement1',
          elevation: 0,
          onPressed: () async {
            // Give a little bzzz.
            await HapticFeedback.lightImpact();

            onIncrementSmall();
          },
          child: const Icon(LucideIcons.chevronUp),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightIncrement10',
          elevation: 0,
          onPressed: () async {
            // Give a bigger bzzz.
            await HapticFeedback.mediumImpact();

            onIncrementLarge();
          },
          child: const Icon(LucideIcons.chevronsUp),
        ),
      ],
    );
  }
}
