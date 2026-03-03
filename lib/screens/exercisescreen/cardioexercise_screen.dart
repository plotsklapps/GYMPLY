import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/sheet_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/sheets/cardiotimer_sheet.dart';
import 'package:signals/signals_flutter.dart';

enum CardioMode { stopwatch, interval }

// Global CardioMode Signal (Stopwatch, Interval).
final Signal<CardioMode> sCardioMode = Signal<CardioMode>(
  CardioMode.stopwatch,
  debugLabel: 'sCardioMode',
);

class CardioExerciseScreen extends StatelessWidget {
  const CardioExerciseScreen({
    required this.exercise,
    super.key,
  });

  final CardioExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final CardioMode mode = sCardioMode.watch(context);
    final bool isStopwatchRunning = StopwatchTimer.sStopwatchTimerRunning.watch(
      context,
    );
    final bool isIntervalRunning = IntervalTimer.sIntervalTimerRunning.watch(
      context,
    );
    final bool isRestRunning = RestTimer.sRestTimerRunning.watch(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          // FIXED TOP SECTION.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        // HISTORY BUTTON.
                        IconButton(
                          onPressed: () {},
                          icon: FaIcon(
                            FontAwesomeIcons.clockRotateLeft,
                            color: theme.colorScheme.secondary.withAlpha(140),
                            size: 20,
                          ),
                        ),
                        // STATISTICS BUTTON.
                        IconButton(
                          onPressed: () {},
                          icon: FaIcon(
                            FontAwesomeIcons.chartColumn,
                            color: theme.colorScheme.secondary.withAlpha(140),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    // EXERCISE IMAGE.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        exercise.imagePath,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                // CARDIOMODE CHOICECHIPS.
                Wrap(
                  spacing: 4,
                  children: CardioMode.values.map((CardioMode value) {
                    final bool isSelected = mode == value;
                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: isSelected
                          ? const FaIcon(FontAwesomeIcons.solidCircleCheck)
                          : null,
                      label: Text(
                        value.name.toUpperCase(),
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) sCardioMode.value = value;
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // TIMER.
                TextButton(
                  onPressed: () async {
                    if (mode != CardioMode.stopwatch) {
                      await SheetService.showSheet(
                        context: context,
                        child: const IntervalTimerSheet(),
                      );
                    }
                  },
                  child: _CardioTimerText(
                    mode: mode,
                  ),
                ),

                const SizedBox(height: 8),

                // FABs.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // RESET FAB.
                    FloatingActionButton(
                      heroTag: 'cardioReset',
                      elevation: 0,
                      onPressed: () async {
                        if (mode == CardioMode.stopwatch) {
                          await StopwatchTimer().resetTimer();
                        } else {
                          await IntervalTimer().resetTimer();
                          await RestTimer().resetTimer();
                        }
                      },
                      child: const FaIcon(FontAwesomeIcons.rotateLeft),
                    ),
                    // START/PAUSE FAB.
                    FloatingActionButton.large(
                      heroTag: 'cardioPlay',
                      elevation: 4,
                      onPressed: () async {
                        if (mode == CardioMode.stopwatch) {
                          isStopwatchRunning
                              ? await StopwatchTimer().pauseTimer()
                              : await StopwatchTimer().startTimer();
                        } else {
                          if (isRestRunning) {
                            RestTimer().pauseTimer();
                          } else if (isIntervalRunning) {
                            IntervalTimer().pauseTimer();
                          } else {
                            await IntervalTimer().startTimer();
                          }
                        }
                      },
                      child:
                          (mode == CardioMode.stopwatch
                              ? isStopwatchRunning
                              : (isIntervalRunning || isRestRunning))
                          ? const FaIcon(FontAwesomeIcons.solidCirclePause)
                          : const FaIcon(FontAwesomeIcons.solidCirclePlay),
                    ),
                    // ADD SET FAB.
                    FloatingActionButton(
                      heroTag: 'cardioAdd',
                      elevation: 0,
                      onPressed: () async {
                        if (mode == CardioMode.stopwatch) {
                          await StopwatchTimer().pauseTimer();
                          final int elapsed =
                              StopwatchTimer.sElapsedStopwatchTime.value;
                          workoutService.addCardioSet(
                            exercise,
                            cardioDuration: Duration(milliseconds: elapsed),
                            restDuration: Duration.zero,
                            totalDuration: Duration(milliseconds: elapsed),
                          );
                          await StopwatchTimer().resetTimer();
                        } else {
                          IntervalTimer().pauseTimer();
                          RestTimer().pauseTimer();

                          // Log the full prescribed interval + rest.
                          final int cardioSec =
                              IntervalTimer.sInitialIntervalTime.value;
                          final int restSec = RestTimer.sInitialRestTime.value;

                          workoutService.addCardioSet(
                            exercise,
                            cardioDuration: Duration(seconds: cardioSec),
                            restDuration: Duration(seconds: restSec),
                            totalDuration: Duration(
                              seconds: cardioSec + restSec,
                            ),
                          );

                          await IntervalTimer().resetTimer();
                          await RestTimer().resetTimer();
                        }
                      },
                      child: const FaIcon(FontAwesomeIcons.circlePlus),
                    ),
                  ],
                ),
                // AUTO-INTERVAL SWITCH.
                if (mode == CardioMode.interval)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text('AUTO-INTERVAL'),
                        Switch(
                          value: IntervalTimer.sAutoIntervalOn.watch(context),
                          onChanged: (bool value) {
                            IntervalTimer.sAutoIntervalOn.value = value;
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: exercise.sets.length,
              itemBuilder: (BuildContext context, int index) {
                final int displayIndex = exercise.sets.length - index;
                final CardioSet set = exercise.sets.reversed.toList()[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(displayIndex.toString()),
                    ),
                    title: Text(
                      set.restDuration == Duration.zero
                          ? set.totalDuration.inMilliseconds.formatHMMSSCC()
                          : 'WORK: ${set.cardioDuration.inSeconds.formatHMMSS()} REST: ${set.restDuration.inSeconds.formatHMMSS()}',
                    ),
                    subtitle: Text(
                      set.restDuration == Duration.zero
                          ? 'STOPWATCH'
                          : 'INTERVAL',
                    ),
                    trailing: const Icon(Icons.more_vert),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// CardioTimer Text Widget to handle high-frequency timer updates.
class _CardioTimerText extends StatelessWidget {
  const _CardioTimerText({required this.mode});

  final CardioMode mode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch ONLY the values needed for the text.
    String timerText;
    if (mode == CardioMode.stopwatch) {
      timerText = StopwatchTimer.sFormattedStopwatchTime.watch(context);
    } else {
      timerText = IntervalTimer.sElapsedIntervalTime.watch(context).formatMSS();
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
