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

enum SummaryMetric { volume, sets, reps, exercises }

class YearlySummaryModal extends SignalStatefulWidget {
  const YearlySummaryModal({required this.year, super.key});

  final int year;

  @override
  State<YearlySummaryModal> createState() {
    return _YearlySummaryModalState();
  }
}

class _YearlySummaryModalState extends State<YearlySummaryModal> {
  SummaryMetric _selectedMetric = SummaryMetric.volume;

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

    // Metric Calculations for Muscle Focus, Top Exercises, Top Equipment
    final Map<MuscleGroup, double> muscleMetricMap = <MuscleGroup, double>{};
    final List<MuscleGroup> allWorkedMuscles = <MuscleGroup>[];
    final Map<String, double> exerciseMetricMap = <String, double>{};
    final Map<Equipment, double> equipmentMetricMap = <Equipment, double>{};

    // PRs in this year
    final List<Map<String, dynamic>> yearPRs = <Map<String, dynamic>>[];

    for (final Workout w in yearWorkouts) {
      final List<Map<String, dynamic>> prs = workoutService.getWorkoutPRs(w);
      yearPRs.addAll(prs);

      for (final WorkoutExercise ex in w.exercises) {
        double val = 0;
        if (_selectedMetric == SummaryMetric.volume) {
          val = ex is StrengthExercise ? ex.totalWeight : 0.0;
        } else if (_selectedMetric == SummaryMetric.sets) {
          val = ex.totalSets.toDouble();
        } else if (_selectedMetric == SummaryMetric.reps) {
          val = ex is StrengthExercise ? ex.totalReps.toDouble() : 0.0;
        } else if (_selectedMetric == SummaryMetric.exercises) {
          val = 1.0;
        }

        exerciseMetricMap[ex.exerciseName] =
            (exerciseMetricMap[ex.exerciseName] ?? 0.0) + val;

        if (ex is StrengthExercise) {
          muscleMetricMap[ex.muscleGroup] =
              (muscleMetricMap[ex.muscleGroup] ?? 0.0) + val;
          allWorkedMuscles.add(ex.muscleGroup);

          equipmentMetricMap[ex.equipment] =
              (equipmentMetricMap[ex.equipment] ?? 0.0) + val;
        } else if (ex is CardioExercise) {
          equipmentMetricMap[ex.equipment] =
              (equipmentMetricMap[ex.equipment] ?? 0.0) + val;
        }
      }
    }

    // Sort Muscle Groups
    final List<MapEntry<MuscleGroup, double>> sortedMuscles =
        muscleMetricMap.entries.toList()
          ..sort((MapEntry<MuscleGroup, double> a, MapEntry<MuscleGroup, double> b) {
            return b.value.compareTo(a.value);
          });

    final List<MapEntry<MuscleGroup, double>> top3Muscles =
        sortedMuscles.take(3).toList();

    MuscleGroup? leastTrainedMuscle;
    for (final MuscleGroup mg in MuscleGroup.values) {
      if (mg != MuscleGroup.fullbody) {
        if (!muscleMetricMap.containsKey(mg)) {
          leastTrainedMuscle = mg;
          break;
        }
      }
    }
    if (leastTrainedMuscle == null && sortedMuscles.isNotEmpty) {
      leastTrainedMuscle = sortedMuscles.last.key;
    }

    // Top 5 Exercises
    final List<MapEntry<String, double>> sortedExercises =
        exerciseMetricMap.entries.toList()
          ..sort((MapEntry<String, double> a, MapEntry<String, double> b) {
            return b.value.compareTo(a.value);
          });
    final List<MapEntry<String, double>> top5Exercises =
        sortedExercises.take(5).toList();

    // Top 5 Equipment
    final List<MapEntry<Equipment, double>> sortedEquipment =
        equipmentMetricMap.entries.toList()
          ..sort((MapEntry<Equipment, double> a, MapEntry<Equipment, double> b) {
            return b.value.compareTo(a.value);
          });
    final List<MapEntry<Equipment, double>> top5Equipment =
        sortedEquipment.take(5).toList();

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

                // METRIC SELECTOR BUTTONS
                Center(
                  child: SegmentedButton<SummaryMetric>(
                    segments: const <ButtonSegment<SummaryMetric>>[
                      ButtonSegment<SummaryMetric>(
                        value: SummaryMetric.volume,
                        label: Text('Volume'),
                        icon: Icon(IconUtils.weight, size: 16),
                      ),
                      ButtonSegment<SummaryMetric>(
                        value: SummaryMetric.sets,
                        label: Text('Sets'),
                        icon: Icon(IconUtils.numbers, size: 16),
                      ),
                      ButtonSegment<SummaryMetric>(
                        value: SummaryMetric.reps,
                        label: Text('Reps'),
                        icon: Icon(IconUtils.speed, size: 16),
                      ),
                      ButtonSegment<SummaryMetric>(
                        value: SummaryMetric.exercises,
                        label: Text('Exercises'),
                        icon: Icon(IconUtils.dumbbell, size: 16),
                      ),
                    ],
                    selected: <SummaryMetric>{_selectedMetric},
                    onSelectionChanged: (Set<SummaryMetric> selection) {
                      setState(() {
                        _selectedMetric = selection.first;
                      });
                    },
                  ),
                ).animate().fadeIn(delay: 50.ms),

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
                                  child: atlas.BodyAtlasView<
                                    atlas.MuscleInfo
                                  >(
                                    view: atlas.AtlasAsset.musclesFront,
                                    resolver: const atlas.MuscleResolver(),
                                    colorMapping: atlasColors,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 200,
                                  child: atlas.BodyAtlasView<
                                    atlas.MuscleInfo
                                  >(
                                    view: atlas.AtlasAsset.musclesBack,
                                    resolver: const atlas.MuscleResolver(),
                                    colorMapping: atlasColors,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 2x2 Grid of Top 3 Muscles + Least Attention
                          Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _buildFocusBadge(
                                      theme,
                                      label: '#1 MOST FOCUS',
                                      muscleName: top3Muscles.isNotEmpty
                                          ? top3Muscles[0].key.name.capitalizeFirst()
                                          : 'N/A',
                                      valStr: top3Muscles.isNotEmpty
                                          ? _formatMetricVal(
                                              top3Muscles[0].value,
                                              weightUnit,
                                            )
                                          : '-',
                                      isHighlight: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFocusBadge(
                                      theme,
                                      label: '#2 FOCUS',
                                      muscleName: top3Muscles.length > 1
                                          ? top3Muscles[1].key.name.capitalizeFirst()
                                          : 'N/A',
                                      valStr: top3Muscles.length > 1
                                          ? _formatMetricVal(
                                              top3Muscles[1].value,
                                              weightUnit,
                                            )
                                          : '-',
                                      isHighlight: false,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _buildFocusBadge(
                                      theme,
                                      label: '#3 FOCUS',
                                      muscleName: top3Muscles.length > 2
                                          ? top3Muscles[2].key.name.capitalizeFirst()
                                          : 'N/A',
                                      valStr: top3Muscles.length > 2
                                          ? _formatMetricVal(
                                              top3Muscles[2].value,
                                              weightUnit,
                                            )
                                          : '-',
                                      isHighlight: false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildFocusBadge(
                                      theme,
                                      label: 'LEAST ATTENTION',
                                      muscleName: leastTrainedMuscle != null
                                          ? leastTrainedMuscle.name.capitalizeFirst()
                                          : 'N/A',
                                      valStr: leastTrainedMuscle != null
                                          ? _formatMetricVal(
                                              muscleMetricMap[leastTrainedMuscle] ?? 0.0,
                                              weightUnit,
                                            )
                                          : '-',
                                      isHighlight: false,
                                    ),
                                  ),
                                ],
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
                          final MapEntry<String, double> entry = top5Exercises[i];
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
                              _formatMetricVal(entry.value, weightUnit),
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
                          final MapEntry<Equipment, double> entry =
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
                              _formatMetricVal(entry.value, weightUnit),
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
                          final String exerciseName =
                              (pr['exerciseName'] as String? ?? 'PR')
                                  .toUpperCase();
                          final String prType =
                              (pr['type'] as String? ?? 'PR').toUpperCase();
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

  String _formatMetricVal(double val, String weightUnit) {
    if (_selectedMetric == SummaryMetric.volume) {
      return '${val.toStringAsFixed(0)} $weightUnit';
    } else if (_selectedMetric == SummaryMetric.sets) {
      return '${val.toInt()} Sets';
    } else if (_selectedMetric == SummaryMetric.reps) {
      return '${val.toInt()} Reps';
    } else {
      return '${val.toInt()} Exercises';
    }
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
    required String valStr,
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
            valStr,
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
