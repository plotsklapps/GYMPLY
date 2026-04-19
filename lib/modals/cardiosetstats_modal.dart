import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CardioSetStatsModal extends StatefulWidget {
  const CardioSetStatsModal({
    required this.initialDistance,
    required this.initialIntensity,
    required this.initialReps,
    required this.onConfirm,
    super.key,
  });

  final double initialDistance;
  final int initialIntensity;
  final int initialReps;
  final void Function(double distance, int intensity, int reps) onConfirm;

  @override
  State<CardioSetStatsModal> createState() => _CardioSetStatsModalState();
}

class _CardioSetStatsModalState extends State<CardioSetStatsModal> {
  late double _currentDistance;
  late int _currentIntensity;
  late int _currentReps;

  @override
  void initState() {
    super.initState();
    _currentDistance = widget.initialDistance;
    _currentIntensity = widget.initialIntensity;
    _currentReps = widget.initialReps;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SET STATS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),
                // Intensity SegmentedButton on top
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: <ButtonSegment<int>>[
                      ButtonSegment<int>(
                        value: 0,
                        label: const Text('Light'),
                        icon: Icon(
                          LucideIcons.flame,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: const Text('Medium'),
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              LucideIcons.flame,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            Icon(
                              LucideIcons.flame,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: const Text('Hard'),
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              LucideIcons.flame,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            Icon(
                              LucideIcons.flame,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            Icon(
                              LucideIcons.flame,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                    selected: <int>{_currentIntensity},
                    onSelectionChanged: (Set<int> newSelection) {
                      setState(() => _currentIntensity = newSelection.first);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Combined Picker underneath
                MetricPicker(
                  initialDistance: _currentDistance,
                  initialReps: _currentReps,
                  onDistanceChanged: (double val) => _currentDistance = val,
                  onRepsChanged: (int val) => _currentReps = val,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () {
                          widget.onConfirm(
                            _currentDistance,
                            _currentIntensity,
                            _currentReps,
                          );
                          Navigator.pop(context, true);
                        },
                        child: const Text('CONFIRM'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MetricPicker extends StatefulWidget {
  const MetricPicker({
    required this.initialDistance,
    required this.initialReps,
    required this.onDistanceChanged,
    required this.onRepsChanged,
    super.key,
  });

  final double initialDistance;
  final int initialReps;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<int> onRepsChanged;

  @override
  State<MetricPicker> createState() => _MetricPickerState();
}

class _MetricPickerState extends State<MetricPicker> {
  late int _km;
  late int _m;
  late int _reps;

  @override
  void initState() {
    super.initState();
    _km = widget.initialDistance.floor();
    final double metersPart = (widget.initialDistance - _km) * 1000;
    _m = (metersPart / 50.0).round().clamp(0, 19);
    _reps = widget.initialReps;
  }

  void _updateDistance() {
    final double totalDistance = _km + ((_m * 50) / 1000.0);
    widget.onDistanceChanged(totalDistance);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _ScrollColumn(
            label: 'KM',
            max: 50,
            value: _km,
            onChanged: (int val) {
              setState(() => _km = val);
              _updateDistance();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '.',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(50),
              ),
            ),
          ),
          _ScrollColumn(
            label: 'M',
            max: 19,
            value: _m,
            step: 50,
            padLeft: 3,
            onChanged: (int val) {
              setState(() => _m = val);
              _updateDistance();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '|',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(50),
              ),
            ),
          ),
          _ScrollColumn(
            label: 'REPS',
            max: 99,
            value: _reps,
            onChanged: (int val) {
              setState(() => _reps = val);
              widget.onRepsChanged(val);
            },
          ),
        ],
      ),
    );
  }
}

class _ScrollColumn extends StatelessWidget {
  const _ScrollColumn({
    required this.label,
    required this.max,
    required this.value,
    required this.onChanged,
    this.padLeft = 2,
    this.step = 1,
  });

  final String label;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final int padLeft;
  final int step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        Expanded(
          child: SizedBox(
            width: 70,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60,
              perspective: 0.005,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(initialItem: value),
              onSelectedItemChanged: onChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (BuildContext context, int index) {
                  if (index < 0 || index > max) return null;
                  final bool isSelected = index == value;
                  final int displayValue = index * step;
                  return Center(
                    child: Text(
                      displayValue.toString().padLeft(padLeft, '0'),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary.withAlpha(200)
                            : theme.colorScheme.onSurface.withAlpha(50),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
                childCount: max + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
