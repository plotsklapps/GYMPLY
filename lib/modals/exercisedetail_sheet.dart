import 'package:flutter/material.dart';
import 'package:gymply/modals/exercisehistory_modal.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

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

    // Watch the favorite IDs list.
    final List<int> favoriteIds = workoutService.sFavoriteExercises.watch(
      context,
    );
    final int exerciseId = int.parse(exercise.id);
    final bool isFavorite = favoriteIds.contains(exerciseId);

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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                // History button.
                IconButton(
                  onPressed: () async {
                    // Create a temporary WorkoutExercise to pass to modal.
                    final WorkoutExercise dummy;
                    if (isCardio) {
                      dummy = CardioExercise(
                        id: exerciseId,
                        exerciseName: exercise.exerciseName,
                        imagePath: exercise.fullPath,
                        equipment: Equipment.values.byName(
                          exercise.equipmentSegment.toLowerCase(),
                        ),
                        sets: <CardioSet>[],
                      );
                    } else if (isStretch) {
                      dummy = StretchExercise(
                        id: exerciseId,
                        exerciseName: exercise.exerciseName,
                        imagePath: exercise.fullPath,
                        sets: <StretchSet>[],
                      );
                    } else {
                      dummy = StrengthExercise(
                        id: exerciseId,
                        exerciseName: exercise.exerciseName,
                        imagePath: exercise.fullPath,
                        muscleGroup: MuscleGroup.values.byName(
                          exercise.muscleSegment.toLowerCase(),
                        ),
                        equipment: Equipment.values.byName(
                          exercise.equipmentSegment.toLowerCase(),
                        ),
                        sets: <StrengthSet>[],
                      );
                    }

                    await ModalService.showModal(
                      context: context,
                      child: ExerciseHistoryModal(exercise: dummy),
                    );
                  },
                  icon: const Icon(LucideIcons.history),
                ),
                // Favorite button.
                IconButton(
                  onPressed: () {
                    workoutService.toggleFavorite(exerciseId);
                  },
                  icon: Icon(
                    isFavorite ? LucideIcons.star : LucideIcons.starHalf,
                    color: isFavorite ? theme.colorScheme.secondary : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            exercise.fullPath,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Pop and return false.
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  // Pop and return true.
                  Navigator.pop(context, true);
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
