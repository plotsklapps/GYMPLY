import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gymply/models/bodymetrics_model.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

// Enum for Segmentedbutton choices.
enum BodyMetricType { weight, bmi, bodyFat }

// Enum for timerange choices.
enum BodyMetricRange { days30, sixMonths, oneYear, allTime }

class BodyMetricsModal extends StatefulWidget {
  const BodyMetricsModal({super.key});

  @override
  State<BodyMetricsModal> createState() {
    return _BodyMetricsModalState();
  }
}

class _BodyMetricsModalState extends State<BodyMetricsModal> {
  // Keep track of values before saving.
  late int _age;
  late double _height;
  late double _weight;
  late int _sex;
  late int _somatotype;

  // Default metric.
  BodyMetricType _selectedType = BodyMetricType.weight;
  // Default range.
  BodyMetricRange _selectedRange = BodyMetricRange.days30;

  @override
  void initState() {
    super.initState();
    // Initialize from Signals.
    _age = sAge.value == 0 ? 25 : sAge.value;
    _height = sHeight.value == 0 ? 170 : sHeight.value;
    _weight = sWeight.value == 0 ? 70 : sWeight.value;
    _sex = sSex.value;
    _somatotype = sSomatotype.value;
  }

  Future<void> _saveBodyMetrics() async {
    await workoutService.saveBodyMetric(
      age: _age,
      height: _height,
      weight: _weight,
      sex: _sex,
      somatotype: _somatotype,
    );

    // Show toast to user.
    ToastService.showSuccess(
      title: 'Body Metrics Saved',
      subtitle: 'Calculations are now done with new values',
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _getUnit(BodyMetricType type) {
    switch (type) {
      case BodyMetricType.weight:
        return 'kg';
      case BodyMetricType.bmi:
        return '';
      case BodyMetricType.bodyFat:
        return '%';
    }
  }

  Color _getColor(ThemeData theme, BodyMetricType type) {
    switch (type) {
      case BodyMetricType.weight:
        return theme.colorScheme.secondary;
      case BodyMetricType.bmi:
        return theme.colorScheme.tertiary;
      case BodyMetricType.bodyFat:
        return theme.colorScheme.primary;
    }
  }

  String _getRangeLabel(BodyMetricRange range) {
    switch (range) {
      case BodyMetricRange.days30:
        return '30 DAYS';
      case BodyMetricRange.sixMonths:
        return '6 MONTHS';
      case BodyMetricRange.oneYear:
        return '1 YEAR';
      case BodyMetricRange.allTime:
        return 'ALL TIME';
    }
  }

  double _getValue(BodyMetric metric) {
    switch (_selectedType) {
      case BodyMetricType.weight:
        return metric.weight;
      case BodyMetricType.bmi:
        return metric.bmi;
      case BodyMetricType.bodyFat:
        return metric.bodyFat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<BodyMetric> history = sBodyMetricsHistory.watch(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // SizedBox to balance close button.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'BODY METRICS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),

        // Range Selector Toggle and Title.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: <Widget>[
                  Text(
                    _selectedType.name.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (history.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(
                      '(${_getValue(history.last).toStringAsFixed(1)}'
                      '${_getUnit(_selectedType)})',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getColor(theme, _selectedType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRange =
                      BodyMetricRange.values[(_selectedRange.index + 1) %
                          BodyMetricRange.values.length];
                });
              },
              icon: const Icon(LucideIcons.calendarDays, size: 18),
              label: Text(_getRangeLabel(_selectedRange)),
            ),
          ],
        ),

        // Body Metrics Chart.
        _BodyMetricsChart(
          history: history,
          selectedType: _selectedType,
          selectedRange: _selectedRange,
        ),
        const SizedBox(height: 8),

        // Choice Chips for Chart Selection.
        Row(
          children: <Widget>[
            Expanded(
              child: SegmentedButton<BodyMetricType>(
                segments: const <ButtonSegment<BodyMetricType>>[
                  ButtonSegment<BodyMetricType>(
                    value: BodyMetricType.weight,
                    label: Text('Weight'),
                    icon: Icon(LucideIcons.weight),
                  ),
                  ButtonSegment<BodyMetricType>(
                    value: BodyMetricType.bmi,
                    label: Text('BMI'),
                    icon: Icon(LucideIcons.activity),
                  ),
                  ButtonSegment<BodyMetricType>(
                    value: BodyMetricType.bodyFat,
                    label: Text('Fat %'),
                    icon: Icon(LucideIcons.flame),
                  ),
                ],
                selected: <BodyMetricType>{_selectedType},
                onSelectionChanged: (Set<BodyMetricType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // Sex Selection.
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(
                value: 0,
                label: Text('Male'),
                icon: Icon(LucideIcons.mars),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Female'),
                icon: Icon(LucideIcons.venus),
              ),
            ],
            selected: <int>{_sex},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _sex = newSelection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 8),

        // Somatotype Selection.
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(
                value: 0,
                label: Text('Ectomorph'),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Mesomorph'),
              ),
              ButtonSegment<int>(
                value: 2,
                label: Text('Endomorph'),
              ),
            ],
            selected: <int>{_somatotype},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _somatotype = newSelection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        // Scroll Columns for Age, Height, Weight.
        SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              // AGE Picker.
              _ScrollColumn(
                label: 'AGE',
                min: 1,
                max: 120,
                value: _age.toDouble(),
                onChanged: (double val) {
                  setState(() {
                    _age = val.toInt();
                  });
                },
                suffix: 'yrs',
              ),
              // HEIGHT Picker.
              _ScrollColumn(
                label: 'HEIGHT',
                min: 50,
                max: 250,
                value: _height,
                onChanged: (double val) {
                  setState(() {
                    _height = val;
                  });
                },
                suffix: 'cm',
              ),
              // WEIGHT Picker.
              _ScrollColumn(
                label: 'WEIGHT',
                min: 20,
                max: 300,
                value: _weight,
                onChanged: (double val) {
                  setState(() {
                    _weight = val;
                  });
                },
                suffix: 'kg',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _saveBodyMetrics,
                child: const Text('SAVE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BodyMetricsChart extends StatelessWidget {
  const _BodyMetricsChart({
    required this.history,
    required this.selectedType,
    required this.selectedRange,
  });

  final List<BodyMetric> history;
  final BodyMetricType selectedType;
  final BodyMetricRange selectedRange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Filter history based on range.
    final List<BodyMetric> displayHistory = _getFilteredHistory();

    if (displayHistory.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'No history yet',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    double maxValue = 0;
    double minValue = double.infinity;
    for (final BodyMetric m in displayHistory) {
      final double val = _getValue(m);
      if (val > maxValue) maxValue = val;
      if (val < minValue) minValue = val;
    }

    return Row(
      children: <Widget>[
        // Simple Y-Axis Labels.
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
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
        ),
        Expanded(
          child: SizedBox(
            height: 100,
            child: selectedRange == BodyMetricRange.days30
                ? _BodyMetricsBars(
                    values: displayHistory.map(_getValue).toList(),
                    maxValue: maxValue,
                    color: _getColor(theme),
                  )
                : _BodyMetricsLine(
                    values: displayHistory.map(_getValue).toList(),
                    color: _getColor(theme),
                  ),
          ),
        ),
      ],
    );
  }

  Color _getColor(ThemeData theme) {
    switch (selectedType) {
      case BodyMetricType.weight:
        return theme.colorScheme.secondary;
      case BodyMetricType.bmi:
        return theme.colorScheme.secondary.withAlpha(200);
      case BodyMetricType.bodyFat:
        return theme.colorScheme.secondary.withAlpha(150);
    }
  }

  List<BodyMetric> _getFilteredHistory() {
    final DateTime now = DateTime.now();
    switch (selectedRange) {
      case BodyMetricRange.days30:
        return history.length > 30
            ? history.sublist(history.length - 30)
            : history;
      case BodyMetricRange.sixMonths:
        return history.where(
          (BodyMetric m) {
            return m.date.isAfter(now.subtract(const Duration(days: 180)));
          },
        ).toList();
      case BodyMetricRange.oneYear:
        return history.where(
          (BodyMetric m) {
            return m.date.isAfter(now.subtract(const Duration(days: 365)));
          },
        ).toList();
      case BodyMetricRange.allTime:
        return history;
    }
  }

  double _getValue(BodyMetric metric) {
    switch (selectedType) {
      case BodyMetricType.weight:
        return metric.weight;
      case BodyMetricType.bmi:
        return metric.bmi;
      case BodyMetricType.bodyFat:
        return metric.bodyFat;
    }
  }
}

class _BodyMetricsBars extends StatelessWidget {
  const _BodyMetricsBars({
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List<Widget>.generate(30, (int index) {
        // Offset to fill from the right.
        final int dataIndex = index - (30 - values.length);

        if (dataIndex < 0) {
          return const Expanded(child: SizedBox.shrink());
        }

        final double value = values[dataIndex];
        final double heightFactor = maxValue == 0 ? 0 : value / maxValue;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: (heightFactor * 0.9).clamp(0.05, 1.0),
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

class _BodyMetricsLine extends StatelessWidget {
  const _BodyMetricsLine({
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        values: values,
        color: color,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      // If only one point, draw a dot or a short line.
      if (values.isNotEmpty) {
        final Paint paint = Paint()
          ..color = color
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
        canvas.drawPoints(
          PointMode.points,
          <Offset>[Offset(size.width / 2, size.height / 2)],
          paint,
        );
      }
      return;
    }

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    final double stepX = size.width / (values.length - 1);

    double maxValue = values[0];
    double minValue = values[0];
    for (final double v in values) {
      if (v > maxValue) maxValue = v;
      if (v < minValue) minValue = v;
    }

    final double range = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    for (int i = 0; i < values.length; i++) {
      final double x = i * stepX;
      // Normalize value to fit height, with 10% padding top/bottom.
      final double y =
          size.height -
          (((values[i] - minValue) / range) * (size.height * 0.8) +
              (size.height * 0.1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _ScrollColumn extends StatelessWidget {
  const _ScrollColumn({
    required this.label,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    required this.suffix,
  });

  final String label;
  final int min;
  final int max;
  final double value;
  final ValueChanged<double> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SizedBox(
            width: 80,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              perspective: 0.005,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: value.toInt() - min,
              ),
              onSelectedItemChanged: (int index) {
                onChanged((index + min).toDouble());
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (BuildContext context, int index) {
                  if (index < 0 || index > (max - min)) return null;
                  final int displayValue = index + min;
                  final bool isSelected = displayValue == value.toInt();
                  return Center(
                    child: Text(
                      displayValue.toString(),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.secondary.withAlpha(200)
                            : theme.colorScheme.primary.withAlpha(50),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
                childCount: max - min + 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          suffix,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
