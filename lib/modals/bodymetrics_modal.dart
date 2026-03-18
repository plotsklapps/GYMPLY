import 'package:flutter/material.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BodyMetricsModal extends StatefulWidget {
  const BodyMetricsModal({super.key});

  @override
  State<BodyMetricsModal> createState() {
    return _BodyMetricsModalState();
  }
}

class _BodyMetricsModalState extends State<BodyMetricsModal> {
  // Local state to keep track of values before saving.
  late int _age;
  late double _height;
  late double _weight;
  // 0 male, 1 female.
  late int _sex;

  @override
  void initState() {
    super.initState();
    // Initialize from signals.
    _age = sAge.value == 0 ? 25 : sAge.value;
    _height = sHeight.value == 0 ? 170 : sHeight.value;
    _weight = sWeight.value == 0 ? 70 : sWeight.value;
    _sex = sSex.value;
  }

  void _saveBodyMetrics() {
    sAge.value = _age;
    sHeight.value = _height;
    sWeight.value = _weight;
    sSex.value = _sex;

    // Show toast to user.
    ToastService.showSuccess(
      title: 'Body Metrics Saved',
      subtitle: 'Calculations are now done with new values',
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
        const SizedBox(height: 16),
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
