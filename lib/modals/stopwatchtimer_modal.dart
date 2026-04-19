import 'package:flutter/material.dart';
import 'package:gymply/services/stopwatchtimer_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StopwatchTimerModal extends StatelessWidget {
  const StopwatchTimerModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SET DURATION',
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
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 16),
                // M:S Picker.
                StopwatchDurationPicker(
                  initialSeconds: (StopwatchTimer.sElapsedStopwatchTime.value / 1000)
                      .round(),
                  onChanged: (int newSeconds) {
                    // Update the temporary value for display/confirmation.
                    _tempSeconds = newSeconds;
                  },
                ),
                const SizedBox(height: 24),
                // Cancel/Confirm Buttons.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          // Reset to zero.
                          await StopwatchTimer().resetTimer();

                          // Pop and return false.
                          if (context.mounted) Navigator.pop(context, false);
                        },
                        child: const Text('RESET'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () {
                          // Set to confirmed value.
                          // We do NOT call resetTimer() here, because it sets
                          // sElapsedStopwatchTime to 0.
                          StopwatchTimer().setManualTime(_tempSeconds * 1000);

                          // Pop and return true.
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

// Global variable for temporary value tracking
int _tempSeconds = 0;

class StopwatchDurationPicker extends StatefulWidget {
  const StopwatchDurationPicker({
    required this.initialSeconds,
    required this.onChanged,
    super.key,
  });

  final int initialSeconds;
  final ValueChanged<int> onChanged;

  @override
  State<StopwatchDurationPicker> createState() {
    return _StopwatchDurationPickerState();
  }
}

class _StopwatchDurationPickerState extends State<StopwatchDurationPicker> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    int remaining = widget.initialSeconds;
    _hours = remaining ~/ 3600;
    remaining %= 3600;
    _minutes = remaining ~/ 60;
    _seconds = remaining % 60;
    _tempSeconds = widget.initialSeconds;
  }

  void _updateDuration() {
    final int totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
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
            label: 'HRS',
            max: 23,
            value: _hours,
            onChanged: (int val) {
              setState(() {
                _hours = val;
              });
              _updateDuration();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: theme.textTheme.headlineMedium),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(':', style: theme.textTheme.headlineMedium),
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
          style: theme.textTheme.labelMedium,
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
                            ? theme.colorScheme.secondary.withAlpha(200)
                            : theme.colorScheme.primary.withAlpha(50),
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
