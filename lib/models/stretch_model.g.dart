// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stretch_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StretchExerciseAdapter extends TypeAdapter<StretchExercise> {
  @override
  final typeId = 3;

  @override
  StretchExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StretchExercise(
      id: fields[0] == null ? 0 : (fields[0] as num).toInt(),
      exerciseName: fields[1] == null ? '' : fields[1] as String,
      imagePath: fields[2] == null ? '' : fields[2] as String,
      sets: (fields[3] as List).cast<StretchSet>(),
      stretchDurationInput: fields[4] as Duration?,
      restDurationInput: fields[5] as Duration?,
      caloriesInput: (fields[6] as num?)?.toInt(),
      intensityInput: (fields[7] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StretchExercise obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.stretchDurationInput)
      ..writeByte(5)
      ..write(obj.restDurationInput)
      ..writeByte(6)
      ..write(obj.caloriesInput)
      ..writeByte(7)
      ..write(obj.intensityInput);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StretchExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StretchSetAdapter extends TypeAdapter<StretchSet> {
  @override
  final typeId = 6;

  @override
  StretchSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StretchSet(
      stretchDuration: fields[0] as Duration,
      restDuration: fields[1] as Duration,
      totalDuration: fields[2] as Duration,
      calories: (fields[3] as num?)?.toInt(),
      intensity: (fields[4] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StretchSet obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.stretchDuration)
      ..writeByte(1)
      ..write(obj.restDuration)
      ..writeByte(2)
      ..write(obj.totalDuration)
      ..writeByte(3)
      ..write(obj.calories)
      ..writeByte(4)
      ..write(obj.intensity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StretchSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
