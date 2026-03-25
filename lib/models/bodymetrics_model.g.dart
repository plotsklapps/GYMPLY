// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bodymetrics_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMetricAdapter extends TypeAdapter<BodyMetric> {
  @override
  final typeId = 12;

  @override
  BodyMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMetric(
      date: fields[0] as DateTime,
      weight: (fields[1] as num).toDouble(),
      age: (fields[2] as num).toInt(),
      height: (fields[3] as num).toDouble(),
      sex: (fields[4] as num).toInt(),
      somatotype: fields[5] == null ? 1 : (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, BodyMetric obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.sex)
      ..writeByte(5)
      ..write(obj.somatotype);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMetricAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
