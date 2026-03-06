// Represents a Stretch training exercise.
import 'package:gymply/models/workout_model.dart';
import 'package:hive_ce/hive.dart';

part 'stretch_model.g.dart';

@HiveType(typeId: 3)
class StretchExercise extends WorkoutExercise {
  StretchExercise({
    required super.id,
    required super.exerciseName,
    required super.imagePath,
    required this.sets,
    this.holdInput,
  });

  @HiveField(3)
  final List<StretchSet> sets;

  // Work-in-progress input for stretching duration.
  @HiveField(4)
  final int? holdInput;

  @override
  StretchExercise copyWith({
    List<StretchSet>? sets,
    int? holdInput,
  }) {
    return StretchExercise(
      id: id,
      exerciseName: exerciseName,
      imagePath: imagePath,
      sets: sets ?? this.sets,
      holdInput: holdInput ?? this.holdInput,
    );
  }

  // --- Getters for statistics ---

  @override
  int get totalSets {
    return sets.length;
  }

  Duration get totalDuration {
    return sets.fold(
      Duration.zero,
      (Duration sum, StretchSet set) {
        return sum + set.duration;
      },
    );
  }
}

@HiveType(typeId: 6)
class StretchSet {
  const StretchSet({required this.duration});

  @HiveField(0)
  final Duration duration;
}
