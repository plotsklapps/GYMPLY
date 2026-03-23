// CardioTimer Text Widget to handle high-frequency timer updates.
import 'package:flutter/material.dart';
import 'package:gymply/screens/exercisescreen/cardioexercise_screen.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:signals/signals_flutter.dart';

class CardioTimerText extends StatelessWidget {
  const CardioTimerText({
    required this.mode,
    super.key,
  });

  final CardioMode mode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch ONLY the values needed for the text.
    String timerText;
    if (mode == CardioMode.stopwatch) {
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
