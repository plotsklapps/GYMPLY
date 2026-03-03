// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutTypeAdapter extends TypeAdapter<WorkoutType> {
  @override
  final typeId = 9;

  @override
  WorkoutType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutType.strength;
      case 1:
        return WorkoutType.cardio;
      case 2:
        return WorkoutType.stretch;
      default:
        return WorkoutType.strength;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutType obj) {
    switch (obj) {
      case WorkoutType.strength:
        writer.writeByte(0);
      case WorkoutType.cardio:
        writer.writeByte(1);
      case WorkoutType.stretch:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MuscleGroupAdapter extends TypeAdapter<MuscleGroup> {
  @override
  final typeId = 7;

  @override
  MuscleGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MuscleGroup.fullbody;
      case 1:
        return MuscleGroup.chest;
      case 2:
        return MuscleGroup.back;
      case 3:
        return MuscleGroup.legs;
      case 4:
        return MuscleGroup.shoulders;
      case 5:
        return MuscleGroup.biceps;
      case 6:
        return MuscleGroup.triceps;
      case 7:
        return MuscleGroup.abs;
      case 8:
        return MuscleGroup.forearms;
      case 9:
        return MuscleGroup.neck;
      default:
        return MuscleGroup.fullbody;
    }
  }

  @override
  void write(BinaryWriter writer, MuscleGroup obj) {
    switch (obj) {
      case MuscleGroup.fullbody:
        writer.writeByte(0);
      case MuscleGroup.chest:
        writer.writeByte(1);
      case MuscleGroup.back:
        writer.writeByte(2);
      case MuscleGroup.legs:
        writer.writeByte(3);
      case MuscleGroup.shoulders:
        writer.writeByte(4);
      case MuscleGroup.biceps:
        writer.writeByte(5);
      case MuscleGroup.triceps:
        writer.writeByte(6);
      case MuscleGroup.abs:
        writer.writeByte(7);
      case MuscleGroup.forearms:
        writer.writeByte(8);
      case MuscleGroup.neck:
        writer.writeByte(9);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EquipmentAdapter extends TypeAdapter<Equipment> {
  @override
  final typeId = 8;

  @override
  Equipment read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Equipment.bodyweight;
      case 1:
        return Equipment.barbell;
      case 2:
        return Equipment.dumbbell;
      case 3:
        return Equipment.machine;
      case 4:
        return Equipment.cable;
      case 5:
        return Equipment.ezbar;
      case 6:
        return Equipment.smith;
      case 7:
        return Equipment.kettlebell;
      case 8:
        return Equipment.band;
      case 9:
        return Equipment.plate;
      case 10:
        return Equipment.medicineball;
      case 11:
        return Equipment.landmine;
      case 12:
        return Equipment.powersled;
      case 13:
        return Equipment.safetybar;
      case 14:
        return Equipment.trapbar;
      case 15:
        return Equipment.stretch;
      default:
        return Equipment.bodyweight;
    }
  }

  @override
  void write(BinaryWriter writer, Equipment obj) {
    switch (obj) {
      case Equipment.bodyweight:
        writer.writeByte(0);
      case Equipment.barbell:
        writer.writeByte(1);
      case Equipment.dumbbell:
        writer.writeByte(2);
      case Equipment.machine:
        writer.writeByte(3);
      case Equipment.cable:
        writer.writeByte(4);
      case Equipment.ezbar:
        writer.writeByte(5);
      case Equipment.smith:
        writer.writeByte(6);
      case Equipment.kettlebell:
        writer.writeByte(7);
      case Equipment.band:
        writer.writeByte(8);
      case Equipment.plate:
        writer.writeByte(9);
      case Equipment.medicineball:
        writer.writeByte(10);
      case Equipment.landmine:
        writer.writeByte(11);
      case Equipment.powersled:
        writer.writeByte(12);
      case Equipment.safetybar:
        writer.writeByte(13);
      case Equipment.trapbar:
        writer.writeByte(14);
      case Equipment.stretch:
        writer.writeByte(15);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
