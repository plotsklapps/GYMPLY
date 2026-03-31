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
    this.manualBmi,
    this.manualBodyFat,
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
  final int sex;

  @HiveField(5, defaultValue: 1)
  // Ecto, Meso, Endo.
  final int somatotype;

  @HiveField(6)
  final double? manualBmi;

  @HiveField(7)
  final double? manualBodyFat;

  // Calculate BMI: weight (kg) / height (m)^2.
  double get bmi {
    if (manualBmi != null && manualBmi! > 0) return manualBmi!;
    if (height == 0) return 0;
    final double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // Calculate BF% using BMI method with somatotype adjustment.
  double get bodyFat {
    if (manualBodyFat != null && manualBodyFat! > 0) return manualBodyFat!;
    final double bmiValue = bmi;
    if (bmiValue == 0) return 0;

    // Convert our sex (0=Male, 1=Female) to formula sex (1=Male, 0=Female)
    final int formulaSex = sex == 0 ? 1 : 0;

    // Gallagher formula.
    double bf = (1.46 * bmiValue) + (0.14 * age) - (11.6 * formulaSex) - 10.0;

    // GYMPLY Somatotype Adjustment for Active Individuals.
    if (somatotype == 0) bf -= 2.0;
    if (somatotype == 1) bf -= 5.0;
    if (somatotype == 2) bf += 1.0;

    return bf;
  }
}
