import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 11)
class Settings {
  Settings({
    required this.darkMode,
    required this.initialRestTime,
    this.favoriteExercises = const <int>[],
    this.isWakelock = true,
  });

  @HiveField(0)
  final bool darkMode;

  @HiveField(1)
  final int initialRestTime;

  @HiveField(2)
  final List<int> favoriteExercises;

  @HiveField(3)
  final bool isWakelock;

  Settings copyWith({
    bool? darkMode,
    int? initialRestTime,
    List<int>? favoriteExerciseIds,
    bool? isWakelock,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
      favoriteExercises: favoriteExerciseIds ?? favoriteExercises,
      isWakelock: isWakelock ?? this.isWakelock,
    );
  }
}
