import 'package:flutter/material.dart';
import 'package:gymply/modals/cardiosetstats_modal.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CardioSetCard extends StatelessWidget {
  const CardioSetCard({
    required this.exercise,
    required this.userWeight,
    required this.userAge,
    required this.userSex,
    super.key,
  });

  final CardioExercise exercise;
  final double userWeight;
  final int userAge;
  final int userSex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: exercise.sets.length,
        itemBuilder: (BuildContext context, int index) {
          final int displayIndex = exercise.sets.length - index;
          final CardioSet set = exercise.sets.reversed.toList()[index];
          final String cardioTime = set.cardioDuration.inMilliseconds
              .formatHMMSSCC();
          final String restTime = set.restDuration.inSeconds.formatMSS();
          final String modeLabel = set.restDuration == Duration.zero
              ? 'STOPWATCH'
              : 'INTERVAL';
          final String distanceLabel = set.distance != null
              ? ' • ${set.distance!.toStringAsFixed(2)} km'
              : '';
          final String caloriesLabel = userWeight > 0
              ? ' • ${set.calculateEstimatedCalories(
                  userWeight: userWeight,
                  userAge: userAge,
                  userSex: userSex,
                )} kcal'
              : '';
          final String repsLabel = (set.reps != null && set.reps! > 0)
              ? ' • ${set.reps} reps'
              : '';

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
                    : 'CARDIO: $cardioTime REST: $restTime',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Row(
                children: <Widget>[
                  Text('$modeLabel$distanceLabel$caloriesLabel$repsLabel'),
                  const SizedBox(width: 8),
                  // Flame icons for intensity.
                  ...List<Widget>.generate(
                    (set.intensity ?? 1) + 1,
                    (int index) {
                      return Icon(
                        LucideIcons.flame,
                        size: 14,
                        color: (set.intensity ?? 1) == 2
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      );
                    },
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(LucideIcons.circleEllipsis),
                onSelected: (String value) async {
                  if (value == 'deleteSet') {
                    workoutService.deleteCardioSet(exercise, set);
                  } else if (value == 'addStats') {
                    // Logic to retrieve sticky values from exercise
                    // or fallback to defaults.
                    final double stickyDistance =
                        (set.distance != null && set.distance! > 0)
                        ? set.distance!
                        : (exercise.distanceInput ?? 0.0);

                    final int stickyIntensity =
                        (set.intensity != null && set.intensity! > 0)
                        ? set.intensity!
                        : (exercise.intensityInput ?? 1);

                    final int stickyReps = (set.reps != null && set.reps! > 0)
                        ? set.reps!
                        : (exercise.repsInput ?? 1);

                    await ModalService.showModal(
                      context: context,
                      child: CardioSetStatsModal(
                        // Retrieve previous input for faster logging.
                        initialDistance: stickyDistance,
                        initialIntensity: stickyIntensity,
                        initialReps: stickyReps,
                        onConfirm: (double distance, int intensity, int reps) {
                          // Update current set and sticky input.
                          workoutService.updateCardioSet(
                            exercise,
                            set,
                            intensity: intensity,
                            distance: distance,
                            reps: reps,
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
                              child: Icon(LucideIcons.plus),
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
    );
  }
}
