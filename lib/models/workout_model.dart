import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';

part 'workout_model.g.dart';

// Main container for a single workout session.
@HiveType(typeId: 0)
class Workout {
  Workout({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.totalDuration,
    this.exercises = const <WorkoutExercise>[],
    this.notes = '',
    this.imagePaths = const <String>[],
  });

  @HiveField(0, defaultValue: '')
  final String id;
  @HiveField(1, defaultValue: '')
  final String title;
  @HiveField(2)
  final DateTime dateTime;
  @HiveField(3, defaultValue: 0)
  final int totalDuration;
  @HiveField(4, defaultValue: <WorkoutExercise>[])
  final List<WorkoutExercise> exercises;
  @HiveField(5, defaultValue: '')
  final String notes;
  @HiveField(6, defaultValue: <String>[])
  final List<String> imagePaths;

  Workout copyWith({
    String? title,
    int? totalDuration,
    List<WorkoutExercise>? exercises,
    String? notes,
    List<String>? imagePaths,
  }) {
    return Workout(
      id: id,
      title: title ?? this.title,
      dateTime: dateTime,
      totalDuration: totalDuration ?? this.totalDuration,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  // --- Date Helpers ---

  // Return date formatted as YYYYMMDD.
  String get dateKey {
    return DateFormat('yyyyMMdd').format(dateTime);
  }

  String get formattedDate {
    return DateFormat.yMMMMd().format(dateTime);
  }

  // --- Aggregate Statistics ---

  int get exerciseCount {
    return exercises.length;
  }

  bool get isEmpty {
    return exercises.isEmpty;
  }

  int get strengthExerciseCount {
    return exercises.whereType<StrengthExercise>().length;
  }

  int get cardioExerciseCount {
    return exercises.whereType<CardioExercise>().length;
  }

  int get stretchExerciseCount {
    return exercises.whereType<StretchExercise>().length;
  }

  // Total sets across all exercise types.
  int get totalSets {
    return exercises.fold(
      0,
      (int sum, WorkoutExercise ex) {
        return sum + ex.totalSets;
      },
    );
  }

  // --- Strength Summaries ---

  // Total weight moved (Weight * Reps) for all strength exercises.
  double get totalStrengthVolume {
    return exercises.whereType<StrengthExercise>().fold(
      0,
      (double sum, StrengthExercise ex) {
        return sum + ex.totalWeight;
      },
    );
  }

  // Total number of repetitions performed across all strength exercises.
  int get totalReps {
    return exercises.whereType<StrengthExercise>().fold(
      0,
      (int sum, StrengthExercise ex) {
        return sum + ex.totalReps;
      },
    );
  }

  // Average weight per rep across the entire workout.
  double get avgWorkoutWeight {
    final int reps = totalReps;
    return reps == 0 ? 0 : totalStrengthVolume / reps;
  }

  // --- Cardio Summaries ---

  // Total distance covered across all cardio exercises (in km).
  double get totalCardioDistance {
    return exercises.whereType<CardioExercise>().fold(
      0,
      (double sum, CardioExercise ex) {
        return sum + ex.totalDistance;
      },
    );
  }

  // Calculates total calories for all cardio exercises in this workout.
  int calculateTotalCardioCalories({
    required double userWeight,
    required int userAge,
    required int userSex,
  }) {
    return exercises.whereType<CardioExercise>().fold(0, (
      int sum,
      CardioExercise ex,
    ) {
      return sum +
          ex.calculateTotalCalories(
            userWeight: userWeight,
            userAge: userAge,
            userSex: userSex,
          );
    });
  }

  // Total calories burned across all cardio exercises (Legacy).
  int get totalCardioCalories {
    return exercises.whereType<CardioExercise>().fold(
      0,
      (int sum, CardioExercise ex) {
        return sum + ex.totalCalories;
      },
    );
  }

  // --- Time & Duration Summaries ---

  // Total time spent specifically on Cardio exercises.
  Duration get totalCardioTime {
    return exercises.whereType<CardioExercise>().fold(
      Duration.zero,
      (Duration sum, CardioExercise ex) {
        return sum + ex.totalDuration;
      },
    );
  }

  // Total time spent specifically on Stretching exercises.
  Duration get totalStretchTime {
    return exercises.whereType<StretchExercise>().fold(
      Duration.zero,
      (Duration sum, StretchExercise ex) {
        return sum + ex.totalDuration;
      },
    );
  }

  // Combined duration of all active exercises (Cardio + Stretch).
  // Note: This is different from Workout.totalDuration which tracks
  // wall-clock time.
  Duration get totalCardioDuration {
    return totalCardioTime + totalStretchTime;
  }
}

// Base class for all exercises in a workout.
abstract class WorkoutExercise {
  WorkoutExercise({
    required this.id,
    required this.exerciseName,
    required this.imagePath,
  });

  @HiveField(0, defaultValue: 0)
  final int id;
  @HiveField(1, defaultValue: '')
  final String exerciseName;
  @HiveField(2, defaultValue: '')
  final String imagePath;

  // Every exercise type must report its total number of sets.
  int get totalSets;

  WorkoutExercise copyWith();
}
