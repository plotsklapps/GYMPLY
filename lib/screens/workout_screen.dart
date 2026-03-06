import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:signals/signals_flutter.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch the active workout.
    final Workout workout = workoutService.sActiveWorkout.watch(context);

    if (workout.isEmpty) {
      return const Center(
        child: Text('No exercises added to your workout yet.'),
      );
    }

    // Reverse the list so the newest exercise appears at the top.
    final List<WorkoutExercise> reversedExercises = workout.exercises.reversed
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reversedExercises.length,
      itemBuilder: (BuildContext context, int index) {
        final WorkoutExercise exercise = reversedExercises[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                exercise.imagePath,
                width: 100,
                fit: BoxFit.contain,
              ),
            ),
            title: Text(
              exercise.exerciseName,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(_getSubtitle(exercise)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'delete') {
                  // Calls the service to delete the entire exercise from the workout.
                  workoutService.deleteExercise(exercise);
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        FaIcon(
                          FontAwesomeIcons.trashCan,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        const Text('Delete'),
                      ],
                    ),
                  ),
                ];
              },
            ),
            onTap: () {
              // Set selected exercise and navigate.
              workoutService.sSelectedExercise.value = exercise;
              navigateToTab(AppTabs.exercise);
            },
          ),
        );
      },
    );
  }

  String _getSubtitle(WorkoutExercise exercise) {
    if (exercise is StrengthExercise) {
      return '${exercise.muscleGroup.name.capitalizeFirst()} • ${exercise.equipment.name.capitalizeFirst()}';
    } else if (exercise is CardioExercise) {
      return 'Cardio • ${exercise.equipment.name.capitalizeFirst()}';
    } else if (exercise is StretchExercise) {
      return 'Stretch';
    }
    return '';
  }
}
