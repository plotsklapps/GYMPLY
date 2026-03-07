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

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _isMoveMode = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final Workout workout = workoutService.sActiveWorkout.watch(context);

    if (workout.isEmpty) {
      return const Center(
        child: Text('No exercises added to your workout yet.'),
      );
    }

    // Reverse list so newest exercise appears at top.
    final List<WorkoutExercise> reversedExercises = workout.exercises.reversed
        .toList();

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reversedExercises.length,
      // Use custom handle.
      buildDefaultDragHandles: false,
      onReorder: (int oldIndex, int newIndex) {
        // Map reversed indices back to original indices for WorkoutService.
        final int originalOldIndex = workout.exercises.length - 1 - oldIndex;
        final int originalNewIndex = workout.exercises.length - newIndex;

        workoutService.moveExercise(originalOldIndex, originalNewIndex);
      },
      onReorderEnd: (int index) {
        // Disable MoveMode when drag is done.
        setState(() {
          _isMoveMode = false;
        });
      },
      itemBuilder: (BuildContext context, int index) {
        final WorkoutExercise exercise = reversedExercises[index];

        return Card(
          key: ValueKey<WorkoutExercise>(exercise),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Image.asset(
              exercise.imagePath,
              width: 120,
              fit: BoxFit.contain,
            ),
            title: Text(
              exercise.exerciseName,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_getSubtitle(exercise)),
            trailing: _isMoveMode
                ? ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: FaIcon(FontAwesomeIcons.grip),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
                    onSelected: (String value) {
                      if (value == 'delete') {
                        // Delete entire exercise from workout.
                        workoutService.deleteExercise(exercise);
                      } else if (value == 'move') {
                        setState(() {
                          _isMoveMode = true;
                        });
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'move',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Move'),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.arrowsUpDown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                  child: FaIcon(
                                    FontAwesomeIcons.trashCan,
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
            onTap: _isMoveMode
                ? null
                : () {
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
