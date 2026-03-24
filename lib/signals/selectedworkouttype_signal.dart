import 'package:gymply/models/exercise_model.dart';
import 'package:signals/signals_flutter.dart';

// Signal to track selected WorkoutType (Strength/Cardio/Stretch).
final Signal<WorkoutType?> sSelectedWorkoutType = Signal<WorkoutType?>(
  null,
  debugLabel: 'sSelectedWorkoutType',
);
