import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:signals/signals_flutter.dart';

class TotalTimerWidget extends StatelessWidget {
  const TotalTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize TotalTimer singleton.
    final TotalTimer totalTimer = TotalTimer();
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final int elapsedTotalTime = TotalTimer.sElapsedTotalTime.watch(context);
    final bool isTotalTimerRunning = TotalTimer.sTotalTimerRunning.watch(
      context,
    );

    // Use formatting extension.
    final String formattedTime = elapsedTotalTime.formatHMMSS();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'TOTAL',
          style: theme.textTheme.bodyLarge,
        ),
        TextButton(
          onPressed: () async {
            // Do nothing for now.
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            formattedTime,
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Press to pause/play, long press to reset.
            InkWell(
              onLongPress: () async {
                await totalTimer.resetTimer();
              },
              child: FloatingActionButton(
                heroTag: 'TotalTimerWidgetFAB1',
                onPressed: () async {
                  if (isTotalTimerRunning) {
                    totalTimer.pauseTimer();
                  } else {
                    await totalTimer.startTimer();
                  }
                },
                child: isTotalTimerRunning
                    ? const FaIcon(FontAwesomeIcons.solidCirclePause)
                    : const FaIcon(FontAwesomeIcons.solidCirclePlay),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
