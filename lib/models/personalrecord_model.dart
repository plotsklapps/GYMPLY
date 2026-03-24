class PersonalRecord {
  PersonalRecord({
    this.maxWeight = 0,
    this.maxSetVolume = 0,
    this.maxExerciseVolume = 0,
    this.oneRepMaxLombardi = 0,
    this.oneRepMaxBrzycki = 0,
    this.oneRepMaxEpley = 0,
    this.maxSetDuration = Duration.zero,
    this.maxDistance = 0,
    this.maxTotalDuration = Duration.zero,
    this.maxExerciseStretches = 0,
  });

  factory PersonalRecord.empty() {
    return PersonalRecord();
  }

  // Strength PRs.
  final double maxWeight;
  final double maxSetVolume;
  final double maxExerciseVolume;
  final double oneRepMaxLombardi;
  final double oneRepMaxBrzycki;
  final double oneRepMaxEpley;

  // Cardio PRs.
  final Duration maxSetDuration;
  final double maxDistance;
  final Duration maxTotalDuration;

  // Stretch PRs.
  final int maxExerciseStretches;
}
