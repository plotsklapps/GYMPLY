import 'package:signals/signals_flutter.dart';

// Signal to track the view mode of the exercises in search.
final Signal<bool> sExercisesGridMode = Signal<bool>(
  true,
  debugLabel: 'sExercisesGridMode',
);
