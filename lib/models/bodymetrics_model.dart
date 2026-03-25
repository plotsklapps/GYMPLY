import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'bodymetrics_model.g.dart';

@HiveType(typeId: 12)
class BodyMetric {
  BodyMetric({
    required this.date,
    required this.weight,
    required this.age,
    required this.height,
    required this.sex,
    required this.somatotype,
  });

  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final double height;

  @HiveField(4)
  final int sex; // 0 for Male, 1 for Female

  @HiveField(5, defaultValue: 1)
  final int somatotype; // 0: Ecto, 1: Meso, 2: Endo

  // Calculate BMI: weight (kg) / height (m)^2
  // Note: BMI is a fixed mathematical formula (kg/m^2) and is not
  // biologically altered by somatotype, though somatotype helps
  // interpret the result.
  double get bmi {
    if (height == 0) return 0;
    final double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Calculate Body Fat Percentage using the BMI method (Deurenberg et al.)
  // with a GYMPLY somatotype adjustment factor.
  double get bodyFat {
    final double bmiValue = bmi;
    if (bmiValue == 0) return 0;

    // Convert our sex (0=Male, 1=Female) to formula sex (1=Male, 0=Female)
    final int formulaSex = sex == 0 ? 1 : 0;

    // Base formula
    double bf = (1.20 * bmiValue) + (0.23 * age) - (10.8 * formulaSex) - 5.4;

    // GYMPLY Somatotype Adjustment:
    // Ecto (lower naturally), Meso (baseline), Endo (higher naturally)
    if (somatotype == 0) bf -= 1.5; // Ecto
    if (somatotype == 2) bf += 1.5; // Endo

    return bf;
  }
}
