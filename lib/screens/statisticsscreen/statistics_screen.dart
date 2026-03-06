import 'package:flutter/material.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/statisticsscreen/monthstat_widget.dart';
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

  String _formatDuration(Duration d) {
    final String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // 1. Watch sWorkoutHistory for the heatmap dots (past workouts).
    final List<Workout> history = workoutService.sWorkoutHistory.watch(context);

    // 2. Watch sActiveWorkout for live, real-time statistics of the current session.
    final Workout activeWorkout = workoutService.sActiveWorkout.watch(context);

    // Store workout dates in a Set for quick lookups in the heatmap.
    final Set<String> workoutDateKeys = history.map((Workout w) {
      return w.dateKey;
    }).toSet();

    // If active workout has exercises, make sure today lights up on the heatmap too.
    if (activeWorkout.exercises.isNotEmpty) {
      workoutDateKeys.add(activeWorkout.dateKey);
    }

    // Use activeWorkout as our source of truth for "Today".
    // If it's empty, we show the "No workout" message.
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
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ID: ${currentWorkout.id.length > 8 ? currentWorkout.id.substring(0, 8) : currentWorkout.id}',
                                style: theme.textTheme.labelSmall,
                              ),
                              Text(
                                'Sets: ${currentWorkout.totalSets}',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (currentWorkout.notes.isNotEmpty) ...[
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
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'WORKOUT OVERVIEW'),
                      _buildStatGrid([
                        _StatTile(
                          label: 'Exercises',
                          value: currentWorkout.exerciseCount.toString(),
                          icon: Icons.fitness_center,
                        ),
                        _StatTile(
                          label: 'Total Sets',
                          value: currentWorkout.totalSets.toString(),
                          icon: Icons.repeat,
                        ),
                        _StatTile(
                          label: 'Wall Time',
                          value: '${currentWorkout.totalDuration}m',
                          icon: Icons.timer,
                        ),
                      ]),
                      if (currentWorkout.totalStrengthVolume > 0) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, 'STRENGTH TOTALS'),
                        _buildStatGrid([
                          _StatTile(
                            label: 'Volume',
                            value:
                                '${currentWorkout.totalStrengthVolume.toStringAsFixed(1)}kg',
                            icon: Icons.line_weight,
                          ),
                          _StatTile(
                            label: 'Total Reps',
                            value: currentWorkout.totalReps.toString(),
                            icon: Icons.reorder,
                          ),
                          _StatTile(
                            label: 'Avg Weight',
                            value:
                                '${currentWorkout.avgWorkoutWeight.toStringAsFixed(1)}kg',
                            icon: Icons.analytics,
                          ),
                        ]),
                      ],
                      if (currentWorkout.totalCardioDistance > 0 ||
                          currentWorkout.totalCardioCalories > 0) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, 'CARDIO TOTALS'),
                        _buildStatGrid([
                          _StatTile(
                            label: 'Distance',
                            value:
                                '${currentWorkout.totalCardioDistance.toStringAsFixed(2)}km',
                            icon: Icons.directions_run,
                          ),
                          _StatTile(
                            label: 'Calories',
                            value: '${currentWorkout.totalCardioCalories}kcal',
                            icon: Icons.local_fire_department,
                          ),
                          _StatTile(
                            label: 'Duration',
                            value: _formatDuration(
                              currentWorkout.totalCardioTime,
                            ),
                            icon: Icons.schedule,
                          ),
                        ]),
                      ],
                      if (currentWorkout.totalStretchTime > Duration.zero) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader(
                          context,
                          'FLEXIBILITY & ACTIVE TIME',
                        ),
                        _buildStatGrid([
                          _StatTile(
                            label: 'Stretch',
                            value: _formatDuration(
                              currentWorkout.totalStretchTime,
                            ),
                            icon: Icons.self_improvement,
                          ),
                          _StatTile(
                            label: 'Active Dur.',
                            value: _formatDuration(
                              currentWorkout.totalCardioDuration,
                            ),
                            icon: Icons.av_timer,
                          ),
                        ]),
                      ],
                      const SizedBox(height: 32),
                      _buildSectionHeader(context, 'EXERCISE BREAKDOWN'),
                      ...currentWorkout.exercises.map(
                        (ex) => _buildExerciseDetailCard(context, ex),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatGrid(List<_StatTile> tiles) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: tiles,
    );
  }

  Widget _buildExerciseDetailCard(BuildContext context, WorkoutExercise ex) {
    final theme = Theme.of(context);
    final List<Widget> detailRows = [];

    if (ex is StrengthExercise) {
      detailRows.addAll([
        _DetailRow(
          label: 'Muscle Group',
          value: ex.muscleGroup.name.toUpperCase(),
        ),
        _DetailRow(label: 'Equipment', value: ex.equipment.name.toUpperCase()),
        _DetailRow(label: 'Sets', value: ex.totalSets.toString()),
        _DetailRow(label: 'Reps', value: ex.totalReps.toString()),
        _DetailRow(
          label: 'Volume',
          value: '${ex.totalWeight.toStringAsFixed(1)} kg',
        ),
        _DetailRow(
          label: 'Avg Weight/Rep',
          value: '${ex.avgWeightPerRep.toStringAsFixed(1)} kg',
        ),
        _DetailRow(
          label: 'Avg Weight/Set',
          value: '${ex.avgWeightPerSet.toStringAsFixed(1)} kg',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4.0),
          child: Divider(),
        ),
        Text(
          '1RM Estimates',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        _DetailRow(
          label: 'Brzycki',
          value: '${ex.oneRepMaxBrzycki.toStringAsFixed(1)} kg',
        ),
        _DetailRow(
          label: 'Epley',
          value: '${ex.oneRepMaxEpley.toStringAsFixed(1)} kg',
        ),
        _DetailRow(
          label: 'Lombardi',
          value: '${ex.oneRepMaxLombardi.toStringAsFixed(1)} kg',
        ),
      ]);
    } else if (ex is CardioExercise) {
      detailRows.addAll([
        _DetailRow(label: 'Equipment', value: ex.equipment.name.toUpperCase()),
        _DetailRow(label: 'Sets', value: ex.totalSets.toString()),
        _DetailRow(label: 'Duration', value: _formatDuration(ex.totalDuration)),
        _DetailRow(
          label: 'Distance',
          value: '${ex.totalDistance.toStringAsFixed(2)} km',
        ),
        _DetailRow(label: 'Calories', value: '${ex.totalCalories} kcal'),
      ]);
    } else if (ex is StretchExercise) {
      detailRows.addAll([
        _DetailRow(label: 'Sets', value: ex.totalSets.toString()),
        _DetailRow(label: 'Duration', value: _formatDuration(ex.totalDuration)),
      ]);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (ex.imagePath.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Image.asset(
                      ex.imagePath,
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fitness_center),
                    ),
                  ),
                Expanded(
                  child: Text(
                    ex.exerciseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...detailRows,
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
