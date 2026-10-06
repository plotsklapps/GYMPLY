// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final typeId = 13;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine(
      id: fields[0] == null ? '' : fields[0] as String,
      title: fields[1] == null ? '' : fields[1] as String,
      exercises: fields[2] == null
          ? []
          : (fields[2] as List).cast<WorkoutExercise>(),
      notes: fields[3] == null ? '' : fields[3] as String,
      muscleGroup: fields[4] as MuscleGroup?,
      muscleGroups: fields[5] == null
          ? []
          : (fields[5] as List).cast<MuscleGroup>(),
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.exercises)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.muscleGroup)
      ..writeByte(5)
      ..write(obj.muscleGroups);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
