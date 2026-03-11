import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 11)
class Settings {
  Settings({
    required this.darkMode,
    required this.initialRestTime,
    this.favoriteExercises = const <int>[],
    this.isWakelock = true,
    this.flexScheme = FlexScheme.shark,
  });

  @HiveField(0)
  final bool darkMode;

  @HiveField(1)
  final int initialRestTime;

  @HiveField(2)
  final List<int> favoriteExercises;

  @HiveField(3)
  final bool isWakelock;

  @HiveField(4)
  final FlexScheme flexScheme;

  Settings copyWith({
    bool? darkMode,
    int? initialRestTime,
    List<int>? favoriteExerciseIds,
    bool? isWakelock,
    FlexScheme? flexScheme,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
      favoriteExercises: favoriteExerciseIds ?? favoriteExercises,
      isWakelock: isWakelock ?? this.isWakelock,
      flexScheme: flexScheme ?? this.flexScheme,
    );
  }
}
