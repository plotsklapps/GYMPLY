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
      id: (fields[0] as num).toInt(),
      exerciseName: fields[1] as String,
      imagePath: fields[2] as String,
      sets: (fields[3] as List).cast<StretchSet>(),
      holdInput: (fields[4] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StretchExercise obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.holdInput);
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
    return StretchSet(duration: fields[0] as Duration);
  }

  @override
  void write(BinaryWriter writer, StretchSet obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.duration);
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
