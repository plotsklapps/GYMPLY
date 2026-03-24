import 'package:gymply/models/exercise_model.dart';
import 'package:signals/signals_flutter.dart';

// Signal to track the selected muscle group.
final Signal<MuscleGroup?> sSelectedMuscleGroup = Signal<MuscleGroup?>(
  null,
  debugLabel: 'sSelectedMuscleGroup',
);
