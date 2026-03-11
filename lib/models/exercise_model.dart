import 'package:hive_ce/hive.dart';

part 'exercise_model.g.dart';

@HiveType(typeId: 9)
enum WorkoutType {
  @HiveField(0)
  strength,
  @HiveField(1)
  cardio,
  @HiveField(2)
  stretch,
}

@HiveType(typeId: 7)
enum MuscleGroup {
  @HiveField(0)
  fullbody,
  @HiveField(1)
  chest,
  @HiveField(2)
  back,
  @HiveField(3)
  legs,
  @HiveField(4)
  shoulders,
  @HiveField(5)
  biceps,
  @HiveField(6)
  triceps,
  @HiveField(7)
  abs,
  @HiveField(8)
  forearms,
  @HiveField(9)
  neck,
}

@HiveType(typeId: 8)
enum Equipment {
  @HiveField(0)
  bodyweight,
  @HiveField(1)
  barbell,
  @HiveField(2)
  dumbbell,
  @HiveField(3)
  machine,
  @HiveField(4)
  cable,
  @HiveField(5)
  ezbar,
  @HiveField(6)
  smith,
  @HiveField(7)
  kettlebell,
  @HiveField(8)
  band,
  @HiveField(9)
  plate,
  @HiveField(10)
  medicineball,
  @HiveField(11)
  landmine,
  @HiveField(12)
  powersled,
  @HiveField(13)
  safetybar,
  @HiveField(14)
  trapbar,
  @HiveField(15)
  stretch,
  @HiveField(16)
  heavybag,
}

// Helper enums for UI filtering (Non-Hive).
enum StrengthEquipment {
  bodyweight,
  barbell,
  dumbbell,
  machine,
  cable,
  ezbar,
  smith,
  kettlebell,
  band,
  plate,
  medicineball,
  landmine,
  powersled,
  safetybar,
  trapbar,
}

enum CardioEquipment {
  bodyweight,
  machine,
  kettlebell,
  medicineball,
  heavybag,
}

// Metadata for an exercise parsed from its asset path.
// (assets/images/exercises/00011101-Abs-Bodyweight-3-Quarter-Sit-Up.png)
class ExercisePath {
  ExercisePath({
    required this.fullPath,
    required this.id,
    required this.muscleSegment,
    required this.equipmentSegment,
    required this.exerciseName,
  });
  // Actual asset path.
  final String fullPath;
  // Numeric ID (00011101).
  final String id;
  // Parsed muscle group segment (Chest).
  final String muscleSegment;
  // Parsed equipment segment (Barbell).
  final String equipmentSegment;
  // Formatted exercisename (3 Quarter Sit Up).
  final String exerciseName;
}
