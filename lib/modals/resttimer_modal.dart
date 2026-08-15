import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

class RestTimerModal extends SignalWidget {
  const RestTimerModal({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final int initialSeconds = RestTimer.sInitialRestTime.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SET REST TIMER',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: const Icon(IconUtils.close),
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
                RestDurationPicker(
                  initialSeconds: initialSeconds,
                  onChanged: (int newSeconds) {
                    // Update the initial duration.
                    RestTimer.sInitialRestTime.value = newSeconds;

                    // Sync the elapsed duration if the timer is not currently
                    // running. This is handled manually to keep the service
                    // logic simple.
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
            ),
          ),
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
    final int rawSeconds = duration.inSeconds % 60;
    _seconds = ((rawSeconds / 5).round() * 5).clamp(0, 55);
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
            max: 55,
            step: 5,
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
    this.step = 1,
  });

  final String label;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final int step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int count = (max ~/ step) + 1;
    final int selectedIndex = (value / step).round().clamp(0, count - 1);

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
              controller: FixedExtentScrollController(
                initialItem: selectedIndex,
              ),
              onSelectedItemChanged: (int index) {
                onChanged(index * step);
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (BuildContext context, int index) {
                  if (index < 0 || index >= count) return null;
                  final int displayValue = index * step;
                  final bool isSelected = displayValue == value;
                  return Center(
                    child: Text(
                      displayValue.toString().padLeft(2, '0'),
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
                childCount: count,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
