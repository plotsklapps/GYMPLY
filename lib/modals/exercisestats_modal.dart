import 'package:flutter/material.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/personalrecord_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class ExerciseStatsModal extends StatelessWidget {
  const ExerciseStatsModal({
    required this.exercise,
    super.key,
  });

  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> detailRows = <Widget>[];

    // Build statistics rows based on exercise type.
    if (exercise is StrengthExercise) {
      final StrengthExercise ex = exercise as StrengthExercise;
      detailRows.addAll(<Widget>[
        _StatRow(
          label: 'Muscle Group',
          value: ex.muscleGroup.name.toUpperCase(),
        ),
        _StatRow(
          label: 'Equipment',
          value: ex.equipment.name.toUpperCase(),
        ),
        _StatRow(label: 'Sets', value: ex.totalSets.toString()),
        _StatRow(label: 'Reps', value: ex.totalReps.toString()),
        _StatRow(
          label: 'Volume',
          value: '${ex.totalWeight.toStringAsFixed(1)} kg',
        ),
        _StatRow(
          label: 'Avg Weight/Rep',
          value: '${ex.avgWeightPerRep.toStringAsFixed(1)} kg',
        ),
        _StatRow(
          label: 'Avg Weight/Set',
          value: '${ex.avgWeightPerSet.toStringAsFixed(1)} kg',
        ),
      ]);
    } else if (exercise is CardioExercise) {
      final CardioExercise ex = exercise as CardioExercise;

      // Watch personal stats for calorie calculation.
      final double userWeight = sWeight.watch(context);
      final int userAge = sAge.watch(context);
      final int userSex = sSex.watch(context);

      detailRows.addAll(<Widget>[
        _StatRow(
          label: 'Equipment',
          value: ex.equipment.name.toUpperCase(),
        ),
        _StatRow(label: 'Sets', value: ex.totalSets.toString()),
        _StatRow(
          label: 'Duration',
          value: ex.totalDuration.format(),
        ),
        _StatRow(
          label: 'Distance',
          value: '${ex.totalDistance.toStringAsFixed(2)} km',
        ),
        _StatRow(
          label: 'Calories',
          value:
              '${ex.calculateTotalCalories(
                userWeight: userWeight,
                userAge: userAge,
                userSex: userSex,
              )} kcal',
        ),
      ]);
    } else if (exercise is StretchExercise) {
      final StretchExercise ex = exercise as StretchExercise;

      // Watch personal stats for calorie calculation.
      final double userWeight = sWeight.watch(context);
      final int userAge = sAge.watch(context);
      final int userSex = sSex.watch(context);

      detailRows.addAll(<Widget>[
        _StatRow(label: 'Sets', value: ex.totalSets.toString()),
        _StatRow(
          label: 'Duration',
          value: ex.totalDuration.format(),
        ),
        _StatRow(
          label: 'Calories',
          value:
              '${ex.calculateTotalCalories(
                userWeight: userWeight,
                userAge: userAge,
                userSex: userSex,
              )} kcal',
        ),
      ]);
    }

    // --- Personal Records Section ---
    detailRows
      ..add(
        Divider(height: 32, color: theme.colorScheme.outlineVariant),
      )
      ..add(
        Builder(
          builder: (BuildContext context) {
            final PersonalRecord pr = workoutService.getPersonalRecords(
              exercise.id,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1RM Estimates (Strength only).
                if (exercise is StrengthExercise &&
                    pr.oneRepMaxLombardi > 0) ...<Widget>[
                  Text(
                    '1RM Estimates',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Lombardi (rep range 1-5)',
                    value: '${pr.oneRepMaxLombardi.toStringAsFixed(1)} kg',
                  ),
                  _StatRow(
                    label: 'Brzycki (rep range 5-10)',
                    value: '${pr.oneRepMaxBrzycki.toStringAsFixed(1)} kg',
                  ),
                  _StatRow(
                    label: 'Epley (rep range 1-10)',
                    value: '${pr.oneRepMaxEpley.toStringAsFixed(1)} kg',
                  ),
                  Divider(height: 32, color: theme.colorScheme.outlineVariant),
                ],

                Text(
                  'Personal Records',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (exercise is StrengthExercise) ...<Widget>[
                  _StatRow(
                    label: 'Max Weight',
                    value: '${pr.maxWeight.toStringAsFixed(1)} kg',
                  ),
                  _StatRow(
                    label: 'Max Set Volume',
                    value: '${pr.maxSetVolume.toStringAsFixed(1)} kg',
                  ),
                  _StatRow(
                    label: 'Max Exercise Volume',
                    value: '${pr.maxExerciseVolume.toStringAsFixed(1)} kg',
                  ),
                ] else if (exercise is CardioExercise) ...<Widget>[
                  _StatRow(
                    label: 'Max Time',
                    value: pr.maxSetDuration.format(),
                  ),
                  _StatRow(
                    label: 'Max Distance',
                    value: '${pr.maxDistance.toStringAsFixed(2)} km',
                  ),
                  _StatRow(
                    label: 'Session PR',
                    value: pr.maxTotalDuration.format(),
                  ),
                ] else if (exercise is StretchExercise) ...<Widget>[
                  _StatRow(
                    label: 'Max Hold',
                    value: pr.maxSetDuration.format(),
                  ),
                  _StatRow(
                    label: 'Stretches PR',
                    value: '${pr.maxExerciseStretches} stretches',
                  ),
                  _StatRow(
                    label: 'Session PR',
                    value: pr.maxTotalDuration.format(),
                  ),
                ],
              ],
            );
          },
        ),
      );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header with centered title and close button on the right.
        Row(
          children: <Widget>[
            const SizedBox(width: 48), // Balance the close button.
            Expanded(
              child: Text(
                exercise.exerciseName.capitalizeAll(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),
        ...detailRows,
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
