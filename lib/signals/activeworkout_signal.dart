import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

// Signal to track current active workout (defaults to today).
final Signal<Workout> sActiveWorkout = Signal<Workout>(
  Workout(
    id: const Uuid().v4(),
    title: DateTime.now().defaultWorkoutTitle,
    dateTime: DateTime.now(),
    totalDuration: 0,
  ),
  debugLabel: 'sActiveWorkout',
);
