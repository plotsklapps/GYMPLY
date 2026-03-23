class PersonalRecord {
  PersonalRecord({
    required this.maxWeight,
    required this.maxSetVolume,
    required this.maxExerciseVolume,
    required this.oneRepMaxLombardi,
    required this.oneRepMaxBrzycki,
    required this.oneRepMaxEpley,
  });

  factory PersonalRecord.empty() {
    return PersonalRecord(
      maxWeight: 0,
      maxSetVolume: 0,
      maxExerciseVolume: 0,
      oneRepMaxLombardi: 0,
      oneRepMaxBrzycki: 0,
      oneRepMaxEpley: 0,
    );
  }
  final double maxWeight;
  final double maxSetVolume;
  final double maxExerciseVolume;
  final double oneRepMaxLombardi;
  final double oneRepMaxBrzycki;
  final double oneRepMaxEpley;
}
