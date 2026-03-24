import 'package:gymply/models/workout_model.dart';
import 'package:signals/signals_flutter.dart';

// Signal to track active exercise in ExerciseScreen.
final Signal<WorkoutExercise?> sSelectedExercise = Signal<WorkoutExercise?>(
  null,
  debugLabel: 'sSelectedExercise',
);
