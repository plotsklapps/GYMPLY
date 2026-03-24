import 'package:gymply/models/exercise_model.dart';
import 'package:signals/signals_flutter.dart';

// Raw data: Signal holds complete, unfiltered list of all exercises.
final Signal<List<ExercisePath>> sAllExercisePaths = Signal<List<ExercisePath>>(
  <ExercisePath>[],
);
