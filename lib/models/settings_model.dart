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
    this.useLbs = false,
  });

  @HiveField(0, defaultValue: true)
  final bool darkMode;

  @HiveField(1, defaultValue: 60)
  final int initialRestTime;

  @HiveField(2, defaultValue: <int>[])
  final List<int> favoriteExercises;

  @HiveField(3, defaultValue: true)
  final bool isWakelock;

  // Non-supporter FlexScheme value.
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

  // Non-supporter Google Fonts value.
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

  @HiveField(17, defaultValue: false)
  final bool useLbs;

  FlexScheme get flexScheme {
    // If supporter, use saved Strin or default.
    if (isSupporter && flexSchemeName != null) {
      return FlexScheme.values.firstWhere(
        (FlexScheme flexScheme) {
          return flexScheme.name == flexSchemeName;
        },
        orElse: () {
          return FlexScheme.shark;
        },
      );
    }

    // Non-supporter indexes.
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

  String get activeFontFamily {
    // If supporter, use saved String or default.
    if (isSupporter && googleFontFamily != null) {
      return googleFontFamily!;
    }

    // Non-supporter Strings.
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
    bool? useLbs,
  }) {
    // Map non-supporter FlexScheme enum choices to indexes.
    int updatedFlexSchemeIndex = flexSchemeIndex;
    if (flexScheme != null) {
      if (flexScheme == FlexScheme.shark) {
        updatedFlexSchemeIndex = 0;
      } else if (flexScheme == FlexScheme.greyLaw) {
        updatedFlexSchemeIndex = 1;
      } else if (flexScheme == FlexScheme.sanJuanBlue) {
        updatedFlexSchemeIndex = 2;
      }
    }

    // Map non-supporter font names to spaceless legacy identifiers.
    String updatedFontFamily = this.fontFamily;
    if (fontFamily != null) {
      if (fontFamily == 'League Gothic' || fontFamily == 'LeagueGothic') {
        updatedFontFamily = 'LeagueGothic';
      } else if (fontFamily == 'Lato') {
        updatedFontFamily = 'Lato';
      } else if (fontFamily == 'Fjalla One' || fontFamily == 'FjallaOne') {
        updatedFontFamily = 'FjallaOne';
      } else {
        updatedFontFamily = fontFamily;
      }
    }

    return Settings(
      darkMode: darkMode ?? this.darkMode,
      initialRestTime: initialRestTime ?? this.initialRestTime,
      favoriteExercises: favoriteExercises ?? this.favoriteExercises,
      isWakelock: isWakelock ?? this.isWakelock,
      flexSchemeIndex: updatedFlexSchemeIndex,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      sex: sex ?? this.sex,
      somatotypeIndex: somatotypeIndex ?? this.somatotypeIndex,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      fontFamily:
          updatedFontFamily, // Keep legacy untouched, mapping formatted input
      isExercisesGridMode: isExercisesGridMode ?? this.isExercisesGridMode,
      isSupporter: isSupporter ?? this.isSupporter,
      flexSchemeName: flexScheme?.name ?? flexSchemeName,
      googleFontFamily: googleFontFamily ?? this.googleFontFamily,
      useLbs: useLbs ?? this.useLbs,
    );
  }
}
