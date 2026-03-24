import 'package:gymply/models/workout_model.dart';
import 'package:signals/signals_flutter.dart';

// Signal for ALL workout history.
final Signal<List<Workout>> sWorkoutHistory = Signal<List<Workout>>(
  <Workout>[],
  debugLabel: 'sWorkoutHistory',
);
