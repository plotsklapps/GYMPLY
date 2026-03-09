import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/services/audio_service.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/sheet_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/sheets/intervaltimer_sheet.dart';
import 'package:signals/signals_flutter.dart';

enum StretchMode { stopwatch, interval }

// Global StretchMode Signal.
final Signal<StretchMode> sStretchMode = Signal<StretchMode>(
  StretchMode.stopwatch,
  debugLabel: 'sStretchMode',
);

class StretchExerciseScreen extends StatelessWidget {
  const StretchExerciseScreen({
    required this.exercise,
    super.key,
  });

  final StretchExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final StretchMode mode = sStretchMode.watch(context);
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
          // FIXED TOP SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // History Button.
                        IconButton(
                          onPressed: () {},
                          icon: FaIcon(
                            FontAwesomeIcons.clockRotateLeft,
                            color: theme.colorScheme.secondary.withAlpha(150),
                          ),
                        ),
                        // Statistics Button.
                        IconButton(
                          onPressed: () {},
                          icon: FaIcon(
                            FontAwesomeIcons.chartColumn,
                            color: theme.colorScheme.secondary.withAlpha(150),
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
                // StretchMode ChoiceChips.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Wrap(
                      spacing: 4,
                      children: StretchMode.values.map((StretchMode value) {
                        final bool isSelected = mode == value;
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: isSelected
                              ? const FaIcon(FontAwesomeIcons.solidCircleCheck)
                              : null,
                          label: Text(
                            value.name.capitalizeFirst(),
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) sStretchMode.value = value;
                          },
                        );
                      }).toList(),
                    ),
                    // AUTO-INTERVAL SWITCH.
                    if (mode == StretchMode.interval)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text('Auto'),
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
                    if (mode != StretchMode.stopwatch) {
                      await SheetService.showSheet(
                        context: context,
                        child: const IntervalTimerSheet(),
                      );
                    }
                  },
                  child: StretchTimerText(mode: mode),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Reset FAB.
                    FloatingActionButton(
                      heroTag: 'stretchReset',
                      elevation: 0,
                      onPressed: () async {
                        if (mode == StretchMode.stopwatch) {
                          await StopwatchTimer().resetTimer();
                        } else {
                          await IntervalTimer().resetTimer();
                          await RestTimer().resetTimer();
                        }
                      },
                      child: const FaIcon(FontAwesomeIcons.solidCircleXmark),
                    ),
                    const SizedBox(width: 8),
                    // Start/Pause FAB.
                    FloatingActionButton.large(
                      heroTag: 'stretchPlay',
                      elevation: 4,
                      onPressed: () async {
                        // Critical for PWA: Initialize audio on first user tap.
                        await AudioService().initialize();

                        if (mode == StretchMode.stopwatch) {
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
                          (mode == StretchMode.stopwatch
                              ? isStopwatchRunning
                              : (isIntervalRunning || isRestRunning))
                          ? const FaIcon(FontAwesomeIcons.solidCirclePause)
                          : const FaIcon(FontAwesomeIcons.solidCirclePlay),
                    ),
                    const SizedBox(width: 8),
                    // Add set FAB.
                    FloatingActionButton(
                      heroTag: 'stretchAdd',
                      elevation: 0,
                      onPressed: () async {
                        if (mode == StretchMode.stopwatch) {
                          await StopwatchTimer().pauseTimer();
                          final int elapsed =
                              StopwatchTimer.sElapsedStopwatchTime.value;
                          workoutService.addStretchSet(
                            exercise,
                            stretchDuration: Duration(milliseconds: elapsed),
                            restDuration: Duration.zero,
                            totalDuration: Duration(milliseconds: elapsed),
                          );
                          await StopwatchTimer().resetTimer();
                        } else {
                          IntervalTimer().pauseTimer();
                          RestTimer().pauseTimer();

                          // Log the full prescribed interval + rest.
                          final int stretchMs =
                              IntervalTimer.sInitialIntervalTime.value;
                          final int restSec = RestTimer.sInitialRestTime.value;

                          workoutService.addStretchSet(
                            exercise,
                            stretchDuration: Duration(milliseconds: stretchMs),
                            restDuration: Duration(seconds: restSec),
                            totalDuration: Duration(
                              milliseconds: stretchMs + (restSec * 1000),
                            ),
                          );

                          await IntervalTimer().resetTimer();
                          await RestTimer().resetTimer();
                        }
                      },
                      child: const FaIcon(FontAwesomeIcons.circlePlus),
                    ),
                    Expanded(
                      child: Text(
                        exercise.exerciseName,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: FaIcon(
                        FontAwesomeIcons.clockRotateLeft,
                        color: theme.colorScheme.secondary.withAlpha(140),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                // 2. Exercise Image.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    exercise.imagePath,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text('Stretch logging coming soon...'),
                ),
                const SizedBox(height: 32),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CardioTimer Text Widget to handle high-frequency timer updates.
class StretchTimerText extends StatelessWidget {
  const StretchTimerText({
    required this.mode,
    super.key,
  });

  final StretchMode mode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch ONLY the values needed for the text.
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
