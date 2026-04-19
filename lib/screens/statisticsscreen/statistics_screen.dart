import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart' as atlas;
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/statisticsscreen/exercisedetailcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/monthstat_widget.dart';
import 'package:gymply/screens/statisticsscreen/prcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/sectionheader_widget.dart';
import 'package:gymply/screens/statisticsscreen/stattile_widget.dart';
import 'package:gymply/services/atlas_mapper.dart';
import 'package:gymply/services/atlas_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:gymply/signals/workouthistory_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() {
    return _StatisticsScreenState();
  }
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final PageController _pageController;

  final int _targetYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final int currentQuarter = (DateTime.now().month - 1) ~/ 3;
    _pageController = PageController(initialPage: currentQuarter);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Workout> history = sWorkoutHistory.watch(context);
    final Workout activeWorkout = sActiveWorkout.watch(context);
    final double userWeight = sWeight.watch(context);
    final int userAge = sAge.watch(context);
    final int userSex = sSex.watch(context);

    final Set<String> workoutDateKeys = history
        .map((Workout w) => w.dateKey)
        .toSet();
    if (activeWorkout.exercises.isNotEmpty) {
      workoutDateKeys.add(activeWorkout.dateKey);
    }

    final Workout? currentWorkout = activeWorkout.exercises.isEmpty
        ? null
        : activeWorkout;

    final String avgWeight =
        currentWorkout?.avgWorkoutWeight.toStringAsFixed(1) ?? '0.0';
    final String cardioDist =
        currentWorkout?.totalCardioDistance.toStringAsFixed(1) ?? '0.0';
    final String cardioCals =
        currentWorkout
            ?.calculateTotalCardioCalories(
              userWeight: userWeight,
              userAge: userAge,
              userSex: userSex,
            )
            .toString() ??
        '0';
    final String stretchCals =
        currentWorkout
            ?.calculateTotalStretchCalories(
              userWeight: userWeight,
              userAge: userAge,
              userSex: userSex,
            )
            .toString() ??
        '0';

    final List<Map<String, dynamic>> workoutPRs = currentWorkout != null
        ? workoutService.getWorkoutPRs(currentWorkout)
        : <Map<String, dynamic>>[];

    final List<MuscleGroup> workedMuscles = <MuscleGroup>[];
    if (currentWorkout != null) {
      for (final WorkoutExercise ex in currentWorkout.exercises) {
        if (ex is StrengthExercise) {
          workedMuscles.add(ex.muscleGroup);
        }
      }
    }

    final Map<String, double> intensityMap = getAtlasIntensityMap(
      workedMuscles,
    );

    final Map<atlas.MuscleInfo, Color> atlasColors = atlasService
        .getAtlasColors(workedMuscles, theme.colorScheme);

    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 100,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 4,
              itemBuilder: (BuildContext context, int quarterIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List<Widget>.generate(3, (int monthInQuarter) {
                      final int month = (quarterIndex * 3) + monthInQuarter + 1;
                      return MonthStat(
                        date: DateTime(_targetYear, month),
                        workoutDateKeys: workoutDateKeys,
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(
            child: currentWorkout == null
                ? const Center(child: Text('No workout recorded today.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  currentWorkout.title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  currentWorkout.formattedDate,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (workoutPRs.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        const StatisticsSectionHeader(
                          title: 'NEW ACHIEVEMENTS',
                        ),
                        PRCard(workoutPRs: workoutPRs),
                      ],
                      if (intensityMap.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        const StatisticsSectionHeader(
                          title: 'MUSCLE ACTIVATION',
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(
                                height: 250,
                                child: atlas.BodyAtlasView<atlas.MuscleInfo>(
                                  view: atlas.AtlasAsset.musclesFront,
                                  resolver: const atlas.MuscleResolver(),
                                  colorMapping: atlasColors,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                height: 250,
                                child: atlas.BodyAtlasView<atlas.MuscleInfo>(
                                  view: atlas.AtlasAsset.musclesBack,
                                  resolver: const atlas.MuscleResolver(),
                                  colorMapping: atlasColors,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const StatisticsSectionHeader(title: 'WORKOUT OVERVIEW'),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: <Widget>[
                          StatTile(
                            label: 'Exercises',
                            value: currentWorkout.exerciseCount.toString(),
                            icon: LucideIcons.dumbbell,
                          ),
                          StatTile(
                            label: 'Sets',
                            value: currentWorkout.totalSets.toString(),
                            icon: LucideIcons.arrowUpWideNarrow,
                          ),
                          StatTile(
                            label: 'Time',
                            value: currentWorkout.totalDuration.formatHHMM(),
                            icon: LucideIcons.timer,
                          ),
                        ],
                      ),
                      if (currentWorkout.strengthExerciseCount > 0) ...<Widget>[
                        const SizedBox(height: 12),
                        const StatisticsSectionHeader(title: 'STRENGTH TOTALS'),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: <Widget>[
                            StatTile(
                              label: 'Volume',
                              value: '${currentWorkout.totalStrengthVolume} kg',
                              icon: LucideIcons.weight,
                            ),
                            StatTile(
                              label: 'Reps',
                              value: currentWorkout.totalReps.toString(),
                              icon: LucideIcons.arrowUp10,
                            ),
                            StatTile(
                              label: 'Avg Weight',
                              value: '${avgWeight}kg',
                              icon: LucideIcons.circleGauge,
                            ),
                          ],
                        ),
                      ],
                      if (currentWorkout.cardioExerciseCount > 0) ...<Widget>[
                        const SizedBox(height: 12),
                        const StatisticsSectionHeader(title: 'CARDIO TOTALS'),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: <Widget>[
                            StatTile(
                              label: 'Distance',
                              value: '${cardioDist}km',
                              icon: LucideIcons.rulerDimensionLine,
                            ),
                            StatTile(
                              label: 'Calories',
                              value: '${cardioCals}kcal',
                              icon: LucideIcons.flame,
                            ),
                            StatTile(
                              label: 'Duration',
                              value: currentWorkout.totalCardioTime.format(),
                              icon: LucideIcons.clock,
                            ),
                          ],
                        ),
                      ],
                      if (currentWorkout.stretchExerciseCount > 0) ...<Widget>[
                        const SizedBox(height: 12),
                        const StatisticsSectionHeader(title: 'STRETCH TOTALS'),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          children: <Widget>[
                            StatTile(
                              label: 'Stretch Count',
                              value: currentWorkout.stretchExerciseCount
                                  .toString(),
                              icon: LucideIcons.personStanding,
                            ),
                            StatTile(
                              label: 'Calories',
                              value: '${stretchCals}kcal',
                              icon: LucideIcons.flame,
                            ),
                            StatTile(
                              label: 'Duration',
                              value: currentWorkout.totalStretchTime.format(),
                              icon: LucideIcons.clock,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      const StatisticsSectionHeader(
                        title: 'EXERCISE BREAKDOWN',
                      ),
                      ...currentWorkout.exercises.map(
                        (WorkoutExercise ex) =>
                            ExerciseDetailCard(exercise: ex),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
