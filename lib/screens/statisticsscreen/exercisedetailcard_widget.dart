import 'package:flutter/material.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:signals/signals_flutter.dart';

class ExerciseDetailCard extends StatelessWidget {
  const ExerciseDetailCard({
    required this.exercise,
    super.key,
  });

  final WorkoutExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> detailRows = <Widget>[];

    if (exercise is StrengthExercise) {
      final StrengthExercise ex = exercise as StrengthExercise;
      detailRows.addAll(<Widget>[
        ExerciseDetailRow(
          label: 'Muscle Group',
          value: ex.muscleGroup.name.toUpperCase(),
        ),
        ExerciseDetailRow(
          label: 'Equipment',
          value: ex.equipment.name.toUpperCase(),
        ),
        ExerciseDetailRow(label: 'Sets', value: ex.totalSets.toString()),
        ExerciseDetailRow(label: 'Reps', value: ex.totalReps.toString()),
        ExerciseDetailRow(
          label: 'Volume',
          value: '${ex.totalWeight.toStringAsFixed(1)} kg',
        ),
        ExerciseDetailRow(
          label: 'Avg Weight/Rep',
          value: '${ex.avgWeightPerRep.toStringAsFixed(1)} kg',
        ),
        ExerciseDetailRow(
          label: 'Avg Weight/Set',
          value: '${ex.avgWeightPerSet.toStringAsFixed(1)} kg',
        ),
        Divider(height: 24, color: theme.colorScheme.secondary),
        Text(
          '1RM Estimates',
          style: theme.textTheme.titleMedium,
        ),
        ExerciseDetailRow(
          label: 'Lombardi (rep range 1-5)',
          value: '${ex.oneRepMaxLombardi.toStringAsFixed(1)} kg',
        ),
        ExerciseDetailRow(
          label: 'Brzycki (rep range 5-10)',
          value: '${ex.oneRepMaxBrzycki.toStringAsFixed(1)} kg',
        ),
        ExerciseDetailRow(
          label: 'Epley (rep range 1-10)',
          value: '${ex.oneRepMaxEpley.toStringAsFixed(1)} kg',
        ),
      ]);
    } else if (exercise is CardioExercise) {
      final CardioExercise ex = exercise as CardioExercise;

      // Watch personal stats for calorie calculation.
      final double userWeight = sWeight.watch(context);
      final int userAge = sAge.watch(context);
      final int userSex = sSex.watch(context);

      detailRows.addAll(<Widget>[
        ExerciseDetailRow(
          label: 'Equipment',
          value: ex.equipment.name.toUpperCase(),
        ),
        ExerciseDetailRow(label: 'Sets', value: ex.totalSets.toString()),
        ExerciseDetailRow(
          label: 'Duration',
          value: ex.totalDuration.format(),
        ),
        ExerciseDetailRow(
          label: 'Distance',
          value: '${ex.totalDistance.toStringAsFixed(2)} km',
        ),
        ExerciseDetailRow(
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
      detailRows.addAll(<Widget>[
        ExerciseDetailRow(label: 'Sets', value: ex.totalSets.toString()),
        ExerciseDetailRow(
          label: 'Duration',
          value: ex.totalDuration.format(),
        ),
      ]);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          if (exercise.imagePath.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 80 / 255,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.asset(
                    exercise.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exercise.exerciseName.capitalizeAll(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ...detailRows,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseDetailRow extends StatelessWidget {
  const ExerciseDetailRow({
    required this.label,
    required this.value,
    super.key,
  });
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
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
    );
  }
}
