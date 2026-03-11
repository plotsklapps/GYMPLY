import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/sheet_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/modals/intervaltimer_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

enum CardioMode { stopwatch, interval }

// Global CardioMode Signal
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
          // Fixed Top Section.
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
                        // History Button.
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            LucideIcons.history,
                            color: theme.colorScheme.secondary.withAlpha(150),
                          ),
                        ),
                        // Statistics Button.
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            LucideIcons.chartColumn,
                            color: theme.colorScheme.secondary.withAlpha(140),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    // Exercise Image.
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
                // CardioMode ChoiceChips.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Wrap(
                      spacing: 4,
                      children: CardioMode.values.map((CardioMode value) {
                        final bool isSelected = mode == value;
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: isSelected
                              ? const Icon(LucideIcons.circleCheck)
                              : null,
                          label: Text(
                            value.name.capitalizeFirst(),
                            style: theme.textTheme.titleLarge,
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) sCardioMode.value = value;
                          },
                        );
                      }).toList(),
                    ),
                    // Auto-Interval Switch.
                    if (mode == CardioMode.interval)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Auto', style: theme.textTheme.titleMedium),
                            Switch(
                              value: IntervalTimer.sAutoIntervalOn.watch(
                                context,
                              ),
                              onChanged: (bool value) {
                                IntervalTimer.sAutoIntervalOn.value = value;
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Timer.
                TextButton(
                  onPressed: () async {
                    if (mode != CardioMode.stopwatch) {
                      await SheetService.showSheet(
                        context: context,
                        child: const IntervalTimerSheet(),
                      );
                    }
                  },
                  child: CardioTimerText(mode: mode),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Reset FAB.
                    FloatingActionButton(
                      heroTag: 'cardioReset',
                      elevation: 0,
                      onPressed: () async {
                        // Give a bigger bzzz.
                        await HapticFeedback.heavyImpact();

                        if (mode == CardioMode.stopwatch) {
                          await StopwatchTimer().resetTimer();
                        } else {
                          await IntervalTimer().resetTimer();
                          await RestTimer().resetTimer();
                        }
                      },
                      child: const Icon(LucideIcons.circleX),
                    ),
                    const SizedBox(width: 8),
                    // Start/Pause FAB.
                    FloatingActionButton.large(
                      heroTag: 'cardioPlay',
                      elevation: 0,
                      onPressed: () async {
                        // Give a little bzzz.
                        await HapticFeedback.lightImpact();

                        if (mode == CardioMode.stopwatch) {
                          isStopwatchRunning
                              ? await StopwatchTimer().pauseTimer()
                              : await StopwatchTimer().startTimer();
                        } else {
                          if (isRestRunning) {
                            await RestTimer().pauseTimer();
                          } else if (isIntervalRunning) {
                            await IntervalTimer().pauseTimer();
                          } else {
                            await IntervalTimer().startTimer();
                          }
                        }
                      },
                      child:
                          (mode == CardioMode.stopwatch
                              ? isStopwatchRunning
                              : (isIntervalRunning || isRestRunning))
                          ? const Icon(LucideIcons.circlePause)
                          : const Icon(LucideIcons.circlePlay),
                    ),
                    const SizedBox(width: 8),
                    // Add set FAB.
                    FloatingActionButton(
                      heroTag: 'cardioAdd',
                      elevation: 0,
                      onPressed: () async {
                        // Give a little bzzz.
                        await HapticFeedback.lightImpact();

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
                          final int cardioMs =
                              IntervalTimer.sInitialIntervalTime.value;
                          final int restSec = RestTimer.sInitialRestTime.value;

                          workoutService.addCardioSet(
                            exercise,
                            cardioDuration: Duration(milliseconds: cardioMs),
                            restDuration: Duration(seconds: restSec),
                            totalDuration: Duration(
                              milliseconds: cardioMs + (restSec * 1000),
                            ),
                          );

                          await IntervalTimer().resetTimer();
                          await RestTimer().resetTimer();
                        }
                      },
                      child: const Icon(LucideIcons.circlePlus),
                    ),
                  ],
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
                          : 'CARDIO: ${set.cardioDuration.inMilliseconds.formatHMMSSCC()}'
                                ' REST: ${set.restDuration.inSeconds.formatMSS()}',
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
