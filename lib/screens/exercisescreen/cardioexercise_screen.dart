import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/modals/cardiosetstats_modal.dart';
import 'package:gymply/modals/exercisehistory_modal.dart';
import 'package:gymply/modals/exercisestats_modal.dart';
import 'package:gymply/modals/intervaltimer_sheet.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
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

    // Watch personal stats for calorie calculation.
    final double userWeight = sWeight.watch(context);
    final int userAge = sAge.watch(context);
    final int userSex = sSex.watch(context); // 0 = male, 1 = female

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
                            size: 20,
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
                            size: 20,
                          ),
                        ),
                      ],
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
                      await ModalService.showModal(
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
                            intensity: exercise.intensityInput ?? 1,
                          );
                          await StopwatchTimer().resetTimer();
                        } else {
                          await IntervalTimer().pauseTimer();
                          await RestTimer().pauseTimer();

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
                          : 'CARDIO: '
                                '${set.cardioDuration.inMilliseconds.formatHMMSSCC()}'
                                ' REST: '
                                '${set.restDuration.inSeconds.formatMSS()}',
                    ),
                    subtitle: Row(
                      children: <Widget>[
                        Text(
                          '${set.restDuration == Duration.zero ? 'STOPWATCH' : 'INTERVAL'}'
                          '${set.distance != null ? ' • ${set.distance!.toStringAsFixed(2)} km' : ''}'
                          '${userWeight > 0 ? ' • ${set.calculateEstimatedCalories(userWeight: userWeight, userAge: userAge, userSex: userSex)} kcal' : ''}',
                        ),
                        const SizedBox(width: 8),
                        // Flame icons for intensity.
                        ...List<Widget>.generate(
                          (set.intensity ?? 1) + 1,
                          (int index) => Icon(
                            LucideIcons.flame,
                            size: 14,
                            color: (set.intensity ?? 1) == 2
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String value) async {
                        if (value == 'deleteSet') {
                          workoutService.deleteCardioSet(exercise, set);
                        } else if (value == 'addStats') {
                          await ModalService.showModal(
                            context: context,
                            child: CardioSetStatsModal(
                              initialDistance: set.distance ?? 0.0,
                              initialIntensity: set.intensity ?? 1,
                              onConfirm: (double distance, int intensity) {
                                // Update current set.
                                workoutService
                                  ..updateCardioSet(
                                    exercise,
                                    set,
                                    distance: distance,
                                    intensity: intensity,
                                  )
                                  // Stickily update exercise input.
                                  ..updateCardioInput(
                                    exercise,
                                    intensity: intensity,
                                  );
                              },
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'addStats',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text('Add Stats'),
                                SizedBox(width: 4),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.plus,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'deleteSet',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text('Delete Set'),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Center(
                                    child: Icon(
                                      LucideIcons.trash,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
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
