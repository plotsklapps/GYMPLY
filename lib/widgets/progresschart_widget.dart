import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gymply/modals/monthstat_modal.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum WorkoutRange { days30, months6, year1, allTime }

class ProgressChart extends StatefulWidget {
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
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  WorkoutRange _selectedRange = WorkoutRange.days30;

  List<Workout> _getFilteredWorkouts() {
    final DateTime now = DateTime.now();
    final List<Workout> sorted = List<Workout>.from(widget.workouts)
      ..sort((Workout a, Workout b) => a.dateTime.compareTo(b.dateTime));

    switch (_selectedRange) {
      case WorkoutRange.days30:
        return sorted.length > 30 ? sorted.sublist(sorted.length - 30) : sorted;
      case WorkoutRange.months6:
        return sorted
            .where(
              (Workout w) =>
                  w.dateTime.isAfter(now.subtract(const Duration(days: 180))),
            )
            .toList();
      case WorkoutRange.year1:
        return sorted
            .where(
              (Workout w) =>
                  w.dateTime.isAfter(now.subtract(const Duration(days: 365))),
            )
            .toList();
      case WorkoutRange.allTime:
        return sorted;
    }
  }

  String _getRangeLabel(WorkoutRange range) {
    switch (range) {
      case WorkoutRange.days30:
        return '30 Days';
      case WorkoutRange.months6:
        return '6 Months';
      case WorkoutRange.year1:
        return '1 Year';
      case WorkoutRange.allTime:
        return 'All Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Workout> filtered = _getFilteredWorkouts();

    if (filtered.isEmpty) return const SizedBox.shrink();

    final List<double> values = filtered.map((Workout w) {
      final WorkoutExercise? ex = w.exercises
          .where((WorkoutExercise e) => e.exerciseName == widget.exerciseName)
          .firstOrNull;
      return (ex != null ? _getExerciseMetricValue(ex) : 0).toDouble();
    }).toList();

    final double maxValue = values.fold(0.0, max);
    final double minValue = values.fold(double.infinity, min);

    return Column(
      children: <Widget>[
        // Range Selector.
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRange =
                      WorkoutRange.values[(_selectedRange.index + 1) %
                          WorkoutRange.values.length];
                });
              },
              icon: const Icon(LucideIcons.calendarDays, size: 18),
              label: Text(_getRangeLabel(_selectedRange)),
            ),
          ],
        ),

        // Chart with Y-Axis.
        SizedBox(
          height: 150,
          child: Row(
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    maxValue.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    minValue.toStringAsFixed(0),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selectedRange == WorkoutRange.days30
                    ? _ChartBars(
                        values: values,
                        maxValue: maxValue,
                        color: theme.colorScheme.secondary,
                      )
                    : _ChartLine(
                        values: values,
                        color: theme.colorScheme.secondary,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _getExerciseMetricValue(WorkoutExercise ex) {
    switch (widget.selectedMetric) {
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

class _ChartBars extends StatelessWidget {
  const _ChartBars({
    required this.values,
    required this.maxValue,
    required this.color,
  });
  final List<double> values;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(30, (int index) {
        final int dataIndex = index - (30 - values.length);
        if (dataIndex < 0 || dataIndex >= values.length) {
          return const Expanded(child: SizedBox());
        }

        // Skip zero values to avoid showing empty bars for non-existent workouts
        if (values[dataIndex] == 0) {
          return const Expanded(child: SizedBox());
        }

        final double height = maxValue == 0
            ? 0
            : (values[dataIndex] / maxValue);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: (height * 0.9).clamp(0.05, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ChartLine extends StatelessWidget {
  const _ChartLine({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _LinePainter(values, color),
        );
      },
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final Path path = Path();
    final double step = size.width / (values.length - 1);
    final double maxVal = values.fold(0.0, max);

    for (int i = 0; i < values.length; i++) {
      final double x = i * step;
      final double y = size.height - ((values[i] / maxVal) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
