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
import 'package:gymply/signals/workouthistory_signal.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:gymply/theme/icons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

class YearlySummaryModal extends SignalStatefulWidget {
  const YearlySummaryModal({required this.year, super.key});

  final int year;

  @override
  State<YearlySummaryModal> createState() {
    return _YearlySummaryModalState();
  }
}

class _YearlySummaryModalState extends State<YearlySummaryModal> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Workout> history = sWorkoutHistory.value;

    // Filter workouts for the given year.
    final List<Workout> yearWorkouts = history.where((Workout w) {
      return w.dateTime.year == widget.year;
    }).toList();

    final String yearTitle = '${widget.year} YEAR IN REVIEW';
    final String weightUnit = sUseLbs.value ? 'lbs' : 'kg';

    if (yearWorkouts.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  '${widget.year} WRAPPED',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
            child: Column(
              children: <Widget>[
                Icon(
                  IconUtils.calendarMonth,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'NO WORKOUTS RECORDED IN ${widget.year}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No workout history found for ${widget.year}.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // --- Calculations for Year Summary ---

    final int totalWorkouts = yearWorkouts.length;
    final int totalDurationSecs = yearWorkouts.fold(0, (int sum, Workout w) {
      return sum + w.totalDuration;
    });
    final int totalSets = yearWorkouts.fold(0, (int sum, Workout w) {
      return sum + w.totalSets;
    });
    final double totalVolume = yearWorkouts.fold(0, (double sum, Workout w) {
      return sum + w.totalStrengthVolume;
    });
    final int totalReps = yearWorkouts.fold(0, (int sum, Workout w) {
      return sum + w.totalReps;
    });

    // Busiest Month Calculation
    final Map<int, int> monthlyWorkoutCounts = <int, int>{};
    for (final Workout w in yearWorkouts) {
      final int month = w.dateTime.month;
      monthlyWorkoutCounts[month] = (monthlyWorkoutCounts[month] ?? 0) + 1;
    }
    MapEntry<int, int>? busiestMonthEntry;
    if (monthlyWorkoutCounts.isNotEmpty) {
      final List<MapEntry<int, int>> sortedMonths =
          monthlyWorkoutCounts.entries.toList()
            ..sort((MapEntry<int, int> a, MapEntry<int, int> b) {
              return b.value.compareTo(a.value);
            });
      busiestMonthEntry = sortedMonths.first;
    }

    // Muscle Group Analysis
    final Map<MuscleGroup, int> muscleSetCounts = <MuscleGroup, int>{};
    final List<MuscleGroup> allWorkedMuscles = <MuscleGroup>[];

    // Top Exercises & Equipment
    final Map<String, int> exerciseSetCounts = <String, int>{};
    final Map<Equipment, int> equipmentCounts = <Equipment, int>{};

    // PRs in this year
    final List<Map<String, dynamic>> yearPRs = <Map<String, dynamic>>[];

    for (final Workout w in yearWorkouts) {
      final List<Map<String, dynamic>> prs = workoutService.getWorkoutPRs(w);
      yearPRs.addAll(prs);

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

    // Top 5 Exercises
    final List<MapEntry<String, int>> topExercises =
        exerciseSetCounts.entries.toList()..sort(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              b.value.compareTo(a.value),
        );
    final List<MapEntry<String, int>> top5Exercises = topExercises
        .take(5)
        .toList();

    // Top 5 Equipment
    final List<MapEntry<Equipment, int>> topEquipment =
        equipmentCounts.entries.toList()..sort(
          (MapEntry<Equipment, int> a, MapEntry<Equipment, int> b) =>
              b.value.compareTo(a.value),
        );
    final List<MapEntry<Equipment, int>> top5Equipment = topEquipment
        .take(5)
        .toList();

    // Peak Days
    Workout? peakVolumeWorkout;
    Workout? peakSetsWorkout;
    Workout? peakRepsWorkout;

    for (final Workout w in yearWorkouts) {
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
                    yearTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'YEARLY WRAPPED',
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

                // 2. BUSIEST MONTH BANNER
                if (busiestMonthEntry != null) ...<Widget>[
                  Card(
                    color: theme.colorScheme.secondary,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            IconUtils.calendarMonth,
                            size: 36,
                            color: theme.colorScheme.onSecondary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'BUSIEST MONTH',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSecondary,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMMM')
                                      .format(
                                        DateTime(
                                          widget.year,
                                          busiestMonthEntry.key,
                                        ),
                                      )
                                      .toUpperCase(),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSecondary,
                                      ),
                                ),
                                Text(
                                  '${busiestMonthEntry.value} Workouts completed',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 3. MUSCLE FOCUS & BODY ATLAS
                if (allWorkedMuscles.isNotEmpty) ...<Widget>[
                  Text(
                    'YEARLY MUSCLE ACTIVATION',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
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
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 4. PEAK PERFORMANCE DAYS OF THE YEAR
                Text(
                  'PEAK DAYS OF THE YEAR',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 8),
                Column(
                  children: <Widget>[
                    if (peakVolumeWorkout != null &&
                        peakVolumeWorkout.totalStrengthVolume > 0)
                      _buildPeakCard(
                        theme,
                        title: 'RECORD VOLUME DAY',
                        subtitle: DateFormat.yMMMMd().format(
                          peakVolumeWorkout.dateTime,
                        ),
                        value:
                            '${peakVolumeWorkout.totalStrengthVolume.toStringAsFixed(0)} $weightUnit',
                        icon: IconUtils.weight,
                      ),
                    if (peakSetsWorkout != null &&
                        peakSetsWorkout.totalSets > 0)
                      _buildPeakCard(
                        theme,
                        title: 'MOST SETS DAY',
                        subtitle: DateFormat.yMMMMd().format(
                          peakSetsWorkout.dateTime,
                        ),
                        value: '${peakSetsWorkout.totalSets} SETS',
                        icon: IconUtils.numbers,
                      ),
                    if (peakRepsWorkout != null &&
                        peakRepsWorkout.totalReps > 0)
                      _buildPeakCard(
                        theme,
                        title: 'MOST REPS DAY',
                        subtitle: DateFormat.yMMMMd().format(
                          peakRepsWorkout.dateTime,
                        ),
                        value: '${peakRepsWorkout.totalReps} REPS',
                        icon: IconUtils.speed,
                      ),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // 5. TOP 5 EXERCISES OF THE YEAR
                if (top5Exercises.isNotEmpty) ...<Widget>[
                  Text(
                    'TOP 5 EXERCISES OF THE YEAR',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: List<Widget>.generate(top5Exercises.length, (
                          int i,
                        ) {
                          final MapEntry<String, int> entry = top5Exercises[i];
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
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 6. TOP 5 EQUIPMENT OF THE YEAR
                if (top5Equipment.isNotEmpty) ...<Widget>[
                  Text(
                    'TOP 5 EQUIPMENT OF THE YEAR',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: List<Widget>.generate(top5Equipment.length, (
                          int i,
                        ) {
                          final MapEntry<Equipment, int> entry =
                              top5Equipment[i];
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
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),
                ],

                // 7. YEAR PERSONAL RECORDS
                if (yearPRs.isNotEmpty) ...<Widget>[
                  Text(
                    'PERSONAL RECORDS ACHIEVED (${yearPRs.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: yearPRs.take(10).map((
                          Map<String, dynamic> pr,
                        ) {
                          return ListTile(
                            leading: const Icon(
                              IconUtils.medal,
                              color: Colors.amber,
                            ),
                            title: Text(
                              pr['exerciseName'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(pr['metric'] as String),
                            trailing: Text(
                              pr['value'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1, end: 0),
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
}
