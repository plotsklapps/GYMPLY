import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/sheet_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/sheets/resttimer_sheet.dart';
import 'package:signals/signals_flutter.dart';

class RestTimerWidget extends StatelessWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize RestTimer singleton.
    final RestTimer restTimer = RestTimer();
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final int elapsedRestTime = RestTimer.sElapsedRestTime.watch(context);
    final bool isRestTimerRunning = RestTimer.sRestTimerRunning.watch(context);

    // Create readable time String.
    final String formattedTime = elapsedRestTime.formatMSS();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'REST',
          style: theme.textTheme.bodyLarge,
        ),
        TextButton(
          onPressed: () async {
            await SheetService.showSheet(
              context: context,
              child: const RestTimerSheet(),
            );
          },
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: Text(
            formattedTime,
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.secondary,
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
            InkWell(
              onLongPress: () async {
                await restTimer.resetTimer();
              },
              child: FloatingActionButton(
                heroTag: 'RestTimerWidgetFAB1',
                onPressed: () async {
                  if (isRestTimerRunning) {
                    restTimer.pauseTimer();
                  } else {
                    await restTimer.startTimer();
                  }
                },
                child: isRestTimerRunning
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
