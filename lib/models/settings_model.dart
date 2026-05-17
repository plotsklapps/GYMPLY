import 'package:flex_color_scheme/flex_color_scheme.dart';
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
    this.fontFamily = 'LeagueGothic',
    this.isExercisesGridMode = true,
    this.isSupporter = false,
    this.flexSchemeName,
    this.googleFontFamily,
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

  @HiveField(9, defaultValue: false)
  final bool onboardingCompleted;

  @HiveField(10, defaultValue: 1)
  final int somatotypeIndex;

  @HiveField(11, defaultValue: 'LeagueGothic')
  final String fontFamily;

  @HiveField(12, defaultValue: true)
  final bool isExercisesGridMode;

  // 13 was for appIcon, type String.

  @HiveField(14, defaultValue: false)
  final bool isSupporter;

  // Supporter FlexScheme value.
  @HiveField(15)
  final String? flexSchemeName;

  // Supporter Google Fonts value.
  @HiveField(16)
  final String? googleFontFamily;

  // Custom enum mapping.
  FlexScheme get flexScheme {
    if (flexSchemeName != null) {
      return FlexScheme.values.firstWhere(
        (e) => e.name == flexSchemeName,
        orElse: () => FlexScheme.shark,
      );
    }
    // Migration logic for old index.
    switch (flexSchemeIndex) {
      case 0:
        return FlexScheme.shark;
      case 1:
        return FlexScheme.greyLaw;
      case 2:
        return FlexScheme.sanJuanBlue;
      default:
        return FlexScheme.shark;
    }
  }

  // Google Fonts string mapping
  String get activeFontFamily {
    if (googleFontFamily != null) {
      return googleFontFamily!;
    }
    // Migration logic for old hardcoded names
    switch (fontFamily) {
      case 'LeagueGothic':
        return 'League Gothic';
      case 'Lato':
        return 'Lato';
      case 'FjallaOne':
        return 'Fjalla One';
      default:
        return 'League Gothic';
    }
  }

  Settings copyWith({
    bool? darkMode,
    int? initialRestTime,
    List<int>? favoriteExercises,
    bool? isWakelock,
    FlexScheme? flexScheme,
    int? age,
    double? height,
    double? weight,
    int? sex,
    int? somatotypeIndex,
    bool? onboardingCompleted,
    String? fontFamily,
    bool? isExercisesGridMode,
    bool? isSupporter,
    String? googleFontFamily,
  }) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
      favoriteExercises: favoriteExercises ?? this.favoriteExercises,
      isWakelock: isWakelock ?? this.isWakelock,
      flexSchemeIndex:
          this.flexSchemeIndex, // Keep legacy untouched unless needed
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sex: sex ?? this.sex,
      somatotypeIndex: somatotypeIndex ?? this.somatotypeIndex,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      fontFamily: this.fontFamily, // Keep legacy untouched
      isExercisesGridMode: isExercisesGridMode ?? this.isExercisesGridMode,
      isSupporter: isSupporter ?? this.isSupporter,
      flexSchemeName: flexScheme?.name ?? flexSchemeName,
      googleFontFamily: googleFontFamily ?? this.googleFontFamily,
    );
  }
}
