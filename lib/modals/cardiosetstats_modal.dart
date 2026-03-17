import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CardioSetStatsModal extends StatefulWidget {
  const CardioSetStatsModal({
    required this.initialDistance,
    required this.initialIntensity,
    required this.onConfirm,
    super.key,
  });

  final double initialDistance;
  final int initialIntensity;
  final void Function(double distance, int intensity) onConfirm;

  @override
  State<CardioSetStatsModal> createState() => _CardioSetStatsModalState();
}

class _CardioSetStatsModalState extends State<CardioSetStatsModal> {
  late double _currentDistance;
  late int _currentIntensity;

  @override
  void initState() {
    super.initState();
    _currentDistance = widget.initialDistance;
    _currentIntensity = widget.initialIntensity;
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
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                  ],
                ),
              ),
              ButtonSegment<int>(
                value: 2,
                label: const Text('Hard'),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
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
        // Distance Picker underneath
        DistancePicker(
          initialDistance: _currentDistance,
          onChanged: (double val) {
            _currentDistance = val;
          },
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
                  widget.onConfirm(_currentDistance, _currentIntensity);
                  Navigator.pop(context, true);
                },
                child: const Text('CONFIRM'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DistancePicker extends StatefulWidget {
  const DistancePicker({
    required this.initialDistance,
    required this.onChanged,
    super.key,
  });

  final double initialDistance;
  final ValueChanged<double> onChanged;

  @override
  State<DistancePicker> createState() => _DistancePickerState();
}

class _DistancePickerState extends State<DistancePicker> {
  late int _km;
  late int _m; // This will store the index (0-19) for the 50m steps

  @override
  void initState() {
    super.initState();
    _km = widget.initialDistance.floor();
    // Calculate the index for 50m steps (0 to 19)
    final double metersPart = (widget.initialDistance - _km) * 1000;
    _m = (metersPart / 50.0).round().clamp(0, 19);
  }

  void _updateDistance() {
    final double totalDistance = _km + ((_m * 50) / 1000.0);
    widget.onChanged(totalDistance);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 200, // Reduced height for combined modal
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '.',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(50),
              ),
            ),
          ),
          _ScrollColumn(
            label: 'M',
            max: 19, // 20 steps of 50m (0, 50, ..., 950)
            value: _m,
            step: 50,
            padLeft: 3,
            onChanged: (int val) {
              setState(() => _m = val);
              _updateDistance();
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
            width: 80, // Slightly narrower
            child: ListWheelScrollView.useDelegate(
              itemExtent: 60, // Slightly shorter
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
