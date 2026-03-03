import 'package:flutter/material.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/exercisescreen/cardioexercise_screen.dart';
import 'package:gymply/screens/exercisescreen/strengthexercise_screen.dart';
import 'package:gymply/screens/exercisescreen/stretchexercise_screen.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:signals/signals_flutter.dart';

// Dispatcher class. Decide which exercisescreen to show.
class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch selected exercise from WorkoutService.
    final WorkoutExercise? exercise = workoutService.sSelectedExercise.watch(
      context,
    );

    // Show Placeholder if no exercise is selected.
    if (exercise == null) {
      return const Scaffold(
        body: Center(
          child: Text('Select an exercise from your workout to start logging.'),
        ),
      );
    }

    // Dispatch logic: Return the specialized screen based on type.
    return switch (exercise) {
      final StrengthExercise strengthExercise => StrengthExerciseScreen(
        exercise: strengthExercise,
      ),
      final CardioExercise cardioExercise => CardioExerciseScreen(
        exercise: cardioExercise,
      ),
      final StretchExercise stretchExercise => StretchExerciseScreen(
        exercise: stretchExercise,
      ),
      WorkoutExercise() => throw UnimplementedError(),
    };
  }
}
