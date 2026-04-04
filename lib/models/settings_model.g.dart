// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final typeId = 11;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      darkMode: fields[0] == null ? true : fields[0] as bool,
      initialRestTime: fields[1] == null ? 60 : (fields[1] as num).toInt(),
      flexSchemeIndex: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      favoriteExercises: fields[2] == null
          ? []
          : (fields[2] as List).cast<int>(),
      isWakelock: fields[3] == null ? true : fields[3] as bool,
      age: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      height: fields[6] == null ? 0 : (fields[6] as num).toDouble(),
      weight: fields[7] == null ? 0 : (fields[7] as num).toDouble(),
      sex: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      somatotypeIndex: fields[10] == null ? 1 : (fields[10] as num).toInt(),
      onboardingCompleted: fields[9] == null ? false : fields[9] as bool,
      fontFamily: fields[11] == null ? 'LeagueGothic' : fields[11] as String,
      isExercisesGridMode: fields[12] == null ? true : fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.darkMode)
      ..writeByte(1)
      ..write(obj.initialRestTime)
      ..writeByte(2)
      ..write(obj.favoriteExercises)
      ..writeByte(3)
      ..write(obj.isWakelock)
      ..writeByte(4)
      ..write(obj.flexSchemeIndex)
      ..writeByte(5)
      ..write(obj.age)
      ..writeByte(6)
      ..write(obj.height)
      ..writeByte(7)
      ..write(obj.weight)
      ..writeByte(8)
      ..write(obj.sex)
      ..writeByte(9)
      ..write(obj.onboardingCompleted)
      ..writeByte(10)
      ..write(obj.somatotypeIndex)
      ..writeByte(11)
      ..write(obj.fontFamily)
      ..writeByte(12)
      ..write(obj.isExercisesGridMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
