// Represents a Strength training exercise.
import 'dart:math' as math;

import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:hive_ce/hive.dart';

part 'strength_model.g.dart';

@HiveType(typeId: 1)
class StrengthExercise extends WorkoutExercise {
  StrengthExercise({
    required super.id,
    required super.exerciseName,
    required super.imagePath,
    required this.muscleGroup,
    required this.equipment,
    required this.sets,
    this.weightInput,
    this.repsInput,
  });

  @HiveField(3)
  final MuscleGroup muscleGroup;
  @HiveField(4)
  final Equipment equipment;
  @HiveField(5)
  final List<StrengthSet> sets;

  // Work-in-progress input fields for UI.
  @HiveField(6)
  final double? weightInput;
  @HiveField(7)
  final int? repsInput;

  @override
  StrengthExercise copyWith({
    List<StrengthSet>? sets,
    double? weightInput,
    int? repsInput,
  }) {
    return StrengthExercise(
      id: id,
      exerciseName: exerciseName,
      imagePath: imagePath,
      muscleGroup: muscleGroup,
      equipment: equipment,
      sets: sets ?? this.sets,
      weightInput: weightInput ?? this.weightInput,
      repsInput: repsInput ?? this.repsInput,
    );
  }

  // --- Getters for statistics ---

  @override
  int get totalSets {
    return sets.length;
  }

  int get totalReps {
    return sets.fold(0, (int sum, StrengthSet set) {
      return sum + set.reps;
    });
  }

  double get totalWeight {
    return sets.fold(0, (double sum, StrengthSet set) {
      return sum + (set.weight * set.reps);
    });
  }

  double get avgWeightPerRep {
    return totalReps == 0 ? 0 : totalWeight / totalReps;
  }

  double get avgWeightPerSet {
    return totalSets == 0 ? 0 : totalWeight / totalSets;
  }

  // Calculates 1RM using Brzycki Formula.
  double get oneRepMaxBrzycki {
    if (sets.isEmpty) return 0;
    double max1RM = 0;

    for (final StrengthSet set in sets) {
      if (set.reps > 0) {
        final double current1RM = set.oneRepMaxBrzycki;
        if (current1RM > max1RM) max1RM = current1RM;
      }
    }
    return max1RM;
  }

  // Calculates 1RM using Epley Formula.
  double get oneRepMaxEpley {
    if (sets.isEmpty) return 0;
    double max1RM = 0;

    for (final StrengthSet set in sets) {
      if (set.reps > 0) {
        final double current1RM = set.oneRepMaxEpley;
        if (current1RM > max1RM) max1RM = current1RM;
      }
    }
    return max1RM;
  }

  // Calculates 1RM using Lombardi Formula.
  double get oneRepMaxLombardi {
    if (sets.isEmpty) return 0;
    double max1RM = 0;

    for (final StrengthSet set in sets) {
      if (set.reps > 0) {
        final double current1RM = set.oneRepMaxLombardi;
        if (current1RM > max1RM) max1RM = current1RM;
      }
    }
    return max1RM;
  }
}

@HiveType(typeId: 4)
class StrengthSet {
  const StrengthSet({required this.weight, required this.reps});

  @HiveField(0)
  final double weight;
  @HiveField(1)
  final int reps;

  // --- 1RM Formulas ---

  double get oneRepMaxBrzycki {
    if (reps == 0) return 0;
    return weight / (1.0278 - (0.0278 * reps));
  }

  double get oneRepMaxEpley {
    if (reps == 0) return 0;
    return weight * (1 + (reps / 30));
  }

  double get oneRepMaxLombardi {
    if (reps == 0) return 0;
    return weight * math.pow(reps, 0.1);
  }
}
