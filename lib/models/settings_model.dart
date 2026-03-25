import 'package:gymply/theme/flexscheme.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 11)
class Settings {
  Settings({
    this.darkMode = true,
    this.initialRestTime = 60,
    this.flexSchemeIndex = 0,
    this.favoriteExercises = const <int>[],
    this.isWakelock = true,
    this.age = 0,
    this.height = 0,
    this.weight = 0,
    this.sex = 0,
    this.somatotypeIndex = 1,
    this.onboardingCompleted = false,
  });

  @HiveField(0, defaultValue: true)
  final bool darkMode;

  @HiveField(1, defaultValue: 60)
  final int initialRestTime;

  @HiveField(2, defaultValue: <int>[])
  final List<int> favoriteExercises;

  @HiveField(3, defaultValue: true)
  final bool isWakelock;

  @HiveField(4, defaultValue: 0)
  final int flexSchemeIndex;

  @HiveField(5, defaultValue: 0)
  final int age;

  @HiveField(6, defaultValue: 0)
  final double height;

  @HiveField(7, defaultValue: 0)
  final double weight;

  @HiveField(8, defaultValue: 0)
  final int sex;

  @HiveField(10, defaultValue: 1)
  final int somatotypeIndex;

  @HiveField(9, defaultValue: false)
  final bool onboardingCompleted;

  // Custom enum mapping.
  FlexSchemes get flexScheme {
    return FlexSchemes.values[flexSchemeIndex];
  }

  Settings copyWith({
    bool? darkMode,
    int? initialRestTime,
    List<int>? favoriteExerciseIds,
    bool? isWakelock,
    FlexSchemes? flexScheme,
    int? age,
    double? height,
    double? weight,
    int? sex,
    int? somatotypeIndex,
    bool? onboardingCompleted,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
      favoriteExercises: favoriteExerciseIds ?? favoriteExercises,
      isWakelock: isWakelock ?? this.isWakelock,
      flexSchemeIndex: flexScheme?.index ?? flexSchemeIndex,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sex: sex ?? this.sex,
      somatotypeIndex: somatotypeIndex ?? this.somatotypeIndex,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
