import 'package:gymply/modals/monthlysummary_modal.dart';
import 'package:gymply/modals/workoutsummary_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/signals/workouthistory_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:gymply/widgets/metricselector_widget.dart';
import 'package:gymply/widgets/monthchart_widget.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

enum WorkoutMetric { volume, reps, sets, time, distance, calories }

class MonthStatModal extends SignalStatefulWidget {
  const MonthStatModal({required this.date, super.key});

  final DateTime date;

  @override
  State<MonthStatModal> createState() {
    return _MonthStatModalState();
  }
}

class _MonthStatModalState extends State<MonthStatModal> {
  late DateTime _currentDate;
  // Default to Volume.
  WorkoutMetric _selectedMetric = WorkoutMetric.volume;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals to ensure the modal rebuilds on deletion or changes.
    final List<Workout> history = sWorkoutHistory.value;
    final Workout active = sActiveWorkout.value;

    // Collect only years containing recorded workouts + current year.
    final Set<int> availableYears =
        history.map((Workout w) => w.dateTime.year).toSet()
          ..add(DateTime.now().year)
          ..add(_currentDate.year);
    final List<int> sortedYears = availableYears.toList()
      ..sort((int a, int b) => b.compareTo(a));

    // Calculate workout keys dynamically.
    final Set<String> workoutDateKeys = history.map((Workout w) {
      return w.dateKey;
    }).toSet();

    // Add active workout to keys ONLY if it is a live session (NOT routine).
    if (active.exercises.isNotEmpty && !active.isRoutine) {
      workoutDateKeys.add(active.dateKey);
    }

    final String monthNameOnly = DateFormat(
      'MMMM',
    ).format(_currentDate).toUpperCase();

    // Calculate days in the month.
    final int daysInMonth = DateTime(
      _currentDate.year,
      _currentDate.month + 1,
      0,
    ).day;

    // Monday-start offset (0-6).
    final int firstDayWeekday = DateTime(
      _currentDate.year,
      _currentDate.month,
    ).weekday;
    final int startOffset = firstDayWeekday - 1;

    final List<String> weekdays = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Filter workouts for this month.
    final List<Workout> monthWorkouts = history.where((Workout w) {
      return w.dateTime.year == _currentDate.year &&
          w.dateTime.month == _currentDate.month;
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('$monthNameOnly ', style: theme.textTheme.titleLarge),
                  if (sortedYears.length > 1)
                    PopupMenuButton<int>(
                      initialValue: _currentDate.year,
                      onSelected: (int year) {
                        setState(() {
                          _currentDate = DateTime(year, _currentDate.month);
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${_currentDate.year}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            IconUtils.chevronDown,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                      itemBuilder: (BuildContext context) {
                        return sortedYears.map((int year) {
                          return PopupMenuItem<int>(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: year == _currentDate.year
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    )
                  else
                    Text(
                      '${_currentDate.year}',
                      style: theme.textTheme.titleLarge,
                    ),
                ],
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
                // Weekday Header.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdays.map((String day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                // Calendar.
                GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: startOffset + daysInMonth,
                  itemBuilder: (BuildContext context, int index) {
                    // Empty space before first day.
                    if (index < startOffset) {
                      return const SizedBox.shrink();
                    }

                    final int day = index - startOffset + 1;
                    final DateTime currentDay = DateTime(
                      _currentDate.year,
                      _currentDate.month,
                      day,
                    );
                    final String key = DateFormat(
                      'yyyyMMdd',
                    ).format(currentDay);
                    final bool hasWorkout = workoutDateKeys.contains(key);
                    final bool isToday =
                        DateFormat('yyyyMMdd').format(DateTime.now()) == key;

                    return InkWell(
                      onTap: hasWorkout
                          ? () async {
                              // Find workout in history or active workout.
                              final Workout? historical = history.where((
                                Workout w,
                              ) {
                                return w.dateKey == key;
                              }).firstOrNull;

                              final Workout? activeIfMatch =
                                  (active.dateKey == key &&
                                      active.exercises.isNotEmpty)
                                  ? active
                                  : null;

                              final Workout? workoutToShow =
                                  historical ?? activeIfMatch;

                              if (workoutToShow != null && context.mounted) {
                                await ModalService.showModal(
                                  context: context,
                                  child: WorkoutSummaryModal(
                                    workout: workoutToShow,
                                  ),
                                );
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasWorkout
                                ? theme.colorScheme.secondary
                                : isToday
                                ? theme.colorScheme.surfaceContainerHighest
                                : null,
                            border: isToday
                                ? Border.all(color: theme.colorScheme.secondary)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: hasWorkout || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: hasWorkout
                                    ? theme.colorScheme.onSecondary
                                    : isToday
                                    ? theme.colorScheme.secondary
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                MonthChart(
                  workouts: monthWorkouts,
                  daysInMonth: daysInMonth,
                  selectedMetric: _selectedMetric,
                ),
                const SizedBox(height: 16),
                MetricSelector(
                  selectedMetric: _selectedMetric,
                  onSelected: (WorkoutMetric metric) {
                    setState(() {
                      _selectedMetric = metric;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Monthly Summary Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ModalService.showModal(
                        context: context,
                        child: MonthlySummaryModal(date: _currentDate),
                      );
                    },
                    icon: const Icon(IconUtils.statistics),
                    label: const Text('MONTHLY SUMMARY'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
