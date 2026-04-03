// Represents a Cardio training exercise.
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:hive_ce/hive.dart';

part 'cardio_model.g.dart';

@HiveType(typeId: 2)
class CardioExercise extends WorkoutExercise {
  CardioExercise({
    required super.id,
    required super.exerciseName,
    required super.imagePath,
    required this.equipment,
    required this.sets,
    this.cardioDurationInput,
    this.restDurationInput,
    this.distanceInput,
    this.caloriesInput,
    this.intensityInput,
  });

  @HiveField(3)
  final Equipment equipment;
  @HiveField(4)
  final List<CardioSet> sets;

  // Work-in-progress input fields for CardioExerciseScreen.
  @HiveField(5)
  final Duration? cardioDurationInput;
  @HiveField(6)
  final Duration? restDurationInput;
  @HiveField(7)
  final double? distanceInput;
  @HiveField(8)
  final int? caloriesInput;
  @HiveField(9)
  final int? intensityInput;

  @override
  CardioExercise copyWith({
    List<CardioSet>? sets,
    Duration? cardioDurationInput,
    Duration? restDurationInput,
    double? distanceInput,
    int? caloriesInput,
    int? intensityInput,
  }) {
    return CardioExercise(
      id: id,
      exerciseName: exerciseName,
      imagePath: imagePath,
      equipment: equipment,
      sets: sets ?? this.sets,
      cardioDurationInput: cardioDurationInput ?? this.cardioDurationInput,
      restDurationInput: restDurationInput ?? this.restDurationInput,
      distanceInput: distanceInput ?? this.distanceInput,
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
      (Duration sum, CardioSet set) {
        return sum + set.totalDuration;
      },
    );
  }

  double get totalDistance {
    return sets.fold(0, (double sum, CardioSet set) {
      return sum + (set.distance ?? 0);
    });
  }

  /// Calculates total calories for all sets in this exercise.
  int calculateTotalCalories({
    required double userWeight,
    required int userAge,
    required int userSex,
  }) {
    return sets.fold(0, (int sum, CardioSet set) {
      return sum +
          set.calculateEstimatedCalories(
            userWeight: userWeight,
            userAge: userAge,
            userSex: userSex,
          );
    });
  }

  // Legacy getter (might return 0 if sets.calories is null).
  int get totalCalories {
    return sets.fold(0, (int sum, CardioSet set) {
      return sum + (set.calories ?? 0);
    });
  }
}

@HiveType(typeId: 5)
class CardioSet {
  const CardioSet({
    required this.cardioDuration,
    required this.restDuration,
    required this.totalDuration,
    this.distance,
    this.calories,
    this.intensity,
  });

  @HiveField(0)
  final Duration cardioDuration;
  @HiveField(1)
  final Duration restDuration;
  @HiveField(2)
  final Duration totalDuration;
  @HiveField(3)
  final double? distance;
  @HiveField(4)
  final int? calories;
  @HiveField(5)
  final int? intensity;

  /// Calculates estimated calories burned based on MET values.
  /// If [userWeight] or [userAge] are 0, returns the stored [calories] or 0.
  /// [userSex] should be 0 for male, 1 for female.
  int calculateEstimatedCalories({
    required double userWeight,
    required int userAge,
    required int userSex,
  }) {
    if (calories != null) return calories!;
    if (userWeight <= 0) return 0;

    // MET (Metabolic Equivalent of Task) mapping for intensity levels
    // (0, 1, 2).
    double met;
    switch (intensity ?? 1) {
      case 0:
        met = 3.5; // Brisk walk / Light cardio
      case 2:
        met = 11.0; // Sprint / Hard cardio
      case 1:
      default:
        met = 7.0; // Jog / Moderate cardio
    }

    // Standard formula: Calories = MET * weight_kg * (duration_hours)
    final double durationHours = cardioDuration.inSeconds / 3600.0;
    double estimated = met * userWeight * durationHours;

    // Small adjustments for age and sex (simplified).
    if (userSex == 1) {
      // 1 = female
      estimated *= 0.9;
    }
    if (userAge > 40) {
      estimated *= 0.95;
    }

    return estimated.round();
  }
}
