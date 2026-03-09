// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cardio_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardioExerciseAdapter extends TypeAdapter<CardioExercise> {
  @override
  final typeId = 2;

  @override
  CardioExercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardioExercise(
      id: (fields[0] as num).toInt(),
      exerciseName: fields[1] as String,
      imagePath: fields[2] as String,
      equipment: fields[3] as Equipment,
      sets: (fields[4] as List).cast<CardioSet>(),
      cardioDurationInput: fields[5] as Duration?,
      restDurationInput: fields[6] as Duration?,
      distanceInput: (fields[7] as num?)?.toDouble(),
      caloriesInput: (fields[8] as num?)?.toInt(),
      intensityInput: (fields[9] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CardioExercise obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseName)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.equipment)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.cardioDurationInput)
      ..writeByte(6)
      ..write(obj.restDurationInput)
      ..writeByte(7)
      ..write(obj.distanceInput)
      ..writeByte(8)
      ..write(obj.caloriesInput)
      ..writeByte(9)
      ..write(obj.intensityInput);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CardioSetAdapter extends TypeAdapter<CardioSet> {
  @override
  final typeId = 5;

  @override
  CardioSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardioSet(
      cardioDuration: fields[0] as Duration,
      restDuration: fields[1] as Duration,
      totalDuration: fields[2] as Duration,
      distance: (fields[3] as num?)?.toDouble(),
      calories: (fields[4] as num?)?.toInt(),
      intensity: (fields[5] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, CardioSet obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.cardioDuration)
      ..writeByte(1)
      ..write(obj.restDuration)
      ..writeByte(2)
      ..write(obj.totalDuration)
      ..writeByte(3)
      ..write(obj.distance)
      ..writeByte(4)
      ..write(obj.calories)
      ..writeByte(5)
      ..write(obj.intensity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardioSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
