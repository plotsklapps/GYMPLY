import 'package:flutter/material.dart';
import 'package:gymply/modals/monthstat_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/widgets/metricselector_widget.dart';
import 'package:gymply/widgets/progresschart_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class ExerciseHistoryModal extends StatefulWidget {
  const ExerciseHistoryModal({
    required this.exercise,
    super.key,
  });

  final WorkoutExercise exercise;

  @override
  State<ExerciseHistoryModal> createState() {
    return _ExerciseHistoryModalState();
  }
}

class _ExerciseHistoryModalState extends State<ExerciseHistoryModal> {
  // Default to Volume for Strength, or Distance/Time for others.
  WorkoutMetric _selectedMetric = WorkoutMetric.volume;

  @override
  void initState() {
    super.initState();
    // Set a sensible default based on exercise type.
    if (widget.exercise.imagePath.contains('cardio')) {
      _selectedMetric = WorkoutMetric.distance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch history signals.
    final List<Workout> history = workoutService.sWorkoutHistory.watch(context);
    final Workout active = workoutService.sActiveWorkout.watch(context);

    // Combine history and active workout to get all occurrences.
    final List<Workout> allWorkouts = <Workout>[...history];
    if (active.exercises.isNotEmpty) {
      allWorkouts.add(active);
    }

    // Filter for workouts containing this specific exercise.
    final List<Workout> relevantWorkouts =
        allWorkouts.where((Workout w) {
            return w.exercises.any(
              (WorkoutExercise ex) {
                return ex.exerciseName == widget.exercise.exerciseName;
              },
            );
          }).toList()
          // Sort by date (ascending) for the chart.
          ..sort(
            (Workout a, Workout b) {
              return a.dateTime.compareTo(b.dateTime);
            },
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Header.
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                '${widget.exercise.exerciseName.capitalizeAll()} HISTORY',
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
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),

        if (relevantWorkouts.isEmpty)
          const Text('No history found for this exercise yet.')
        else ...<Widget>[
          // The adaptive progress chart.
          ProgressChart(
            workouts: relevantWorkouts,
            exerciseName: widget.exercise.exerciseName,
            selectedMetric: _selectedMetric,
          ),
          const SizedBox(height: 24),

          // Metric Selector.
          MetricSelector(
            selectedMetric: _selectedMetric,
            onSelected: (WorkoutMetric metric) {
              setState(() {
                _selectedMetric = metric;
              });
            },
          ),
        ],
      ],
    );
  }
}
