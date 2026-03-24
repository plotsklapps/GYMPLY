import 'package:flutter/material.dart';
import 'package:gymply/modals/exercisehistory_modal.dart';
import 'package:gymply/modals/exercisestats_modal.dart';
import 'package:gymply/modals/intervaltimer_sheet.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/screens/exercisescreen/stretchset_builder.dart';
import 'package:gymply/screens/exercisescreen/stretchtimer_text.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

    // Watch personal stats for calorie calculation.
    final double userWeight = sWeight.watch(context);
    final int userAge = sAge.watch(context);
    final int userSex = sSex.watch(context);

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        // History Button.
                        IconButton(
                          onPressed: () async {
                            await ModalService.showModal(
                              context: context,
                              child: ExerciseHistoryModal(exercise: exercise),
                            );
                          },
                          icon: Icon(
                            LucideIcons.history,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        // Statistics Button.
                        IconButton(
                          onPressed: () async {
                            await ModalService.showModal(
                              context: context,
                              child: ExerciseStatsModal(exercise: exercise),
                            );
                          },
                          icon: Icon(
                            LucideIcons.chartColumn,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
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
                              ? const Icon(LucideIcons.circleCheck)
                              : null,
                          label: Text(
                            value.name.capitalizeFirst(),
                            style: theme.textTheme.titleLarge,
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) sStretchMode.value = value;
                          },
                        );
                      }).toList(),
                    ),
                    // Auto-Interval Switch.
                    if (mode == StretchMode.interval)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Auto',
                              style: theme.textTheme.titleMedium,
                            ),
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
                      await ModalService.showModal(
                        context: context,
                        child: const IntervalTimerSheet(),
                      );
                    }
                  },
                  child: StretchTimerText(mode: mode),
                ),

                // FAB ROW.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Reset FAB.
                    FloatingActionButton(
                      heroTag: 'stretchReset',
                      elevation: 0,
                      onPressed: () async {
                        // Check WorkoutType before reset.
                        if (mode == StretchMode.stopwatch) {
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
                      heroTag: 'stretchPlay',
                      elevation: 0,
                      onPressed: () async {
                        if (mode == StretchMode.stopwatch) {
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
                          (mode == StretchMode.stopwatch
                              ? isStopwatchRunning
                              : (isIntervalRunning || isRestRunning))
                          ? const Icon(LucideIcons.circlePause)
                          : const Icon(LucideIcons.circlePlay),
                    ),
                    const SizedBox(width: 8),

                    // Add set FAB.
                    FloatingActionButton(
                      heroTag: 'stretchAdd',
                      elevation: 0,
                      onPressed: () async {
                        // Check WorkoutType before adding set.
                        if (mode == StretchMode.stopwatch) {
                          await StopwatchTimer().pauseTimer();
                          final int elapsed =
                              StopwatchTimer.sElapsedStopwatchTime.value;
                          workoutService.addStretchSet(
                            exercise,
                            stretchDuration: Duration(milliseconds: elapsed),
                            restDuration: Duration.zero,
                            totalDuration: Duration(milliseconds: elapsed),
                            intensity: exercise.intensityInput ?? 1,
                          );
                          await StopwatchTimer().resetTimer();
                        } else {
                          await IntervalTimer().pauseTimer();
                          await RestTimer().pauseTimer();

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
                            intensity: exercise.intensityInput ?? 1,
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

          // SCROLLABLE SET LIST SECTION.
          StretchSetBuilder(
            exercise: exercise,
            userWeight: userWeight,
            userAge: userAge,
            userSex: userSex,
          ),
        ],
      ),
    );
  }
}
