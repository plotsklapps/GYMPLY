import 'package:flutter/material.dart';
import 'package:gymply/models/personalrecord_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StrengthSetCard extends StatelessWidget {
  const StrengthSetCard({
    required this.exercise,
    super.key,
  });

  final StrengthExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Expanded(
      child: Builder(
        builder: (BuildContext context) {
          // Fetch historical PRs.
          final PersonalRecord historicalPR = workoutService.getPersonalRecords(
            exercise.id,
            includeActive: false,
          );

          // Determine session peaks.
          double sessionMaxWeight = 0;
          double sessionMaxVolume = 0;
          for (final StrengthSet strengthSet in exercise.sets) {
            if (strengthSet.weight > sessionMaxWeight) {
              sessionMaxWeight = strengthSet.weight;
            }
            final double sessionVolume = strengthSet.weight * strengthSet.reps;
            if (sessionVolume > sessionMaxVolume) {
              sessionMaxVolume = sessionVolume;
            }
          }

          // Find index of first set that achieved these peaks.
          final int weightPRIndex = (sessionMaxWeight > historicalPR.maxWeight)
              ? exercise.sets.indexWhere(
                  (StrengthSet s) {
                    return s.weight == sessionMaxWeight;
                  },
                )
              : -1;

          final int volumePRIndex =
              (sessionMaxVolume > historicalPR.maxSetVolume)
              ? exercise.sets.indexWhere(
                  (StrengthSet s) {
                    return (s.weight * s.reps) == sessionMaxVolume;
                  },
                )
              : -1;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: exercise.sets.length,
            itemBuilder: (BuildContext context, int index) {
              // Reverse index for visual ordering (latest on top)
              final int displayIndex = exercise.sets.length - index;
              final int originalIndex = exercise.sets.length - 1 - index;
              final StrengthSet set = exercise.sets[originalIndex];

              // Logic to detect New PR
              final bool isWeightPR = originalIndex == weightPRIndex;
              final bool isVolumePR = originalIndex == volumePRIndex;
              final bool isNewPR = isWeightPR || isVolumePR;

              // PR Label text based on specifically what was broken.
              String prLabel = 'NEW PR!';
              final List<String> types = <String>[];
              if (isWeightPR) types.add('REP');
              if (isVolumePR) types.add('SET');

              if (types.length == 1) {
                prLabel = '${types.first} PR';
              } else if (types.length > 1) {
                prLabel = 'NEW PR!';
              }

              final String weight = set.weight.toStringAsFixed(0);
              final String reps = set.reps.toString();
              final double totalSetWeight = set.weight * set.reps;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isNewPR ? theme.colorScheme.secondary : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: isNewPR
                        ? Icon(
                            LucideIcons.trophy,
                            color: theme.colorScheme.secondary,
                          )
                        : Text(
                            displayIndex.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${totalSetWeight.toInt()} | $weight kg x $reps reps',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isNewPR ? theme.colorScheme.onSecondary : null,
                        ),
                      ),
                      if (isNewPR) ...<Widget>[
                        Text(
                          prLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(
                      LucideIcons.circleEllipsis,
                      color: isNewPR ? theme.colorScheme.onSecondary : null,
                    ),
                    onSelected: (String value) {
                      if (value == 'delete') {
                        workoutService.deleteStrengthSet(exercise, set);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Delete'),
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
          );
        },
      ),
    );
  }
}
