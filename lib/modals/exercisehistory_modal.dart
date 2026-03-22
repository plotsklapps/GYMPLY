import 'package:flutter/material.dart';
import 'package:gymply/modals/monthstat_modal.dart';
import 'package:gymply/models/personal_record_model.dart';
import 'package:gymply/models/strength_model.dart';
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

          if (widget.exercise is StrengthExercise) ...<Widget>[
            const SizedBox(height: 24),
            const Divider(),
            Builder(
              builder: (BuildContext context) {
                // Create PersonalRecord Object for this exercise.
                final PersonalRecord pr = workoutService.getPersonalRecords(
                  widget.exercise.id,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PERSONAL RECORDS',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _PersonalRecordItem(
                          label: 'REP PR',
                          value: '${pr.maxWeight.toStringAsFixed(1)} kg',
                        ),
                        _PersonalRecordItem(
                          label: 'SET PR',
                          value: '${pr.maxSetVolume.toStringAsFixed(1)} kg',
                        ),
                        _PersonalRecordItem(
                          label: 'SESSION PR',
                          value:
                              '${pr.maxExerciseVolume.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      '1RM ESTIMATES',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _OneRepMaxItem(
                          label: 'LOMBARDI',
                          repRange: '1-5 reps',
                          value:
                              '${(widget.exercise as StrengthExercise).oneRepMaxLombardi.toStringAsFixed(1)} kg',
                        ),
                        _OneRepMaxItem(
                          label: 'BRZYCKI',
                          repRange: '5-10 reps',
                          value:
                              '${(widget.exercise as StrengthExercise).oneRepMaxBrzycki.toStringAsFixed(1)} kg',
                        ),
                        _OneRepMaxItem(
                          label: 'EPLEY',
                          repRange: '1-10 reps',
                          value:
                              '${(widget.exercise as StrengthExercise).oneRepMaxEpley.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}

class _PersonalRecordItem extends StatelessWidget {
  const _PersonalRecordItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _OneRepMaxItem extends StatelessWidget {
  const _OneRepMaxItem({
    required this.label,
    required this.repRange,
    required this.value,
  });

  final String label;
  final String repRange;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          repRange,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
