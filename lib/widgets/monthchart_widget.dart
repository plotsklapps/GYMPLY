import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gymply/modals/monthstat_modal.dart';
import 'package:gymply/models/workout_model.dart';

class MonthChart extends StatelessWidget {
  const MonthChart({
    required this.workouts,
    required this.daysInMonth,
    required this.selectedMetric,
    super.key,
  });

  final List<Workout> workouts;
  final int daysInMonth;
  final WorkoutMetric selectedMetric;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Map day to workout value.
    final Map<int, double> data = <int, double>{};
    double maxValue = 0;

    for (final Workout w in workouts) {
      final double value = _getMetricValue(w);
      data[w.dateTime.day] = value;
      maxValue = max(maxValue, value);
    }

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
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(daysInMonth, (int index) {
              final int day = index + 1;
              final double value = data[day] ?? 0;
              final double heightFactor = maxValue == 0 ? 0 : value / maxValue;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: FractionallySizedBox(
                          heightFactor: max(heightFactor, 0.05),
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: value > 0
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.outlineVariant.withAlpha(
                                      80,
                                    ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  double _getMetricValue(Workout workout) {
    switch (selectedMetric) {
      case WorkoutMetric.volume:
        return workout.totalStrengthVolume;
      case WorkoutMetric.reps:
        return workout.totalReps.toDouble();
      case WorkoutMetric.sets:
        return workout.totalSets.toDouble();
      case WorkoutMetric.time:
        return workout.totalDuration.toDouble();
      case WorkoutMetric.distance:
        return workout.totalCardioDistance;
      case WorkoutMetric.calories:
        return workout.totalCardioCalories.toDouble();
    }
  }
}
