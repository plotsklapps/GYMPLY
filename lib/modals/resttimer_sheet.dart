import 'package:flutter/material.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class RestTimerSheet extends StatelessWidget {
  const RestTimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final int initialSeconds = RestTimer.sInitialRestTime.watch(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SET INTERVAL TIMER',
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
        // M:S Picker.
        RestDurationPicker(
          initialSeconds: initialSeconds,
          onChanged: (int newSeconds) {
            // Update the initial duration.
            RestTimer.sInitialRestTime.value = newSeconds;

            // Sync the elapsed duration if the timer is not currently running.
            // This is handled manually to keep the service logic simple.
            if (!RestTimer.sRestTimerRunning.value) {
              RestTimer.sElapsedRestTime.value = newSeconds;
            }
          },
        ),
        const SizedBox(height: 24),
        // Cancel/Confirm Buttons.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Reset to default.
                  RestTimer.sInitialRestTime.value = 60;
                  RestTimer.sElapsedRestTime.value = 60;

                  // Pop and return false.
                  Navigator.pop(context, false);
                },
                child: const Text('DEFAULT'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  // Pop and return true.
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

class RestDurationPicker extends StatefulWidget {
  const RestDurationPicker({
    required this.initialSeconds,
    required this.onChanged,
    super.key,
  });

  final int initialSeconds;
  final ValueChanged<int> onChanged;

  @override
  State<RestDurationPicker> createState() {
    return _RestDurationPickerState();
  }
}

class _RestDurationPickerState extends State<RestDurationPicker> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    final Duration duration = Duration(seconds: widget.initialSeconds);
    _minutes = duration.inMinutes % 60;
    _seconds = duration.inSeconds % 60;
  }

  void _updateDuration() {
    final int totalSeconds = (_minutes * 60) + _seconds;
    widget.onChanged(totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      height: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _ScrollColumn(
            label: 'MIN',
            max: 59,
            value: _minutes,
            onChanged: (int val) {
              setState(() {
                _minutes = val;
              });
              _updateDuration();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(50),
              ),
            ),
          ),
          _ScrollColumn(
            label: 'SEC',
            max: 59,
            value: _seconds,
            onChanged: (int val) {
              setState(() {
                _seconds = val;
              });
              _updateDuration();
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
  });

  final String label;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;

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
            width: 100,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 80,
              perspective: 0.005,
              diameterRatio: 1.2,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(initialItem: value),
              onSelectedItemChanged: onChanged,
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (BuildContext context, int index) {
                  if (index < 0 || index > max) return null;
                  final bool isSelected = index == value;
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: theme.textTheme.displayLarge?.copyWith(
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
