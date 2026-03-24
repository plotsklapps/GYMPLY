import 'package:flutter/material.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/statisticsscreen/exercisedetailcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/monthstat_widget.dart';
import 'package:gymply/screens/statisticsscreen/prcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/sectionheader_widget.dart';
import 'package:gymply/screens/statisticsscreen/stattile_widget.dart';
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

  // Always use current year.
  final int _targetYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    // Calculate current quarter index (0-3).
    final int currentQuarter = (DateTime.now().month - 1) ~/ 3;
    // Set PageController to show currentQuarter on init.
    _pageController = PageController(initialPage: currentQuarter);
  }

  @override
  void dispose() {
    // Kill PageController.
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch sWorkoutHistory for past workouts (heatmap dots).
    final List<Workout> history = sWorkoutHistory.watch(context);

    // Watch sActiveWorkout for live statistics of current workout.
    final Workout activeWorkout = sActiveWorkout.watch(context);

    // Watch personal stats for calorie calculation.
    final double userWeight = sWeight.watch(context);
    final int userAge = sAge.watch(context);
    final int userSex = sSex.watch(context);

    // Store workout dates in a Set for quick lookups in heatmap.
    final Set<String> workoutDateKeys = history.map((Workout w) {
      return w.dateKey;
    }).toSet();

    // If active workout has exercises, today has a dot too.
    if (activeWorkout.exercises.isNotEmpty) {
      workoutDateKeys.add(activeWorkout.dateKey);
    }

    // Use activeWorkout as source of truth for "Today".
    final Workout? currentWorkout = activeWorkout.exercises.isEmpty
        ? null
        : activeWorkout;

    // Pre-calculate formatted strings for totals sections to keep lines short.
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

    // Fetch PRs for the current workout.
    final List<Map<String, dynamic>> workoutPRs = currentWorkout != null
        ? workoutService.getWorkoutPRs(currentWorkout)
        : <Map<String, dynamic>>[];

    return Scaffold(
      body: Column(
        children: <Widget>[
          // QUARTERLY MONTH STATS (Heatmap).
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                ? const Center(
                    child: Text('No workout recorded today.'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            // Workout Title and Date.
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
                          // Today's ID and dateKey.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                'ID: ${currentWorkout.id.substring(0, 8)}',
                                style: theme.textTheme.labelSmall,
                              ),
                              Text(
                                'dateKey: ${currentWorkout.dateKey}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // If any PR's were broken, show them.
                      if (workoutPRs.isNotEmpty) ...<Widget>[
                        const StatisticsSectionHeader(
                          title: 'NEW ACHIEVEMENTS',
                        ),
                        PRCard(workoutPRs: workoutPRs),
                      ],
                      const SizedBox(height: 12),
                      // Workout Overview Section.
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
                      // Strength Totals Section (Conditional).
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
                      // Cardio Totals Section (Conditional).
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
                      // Stretch Totals Section (Conditional).
                      if (currentWorkout.stretchExerciseCount > 0) ...<Widget>[
                        const SizedBox(height: 12),
                        const StatisticsSectionHeader(
                          title: 'STRETCH TOTALS',
                        ),
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
                        (WorkoutExercise ex) {
                          return ExerciseDetailCard(exercise: ex);
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
