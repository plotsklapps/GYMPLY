import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:hive_ce/hive.dart';

part 'routine_model.g.dart';

// Represents a reusable Workout Routine template.
@HiveType(typeId: 13)
class Routine {
  Routine({
    required this.id,
    required this.title,
    this.exercises = const <WorkoutExercise>[],
    this.notes = '',
    this.muscleGroup,
    this.muscleGroups = const <MuscleGroup>[],
  });

  @HiveField(0, defaultValue: '')
  final String id;

  @HiveField(1, defaultValue: '')
  final String title;

  @HiveField(2, defaultValue: <WorkoutExercise>[])
  final List<WorkoutExercise> exercises;

  @HiveField(3, defaultValue: '')
  final String notes;

  @HiveField(4)
  final MuscleGroup? muscleGroup;

  @HiveField(5, defaultValue: <MuscleGroup>[])
  final List<MuscleGroup> muscleGroups;

  // Helper getter returning up to 3 selected active muscle groups.
  List<MuscleGroup> get activeMuscleGroups {
    if (muscleGroups.isNotEmpty) {
      return muscleGroups.take(3).toList();
    }
    if (muscleGroup != null) {
      return <MuscleGroup>[muscleGroup!];
    }
    return <MuscleGroup>[];
  }

  Routine copyWith({
    String? title,
    List<WorkoutExercise>? exercises,
    String? notes,
    MuscleGroup? muscleGroup,
    List<MuscleGroup>? muscleGroups,
  }) {
    return Routine(
      id: id,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      muscleGroups: muscleGroups ?? this.muscleGroups,
    );
  }
}
