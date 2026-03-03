import 'package:flutter/material.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/workout_service.dart';

class ExerciseDetailSheet extends StatelessWidget {
  const ExerciseDetailSheet({
    required this.exercise,
    super.key,
  });

  final ExercisePath exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Determine which Chips to show.
    final bool isCardio = exercise.muscleSegment == 'Cardio';
    final bool isStretch = exercise.equipmentSegment == 'Stretch';
    final bool isStrength = !isCardio && !isStretch;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                exercise.exerciseName,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                // MuscleGroup chip: Strength or Stretch
                if (isStrength || isStretch)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Chip(
                      padding: EdgeInsets.zero,
                      label: Text(
                        exercise.muscleSegment.capitalizeFirst(),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
                // Equipment chip: Strength or Cardio
                if (isStrength || isCardio)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Chip(
                      padding: EdgeInsets.zero,
                      label: Text(
                        exercise.equipmentSegment.capitalizeFirst(),
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              exercise.fullPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  // Add the exercise to today's workout
                  workoutService.addExercise(exercise);

                  // Pop the sheet.
                  Navigator.pop(context);

                  // Navigate to WorkoutScreen.
                  navigateToTab(AppTabs.workout);
                },
                child: const Text('ADD TO WORKOUT'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
