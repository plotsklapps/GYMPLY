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
  });

  @HiveField(0, defaultValue: '')
  final String id;

  @HiveField(1, defaultValue: '')
  final String title;

  @HiveField(2, defaultValue: <WorkoutExercise>[])
  final List<WorkoutExercise> exercises;

  @HiveField(3, defaultValue: '')
  final String notes;

  Routine copyWith({
    String? title,
    List<WorkoutExercise>? exercises,
    String? notes,
  }) {
    return Routine(
      id: id,
      title: title ?? this.title,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}
