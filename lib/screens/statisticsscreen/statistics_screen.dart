import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/statisticsscreen/exercisedetailcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/monthstat_widget.dart';
import 'package:gymply/screens/statisticsscreen/sectionheader_widget.dart';
import 'package:gymply/screens/statisticsscreen/stattile_widget.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
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
    final List<Workout> history = workoutService.sWorkoutHistory.watch(context);

    // Watch sActiveWorkout for live statistics of current workout.
    final Workout activeWorkout = workoutService.sActiveWorkout.watch(context);

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

    return Scaffold(
      body: Column(
        children: <Widget>[
          // QUARTERLY MONTH STATS (Heatmap).
          SizedBox(
            height: 94,
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
                            // Today's workout and Date.
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
                      // Notes section.
                      if (currentWorkout.notes.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Notes: ${currentWorkout.notes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
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
                            icon: FontAwesomeIcons.dumbbell,
                          ),
                          StatTile(
                            label: 'Sets',
                            value: currentWorkout.totalSets.toString(),
                            icon: FontAwesomeIcons.arrowUpWideShort,
                          ),
                          StatTile(
                            label: 'Time',
                            value: currentWorkout.totalDuration.formatHHMM(),
                            icon: FontAwesomeIcons.stopwatch,
                          ),
                        ],
                      ),
                      // Strength Totals Section (Conditional).
                      if (currentWorkout.totalStrengthVolume > 0) ...<Widget>[
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
                              icon: FontAwesomeIcons.weightHanging,
                            ),
                            StatTile(
                              label: 'Reps',
                              value: currentWorkout.totalReps.toString(),
                              icon: FontAwesomeIcons.arrowUp19,
                            ),
                            StatTile(
                              label: 'Avg Weight',
                              value:
                                  '${currentWorkout.avgWorkoutWeight.toStringAsFixed(1)}kg',
                              icon: FontAwesomeIcons.gauge,
                            ),
                          ],
                        ),
                      ],
                      // Cardio Totals Section (Conditional).
                      if (currentWorkout.totalCardioDuration >
                          Duration.zero) ...<Widget>[
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
                              value:
                                  '${currentWorkout.totalCardioDistance.toStringAsFixed(1)}km',
                              icon: FontAwesomeIcons.personRunning,
                            ),
                            StatTile(
                              label: 'Calories',
                              value:
                                  '${currentWorkout.totalCardioCalories}kcal',
                              icon: FontAwesomeIcons.fire,
                            ),
                            StatTile(
                              label: 'Duration',
                              value: currentWorkout.totalCardioTime.format(),
                              icon: FontAwesomeIcons.solidClock,
                            ),
                          ],
                        ),
                      ],
                      // Stretch Totals Section (Conditional).
                      if (currentWorkout.totalStretchTime >
                          Duration.zero) ...<Widget>[
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
                              label: 'Stretch',
                              value: currentWorkout.totalStretchTime.format(),
                              icon: FontAwesomeIcons.personBurst,
                            ),
                            StatTile(
                              label: 'Duration',
                              value: currentWorkout.totalCardioDuration
                                  .format(),
                              icon: FontAwesomeIcons.personPraying,
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
