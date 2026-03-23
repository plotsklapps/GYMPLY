import 'package:flutter/material.dart';
import 'package:gymply/modals/stretchsetstats_modal.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StretchSetBuilder extends StatelessWidget {
  const StretchSetBuilder({
    required this.exercise,
    required this.userWeight,
    required this.userAge,
    required this.userSex,
    super.key,
  });

  final StretchExercise exercise;
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
          final StretchSet set = exercise.sets.reversed.toList()[index];
          final String stretchTime = set.stretchDuration.inMilliseconds
              .formatHMMSSCC();
          final String restTime = set.restDuration.inSeconds.formatMSS();

          final String modeLabel = set.restDuration == Duration.zero
              ? 'STOPWATCH'
              : 'INTERVAL';
          final String caloriesLabel = userWeight > 0
              ? ' • ${set.calculateEstimatedCalories(
                  userWeight: userWeight,
                  userAge: userAge,
                  userSex: userSex,
                )} kcal'
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
                    : 'STRETCH: $stretchTime REST: $restTime',
              ),
              subtitle: Row(
                children: <Widget>[
                  Text('$modeLabel$caloriesLabel'),
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
                    workoutService.deleteStretchSet(exercise, set);
                  } else if (value == 'addStats') {
                    await ModalService.showModal(
                      context: context,
                      child: StretchSetStatsModal(
                        initialIntensity: set.intensity ?? 1,
                        onConfirm: (int intensity) {
                          // Update current set.
                          workoutService
                            ..updateStretchSet(
                              exercise,
                              set,
                              intensity: intensity,
                            )
                            // Stickily update exercise input.
                            ..updateStretchInput(
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
