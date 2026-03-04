import 'package:hive_ce/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 11)
class Settings {
  Settings({
    required this.darkMode,
    required this.initialRestTime,
  });

  @HiveField(0)
  final bool darkMode;

  @HiveField(1)
  final int initialRestTime;

  Settings copyWith({
    bool? darkMode,
    int? initialRestTime,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
    );
  }
}
