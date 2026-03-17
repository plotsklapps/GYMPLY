import 'package:flutter/material.dart';
import 'package:gymply/modals/resttimer_modal.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
            await ModalService.showModal(
              context: context,
              child: const RestTimerModal(),
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
                heroTag: 'RestTimerWidgetFAB',
                elevation: 0,
                onPressed: () async {
                  if (isRestTimerRunning) {
                    await restTimer.pauseTimer();
                  } else {
                    await restTimer.startTimer();
                  }
                },
                child: isRestTimerRunning
                    ? const Icon(LucideIcons.circlePause)
                    : const Icon(LucideIcons.circlePlay),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
