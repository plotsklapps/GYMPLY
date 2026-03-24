import 'package:signals/signals_flutter.dart';

// Signal to track favorite exercises (by id).
final Signal<List<int>> sFavoriteExercises = Signal<List<int>>(
  <int>[],
  debugLabel: 'sFavoriteExercises',
);
