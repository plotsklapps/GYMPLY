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
    this.caloriesInput,
    this.intensityInput,
  });

  @HiveField(3)
  final List<StretchSet> sets;

  // Work-in-progress input fields for StretchExerciseScreen.
  @HiveField(4)
  final Duration? stretchDurationInput;
  @HiveField(5)
  final Duration? restDurationInput;
  @HiveField(6)
  final int? caloriesInput;
  @HiveField(7)
  final int? intensityInput;

  @override
  StretchExercise copyWith({
    List<StretchSet>? sets,
    Duration? stretchDurationInput,
    Duration? restDurationInput,
    int? caloriesInput,
    int? intensityInput,
  }) {
    return StretchExercise(
      id: id,
      exerciseName: exerciseName,
      imagePath: imagePath,
      sets: sets ?? this.sets,
      stretchDurationInput: stretchDurationInput ?? this.stretchDurationInput,
      restDurationInput: restDurationInput ?? this.restDurationInput,
      caloriesInput: caloriesInput ?? this.caloriesInput,
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

  /// Calculates total calories for all sets in this exercise.
  int calculateTotalCalories({
    required double userWeight,
    required int userAge,
    required int userSex,
  }) {
    return sets.fold(0, (int sum, StretchSet set) {
      return sum +
          set.calculateEstimatedCalories(
            userWeight: userWeight,
            userAge: userAge,
            userSex: userSex,
          );
    });
  }

  // Legacy getter.
  int get totalCalories {
    return sets.fold(0, (int sum, StretchSet set) {
      return sum + (set.calories ?? 0);
    });
  }
}

@HiveType(typeId: 6)
class StretchSet {
  const StretchSet({
    required this.stretchDuration,
    required this.restDuration,
    required this.totalDuration,
    this.calories,
    this.intensity,
  });

  @HiveField(0)
  final Duration stretchDuration;
  @HiveField(1)
  final Duration restDuration;
  @HiveField(2)
  final Duration totalDuration;
  @HiveField(3)
  final int? calories;
  @HiveField(4)
  final int? intensity;

  /// Calculates estimated calories burned based on MET values.
  /// Stretching usually has a low MET (around 2.3).
  int calculateEstimatedCalories({
    required double userWeight,
    required int userAge,
    required int userSex,
  }) {
    if (calories != null) return calories!;
    if (userWeight <= 0) return 0;

    // MET mapping for intensity levels (0, 1, 2).
    double met;
    switch (intensity ?? 1) {
      case 0:
        met = 1.8; // Static stretching
      case 2:
        met = 3.5; // Dynamic/Hard stretching
      case 1:
      default:
        met = 2.3; // Moderate stretching
    }

    // Standard formula: Calories = MET * weight_kg * (duration_hours)
    final double durationHours = stretchDuration.inSeconds / 3600.0;
    double estimated = met * userWeight * durationHours;

    // Small adjustments for age and sex.
    if (userSex == 1) estimated *= 0.9;
    if (userAge > 40) estimated *= 0.95;

    return estimated.round();
  }
}
