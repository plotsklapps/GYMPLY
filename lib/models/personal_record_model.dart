class PersonalRecord {
  PersonalRecord({
    required this.maxWeight,
    required this.maxSetVolume,
    required this.maxExerciseVolume,
  });

  factory PersonalRecord.empty() {
    return PersonalRecord(
      maxWeight: 0,
      maxSetVolume: 0,
      maxExerciseVolume: 0,
    );
  }
  final double maxWeight;
  final double maxSetVolume;
  final double maxExerciseVolume;
}
