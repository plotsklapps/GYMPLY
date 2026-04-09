import 'package:flutter/material.dart' hide StretchMode;
import 'package:gymply/screens/exercisescreen/stretchexercise_screen.dart'
    show StretchMode;
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:signals/signals_flutter.dart';

// StretchTimer Text Widget to handle high-frequency timer updates.
class StretchTimerText extends StatelessWidget {
  const StretchTimerText({
    required this.mode,
    super.key,
  });

  // Stopwatch or Interval.
  final StretchMode mode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch ONLY values needed for text.
    String timerText;
    if (mode == StretchMode.stopwatch) {
      timerText = StopwatchTimer.cFormattedStopwatchTime.watch(context);
    } else {
      timerText = IntervalTimer.cFormattedIntervalTime.watch(context);
    }

    return Text(
      timerText,
      style: theme.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: const <FontFeature>[
          FontFeature.tabularFigures(),
        ],
      ),
    );
  }
}
