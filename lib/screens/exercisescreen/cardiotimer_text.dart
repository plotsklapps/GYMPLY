import 'package:flutter/material.dart';
import 'package:gymply/screens/exercisescreen/cardioexercise_screen.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:signals/signals_flutter.dart';

// CardioTimer Text Widget to handle high-frequency timer updates.
class CardioTimerText extends SignalWidget {
  const CardioTimerText({
    required this.mode,
    super.key,
  });

  // Stopwatch or Interval.
  final CardioMode mode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch ONLY values needed for text.
    String timerText;
    if (mode == CardioMode.stopwatch) {
      timerText = StopwatchTimer.cFormattedStopwatchTime.value;
    } else {
      timerText = IntervalTimer.cFormattedIntervalTime.value;
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
