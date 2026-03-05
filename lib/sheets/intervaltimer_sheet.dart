import 'package:flutter/material.dart';
import 'package:gymply/services/intervaltimer_service.dart';
import 'package:signals/signals_flutter.dart';

class IntervalTimerSheet extends StatelessWidget {
  const IntervalTimerSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final int initialMs = IntervalTimer.sInitialIntervalTime.watch(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'SET INTERVAL DURATION',
          style: theme.textTheme.titleLarge,
        ),
        const Divider(),
        const SizedBox(height: 20),
        // H:M:S Picker.
        _HMSDurationPicker(
          initialMs: initialMs,
          onChanged: (int newMs) {
            // Update the initial duration.
            IntervalTimer.sInitialIntervalTime.value = newMs;

            // Sync the elapsed duration if the timer is not currently running.
            // This is handled manually to keep the service logic simple.
            if (!IntervalTimer.sIntervalTimerRunning.value) {
              IntervalTimer.sElapsedIntervalTime.value = newMs;
            }
          },
        ),
        const SizedBox(height: 20),
        // Cancel/Confirm Buttons.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Reset to default (1 minute).
                  IntervalTimer.sInitialIntervalTime.value = 60000;
                  IntervalTimer.sElapsedIntervalTime.value = 60000;
                  Navigator.pop(context);
                },
                child: const Text('DEFAULT'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
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

class _HMSDurationPicker extends StatefulWidget {
  const _HMSDurationPicker({
    required this.initialMs,
    required this.onChanged,
  });

  final int initialMs;
  final ValueChanged<int> onChanged;

  @override
  State<_HMSDurationPicker> createState() => _HMSDurationPickerState();
}

class _HMSDurationPickerState extends State<_HMSDurationPicker> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    final Duration duration = Duration(milliseconds: widget.initialMs);
    _hours = duration.inHours;
    _minutes = duration.inMinutes % 60;
    _seconds = duration.inSeconds % 60;
  }

  void _updateDuration() {
    final int totalMs = ((_hours * 3600) + (_minutes * 60) + _seconds) * 1000;
    widget.onChanged(totalMs);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _ScrollColumn(
            label: 'HRS',
            max: 23,
            value: _hours,
            onChanged: (int val) {
              setState(() => _hours = val);
              _updateDuration();
            },
          ),
          _Separator(),
          _ScrollColumn(
            label: 'MIN',
            max: 59,
            value: _minutes,
            onChanged: (int val) {
              setState(() => _minutes = val);
              _updateDuration();
            },
          ),
          _Separator(),
          _ScrollColumn(
            label: 'SEC',
            max: 59,
            value: _seconds,
            onChanged: (int val) {
              setState(() => _seconds = val);
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
        Text(label, style: theme.textTheme.labelSmall),
        Expanded(
          child: SizedBox(
            width: 50,
            child: ListWheelScrollView.useDelegate(
              itemExtent: 40,
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
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
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

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(50),
        ),
      ),
    );
  }
}
