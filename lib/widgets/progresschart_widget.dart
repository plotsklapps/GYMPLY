import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gymply/modals/monthstat_modal.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:intl/intl.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart({
    required this.workouts,
    required this.exerciseName,
    required this.selectedMetric,
    super.key,
  });

  final List<Workout> workouts;
  final String exerciseName;
  final WorkoutMetric selectedMetric;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (workouts.isEmpty) return const SizedBox.shrink();

    // Extract data points for this specific exercise.
    final List<_DataPoint> points = workouts.map((Workout w) {
      final WorkoutExercise? ex = w.exercises.where((WorkoutExercise e) {
        return e.exerciseName == exerciseName;
      }).firstOrNull;

      return _DataPoint(
        date: w.dateTime,
        value: ex != null ? _getExerciseMetricValue(ex) : 0,
      );
    }).toList();

    final double maxValue = points
        .map((_DataPoint p) {
          return p.value;
        })
        .fold(0, max);
    final DateTime minDate = points.first.date;
    final DateTime maxDate = points.last.date;
    final int totalDurationMs = maxDate.difference(minDate).inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            selectedMetric.name.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Chart Container.
        Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: <Widget>[
                  // Horizontal Grid Lines (Base).
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),

                  // Data Points (Bars).
                  ...points.map((_DataPoint p) {
                    // Calculate horizontal position relative to time span.
                    final double xRatio = totalDurationMs == 0
                        ? 0.5 // Center if only one point exists.
                        : p.date.difference(minDate).inMilliseconds /
                              totalDurationMs;

                    final double heightFactor = maxValue == 0
                        ? 0.1
                        : (p.value / maxValue).clamp(0.05, 1.0);

                    return Positioned(
                      left: xRatio * (constraints.maxWidth - 4),
                      bottom: 0,
                      child: Tooltip(
                        message:
                            '${DateFormat.yMMMd().format(p.date)}: '
                            '${p.value.toStringAsFixed(1)}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 4,
                          height: heightFactor * constraints.maxHeight,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),

        // Timeline Labels.
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              DateFormat.yMMMd().format(minDate),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              DateFormat.yMMMd().format(maxDate),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Calculate the metric specifically for ONE exercise instance.
  double _getExerciseMetricValue(WorkoutExercise ex) {
    switch (selectedMetric) {
      case WorkoutMetric.volume:
        return ex is StrengthExercise ? ex.totalWeight : 0;
      case WorkoutMetric.reps:
        return ex is StrengthExercise ? ex.totalReps.toDouble() : 0;
      case WorkoutMetric.sets:
        return ex.totalSets.toDouble();
      case WorkoutMetric.time:
        if (ex is CardioExercise) return ex.totalDuration.inMinutes.toDouble();
        if (ex is StretchExercise) return ex.totalDuration.inMinutes.toDouble();
        return 0;
      case WorkoutMetric.distance:
        return ex is CardioExercise ? ex.totalDistance : 0;
      case WorkoutMetric.calories:
        return ex is CardioExercise ? ex.totalCalories.toDouble() : 0;
    }
  }
}

class _DataPoint {
  _DataPoint({required this.date, required this.value});
  final DateTime date;
  final double value;
}
