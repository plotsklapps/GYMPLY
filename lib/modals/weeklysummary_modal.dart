import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart' as atlas;
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/atlas_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:gymply/theme/icons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

class WeeklySummaryModal extends SignalStatefulWidget {
  const WeeklySummaryModal({
    required this.startDate,
    required this.endDate,
    required this.workouts,
    super.key,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<Workout> workouts;

  @override
  State<WeeklySummaryModal> createState() {
    return _WeeklySummaryModalState();
  }
}

class _WeeklySummaryModalState extends State<WeeklySummaryModal> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String weightUnit = sUseLbs.value ? 'lbs' : 'kg';

    final String startStr = DateFormat(
      'MMM d',
    ).format(widget.startDate).toUpperCase();
    final String endStr = DateFormat(
      'MMM d, yyyy',
    ).format(widget.endDate).toUpperCase();
    final String rangeTitle = '$startStr - $endStr';

    final int totalWorkouts = widget.workouts.length;
    final int totalDurationSecs = widget.workouts.fold(0, (int sum, Workout w) {
      return sum + w.totalDuration;
    });
    final int totalSets = widget.workouts.fold(0, (int sum, Workout w) {
      return sum + w.totalSets;
    });
    final double totalVolume = widget.workouts.fold(0, (double sum, Workout w) {
      return sum + w.totalStrengthVolume;
    });
    final int totalReps = widget.workouts.fold(0, (int sum, Workout w) {
      return sum + w.totalReps;
    });

    // Muscle Group Analysis
    final Map<MuscleGroup, int> muscleSetCounts = <MuscleGroup, int>{};
    final List<MuscleGroup> allWorkedMuscles = <MuscleGroup>[];

    // Top Exercises & Equipment
    final Map<String, int> exerciseSetCounts = <String, int>{};
    final Map<Equipment, int> equipmentCounts = <Equipment, int>{};

    // PRs in this week
    final List<Map<String, dynamic>> weekPRs = <Map<String, dynamic>>[];

    for (final Workout w in widget.workouts) {
      final List<Map<String, dynamic>> prs = workoutService.getWorkoutPRs(w);
      weekPRs.addAll(prs);

      for (final WorkoutExercise ex in w.exercises) {
        // Exercise Frequency
        exerciseSetCounts[ex.exerciseName] =
            (exerciseSetCounts[ex.exerciseName] ?? 0) + ex.totalSets;

        if (ex is StrengthExercise) {
          muscleSetCounts[ex.muscleGroup] =
              (muscleSetCounts[ex.muscleGroup] ?? 0) + ex.totalSets;
          allWorkedMuscles.add(ex.muscleGroup);

          equipmentCounts[ex.equipment] =
              (equipmentCounts[ex.equipment] ?? 0) + ex.totalSets;
        } else if (ex is CardioExercise) {
          equipmentCounts[ex.equipment] =
              (equipmentCounts[ex.equipment] ?? 0) + ex.totalSets;
        }
      }
    }

    // Sort Muscle Groups
    MuscleGroup? mostTrainedMuscle;
    MuscleGroup? leastTrainedMuscle;
    if (muscleSetCounts.isNotEmpty) {
      final List<MapEntry<MuscleGroup, int>> sortedMuscles =
          muscleSetCounts.entries.toList()..sort(
            (MapEntry<MuscleGroup, int> a, MapEntry<MuscleGroup, int> b) =>
                b.value.compareTo(a.value),
          );
      mostTrainedMuscle = sortedMuscles.first.key;

      for (final MuscleGroup mg in MuscleGroup.values) {
        if (mg != MuscleGroup.fullbody) {
          if (!muscleSetCounts.containsKey(mg)) {
            leastTrainedMuscle = mg;
            break;
          }
        }
      }
      leastTrainedMuscle ??= sortedMuscles.last.key;
    }

    // Top 3 Exercises
    final List<MapEntry<String, int>> topExercises =
        exerciseSetCounts.entries.toList()..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value),
        );
    final List<MapEntry<String, int>> top3Exercises = topExercises
        .take(3)
        .toList();

    // Top 3 Equipment
    final List<MapEntry<Equipment, int>> topEquipment =
        equipmentCounts.entries.toList()..sort(
          (MapEntry<Equipment, int> a, MapEntry<Equipment, int> b) =>
              b.value.compareTo(a.value),
        );
    final List<MapEntry<Equipment, int>> top3Equipment = topEquipment
        .take(3)
        .toList();

    // Peak Days
    Workout? peakVolumeWorkout;
    Workout? peakSetsWorkout;
    Workout? peakRepsWorkout;

    for (final Workout w in widget.workouts) {
      if (peakVolumeWorkout == null ||
          w.totalStrengthVolume > peakVolumeWorkout.totalStrengthVolume) {
        peakVolumeWorkout = w;
      }
      if (peakSetsWorkout == null || w.totalSets > peakSetsWorkout.totalSets) {
        peakSetsWorkout = w;
      }
      if (peakRepsWorkout == null || w.totalReps > peakRepsWorkout.totalReps) {
        peakRepsWorkout = w;
      }
    }

    // Body Atlas Colors
    final Map<atlas.MuscleInfo, Color> atlasColors = atlasService
        .getAtlasColors(allWorkedMuscles, theme.colorScheme);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Header
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    rangeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'WEEKLY WRAPPED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(IconUtils.close),
            ),
          ],
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),

                // 1. OVERVIEW HERO BANNER
                Card(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        Text(
                          '$totalWorkouts WORKOUTS',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalDurationSecs.formatHHMM()} TOTAL TIME',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            _buildMiniStat(
                              theme,
                              'TOTAL VOLUME',
                              '${totalVolume.toStringAsFixed(0)} $weightUnit',
                            ),
                            _buildMiniStat(theme, 'TOTAL SETS', '$totalSets'),
                            _buildMiniStat(theme, 'TOTAL REPS', '$totalReps'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // 2. MUSCLE FOCUS & BODY ATLAS
                if (allWorkedMuscles.isNotEmpty) ...<Widget>[
                  Text(
                    'WEEKLY MUSCLE ACTIVATION',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: SizedBox(
                                  height: 200,
                                  child: atlas.BodyAtlasView<atlas.MuscleInfo>(
                                    view: atlas.AtlasAsset.musclesFront,
                                    resolver: const atlas.MuscleResolver(),
                                    colorMapping: atlasColors,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 200,
                                  child: atlas.BodyAtlasView<atlas.MuscleInfo>(
                                    view: atlas.AtlasAsset.musclesBack,
                                    resolver: const atlas.MuscleResolver(),
                                    colorMapping: atlasColors,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: <Widget>[
                              if (mostTrainedMuscle != null)
                                Expanded(
                                  child: _buildFocusBadge(
                                    theme,
                                    label: 'MOST FOCUS',
                                    muscleName: mostTrainedMuscle.name
                                        .capitalizeFirst(),
                                    sets:
                                        muscleSetCounts[mostTrainedMuscle] ?? 0,
                                    isHighlight: true,
                                  ),
                                ),
                              if (mostTrainedMuscle != null &&
                                  leastTrainedMuscle != null)
                                const SizedBox(width: 8),
                              if (leastTrainedMuscle != null)
                                Expanded(
                                  child: _buildFocusBadge(
                                    theme,
                                    label: 'LEAST ATTENTION',
                                    muscleName: leastTrainedMuscle.name
                                        .capitalizeFirst(),
                                    sets:
                                        muscleSetCounts[leastTrainedMuscle] ??
                                        0,
                                    isHighlight: false,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 3. PEAK PERFORMANCE DAYS OF THE WEEK
                Text(
                  'PEAK DAYS OF THE WEEK',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                Column(
                  children: <Widget>[
                    if (peakVolumeWorkout != null &&
                        peakVolumeWorkout.totalStrengthVolume > 0)
                      _buildPeakCard(
                        theme,
                        title: 'HIGHEST VOLUME DAY',
                        subtitle: DateFormat(
                          'EEEE, MMM d',
                        ).format(peakVolumeWorkout.dateTime),
                        value:
                            '${peakVolumeWorkout.totalStrengthVolume.toStringAsFixed(0)} $weightUnit',
                        icon: IconUtils.weight,
                      ),
                    if (peakSetsWorkout != null &&
                        peakSetsWorkout.totalSets > 0)
                      _buildPeakCard(
                        theme,
                        title: 'MOST SETS DAY',
                        subtitle: DateFormat(
                          'EEEE, MMM d',
                        ).format(peakSetsWorkout.dateTime),
                        value: '${peakSetsWorkout.totalSets} SETS',
                        icon: IconUtils.numbers,
                      ),
                    if (peakRepsWorkout != null &&
                        peakRepsWorkout.totalReps > 0)
                      _buildPeakCard(
                        theme,
                        title: 'MOST REPS DAY',
                        subtitle: DateFormat(
                          'EEEE, MMM d',
                        ).format(peakRepsWorkout.dateTime),
                        value: '${peakRepsWorkout.totalReps} REPS',
                        icon: IconUtils.speed,
                      ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // 4. TOP 3 EXERCISES OF THE WEEK
                if (top3Exercises.isNotEmpty) ...<Widget>[
                  Text(
                    'TOP 3 EXERCISES THIS WEEK',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: List<Widget>.generate(top3Exercises.length, (
                          int i,
                        ) {
                          final MapEntry<String, int> entry = top3Exercises[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: i == 0
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.surfaceContainerHigh,
                              child: Text(
                                '#${i + 1}',
                                style: TextStyle(
                                  color: i == 0
                                      ? theme.colorScheme.onSecondary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              entry.key,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              '${entry.value} SETS',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 5. TOP 3 EQUIPMENT OF THE WEEK
                if (top3Equipment.isNotEmpty) ...<Widget>[
                  Text(
                    'TOP 3 EQUIPMENT THIS WEEK',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: List<Widget>.generate(top3Equipment.length, (
                          int i,
                        ) {
                          final MapEntry<Equipment, int> entry =
                              top3Equipment[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: i == 0
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.surfaceContainerHigh,
                              child: Text(
                                '#${i + 1}',
                                style: TextStyle(
                                  color: i == 0
                                      ? theme.colorScheme.onSecondary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              entry.key.name.capitalizeFirst(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              '${entry.value} SETS',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 6. WEEK PERSONAL RECORDS
                if (weekPRs.isNotEmpty) ...<Widget>[
                  Text(
                    'PERSONAL RECORDS ACHIEVED (${weekPRs.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: weekPRs.map((Map<String, dynamic> pr) {
                          final String exerciseName =
                              (pr['exerciseName'] as String? ?? 'PR')
                                  .toUpperCase();
                          final String prType = (pr['type'] as String? ?? 'PR')
                              .toUpperCase();
                          final String detail = _formatPRDetail(pr, weightUnit);

                          return ListTile(
                            leading: const Icon(
                              IconUtils.medal,
                              color: Colors.amber,
                            ),
                            title: Text(
                              '$exerciseName $prType PR',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              detail,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(ThemeData theme, String label, String value) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildFocusBadge(
    ThemeData theme, {
    required String label,
    required String muscleName,
    required int sets,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight
            ? theme.colorScheme.secondary
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? theme.colorScheme.onSecondary
                  : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            muscleName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? theme.colorScheme.onSecondary
                  : theme.colorScheme.onSurface,
            ),
          ),
          Text(
            '$sets Sets',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isHighlight
                  ? theme.colorScheme.onSecondary
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.secondary),
        title: Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  String _formatPRDetail(Map<String, dynamic> pr, String weightUnit) {
    final String type = (pr['type'] as String?) ?? '';
    final dynamic val = pr['value'];

    if (type == 'REP') {
      if (val is num) {
        return '${val.toStringAsFixed(1)} $weightUnit';
      }
    } else if (type == 'SET') {
      final double weight = (pr['weight'] as num?)?.toDouble() ?? 0.0;
      final int reps = (pr['reps'] as num?)?.toInt() ?? 0;
      return '${weight.toStringAsFixed(1)} $weightUnit x $reps reps';
    } else if (type == 'TOTAL') {
      if (val is num) {
        return '${val.toStringAsFixed(1)} $weightUnit Volume';
      } else if (val is Duration) {
        return val.format();
      }
    } else if (type == 'TIME' || type == 'HOLD') {
      if (val is Duration) {
        return val.format();
      }
    } else if (type == 'DIST') {
      if (val is num) {
        return '${val.toStringAsFixed(2)} km';
      }
    }
    return val?.toString() ?? '';
  }
}
