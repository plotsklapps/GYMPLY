import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RepControls extends StatelessWidget {
  const RepControls({
    required this.currentValue,
    required this.onDecrementLarge,
    required this.onDecrementSmall,
    required this.onIncrementSmall,
    required this.onIncrementLarge,
    super.key,
  });

  final int? currentValue;
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
          heroTag: 'RepsDecrement10',
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
          heroTag: 'RepsDecrement1',
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
            currentValue == null ? 'REPS' : currentValue!.toString(),
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
          heroTag: 'RepsIncrement1',
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
          heroTag: 'RepsIncrement10',
          elevation: 0,
          onPressed: () async {
            // Give a bigger bzzz.
            await HapticFeedback.lightImpact();

            onIncrementLarge();
          },
          child: const Icon(LucideIcons.chevronsUp),
        ),
      ],
    );
  }
}
