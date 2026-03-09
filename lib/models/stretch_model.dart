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
    this.stretchDurationInput,
    this.restDurationInput,
    this.intensityInput,
  });

  @HiveField(3)
  final List<StretchSet> sets;

  // Work-in-progress input for stretching duration.
  @HiveField(4)
  final Duration? stretchDurationInput;

  @HiveField(5)
  final Duration? restDurationInput;

  @HiveField(6)
  final int? intensityInput;

  @override
  StretchExercise copyWith({
    List<StretchSet>? sets,
    Duration? stretchDurationInput,
    Duration? restDurationInput,
    int? intensityInput,
  }) {
    return StretchExercise(
      id: id,
      exerciseName: exerciseName,
      imagePath: imagePath,
      sets: sets ?? this.sets,
      stretchDurationInput: stretchDurationInput ?? this.stretchDurationInput,
      restDurationInput: restDurationInput ?? this.restDurationInput,
      intensityInput: intensityInput ?? this.intensityInput,
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
        return sum + set.totalDuration;
      },
    );
  }
}

@HiveType(typeId: 6)
class StretchSet {
  const StretchSet({
    required this.stretchDuration,
    required this.restDuration,
    required this.totalDuration,
    this.intensity,
  });

  @HiveField(0)
  final Duration stretchDuration;

  @HiveField(1)
  final Duration restDuration;

  @HiveField(2)
  final Duration totalDuration;

  @HiveField(3)
  final int? intensity;
}
