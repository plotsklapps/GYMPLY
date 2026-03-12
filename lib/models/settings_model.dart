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
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
      favoriteExercises: favoriteExerciseIds ?? favoriteExercises,
      isWakelock: isWakelock ?? this.isWakelock,
      flexSchemeIndex: flexScheme?.index ?? flexSchemeIndex,
    );
  }
}
