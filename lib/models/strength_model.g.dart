// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strength_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StrengthExerciseAdapter extends TypeAdapter<StrengthExercise> {
  @override
  final typeId = 1;

  @override
  StrengthExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrengthExercise(
      id: fields[0] == null ? 0 : (fields[0] as num).toInt(),
      exerciseName: fields[1] == null ? '' : fields[1] as String,
      imagePath: fields[2] == null ? '' : fields[2] as String,
      muscleGroup: fields[3] as MuscleGroup,
      equipment: fields[4] as Equipment,
      sets: (fields[5] as List).cast<StrengthSet>(),
      weightInput: (fields[6] as num?)?.toDouble(),
      repsInput: (fields[7] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StrengthExercise obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.muscleGroup)
      ..writeByte(4)
      ..write(obj.equipment)
      ..writeByte(5)
      ..write(obj.sets)
      ..writeByte(6)
      ..write(obj.weightInput)
      ..writeByte(7)
      ..write(obj.repsInput);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrengthExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrengthSetAdapter extends TypeAdapter<StrengthSet> {
  @override
  final typeId = 4;

  @override
  StrengthSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrengthSet(
      weight: (fields[0] as num).toDouble(),
      reps: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StrengthSet obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.weight)
      ..writeByte(1)
      ..write(obj.reps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrengthSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
