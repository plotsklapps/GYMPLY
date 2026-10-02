import 'package:gymply/modals/searchmodal/search_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class SelectPlannedDateModal extends SignalStatefulWidget {
  const SelectPlannedDateModal({super.key});

  @override
  State<SelectPlannedDateModal> createState() {
    return _SelectPlannedDateModalState();
  }
}

class _SelectPlannedDateModalState extends State<SelectPlannedDateModal> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Default to tomorrow (or today if late evening).
    _selectedDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Workout> plannedWorkouts = sPlannedWorkouts.value;

    final Set<String> plannedDateKeys = plannedWorkouts.map((Workout w) {
      return w.dateKey;
    }).toSet();

    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Header
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    'PLAN A WORKOUT',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'SELECT FUTURE DATE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(IconUtils.close),
            ),
          ],
        ),
        const Divider(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: <Widget>[
              // Calendar Date Picker
              CalendarDatePicker(
                initialDate: _selectedDate.isBefore(todayStart)
                    ? todayStart
                    : _selectedDate,
                firstDate: todayStart,
                lastDate: todayStart.add(const Duration(days: 365)),
                onDateChanged: (DateTime date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Selected Date Badge
              Card(
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  leading: Icon(
                    IconUtils.calendarMonth,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                        ? 'Has a scheduled workout'
                        : 'No workout scheduled yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    // Close date picker modal.
                    Navigator.pop(context);

                    // Check if there is already a planned workout for this date.
                    final String targetKey = _selectedDate.yyyyMMdd;
                    final Workout? existingPlanned = plannedWorkouts
                        .where((Workout w) => w.dateKey == targetKey)
                        .firstOrNull;

                    if (existingPlanned != null) {
                      sActiveWorkout.value = existingPlanned;
                    } else {
                      // Create a new planned workout container for target date.
                      sActiveWorkout.value = Workout(
                        id: const Uuid().v4(),
                        title: _selectedDate.defaultWorkoutTitle,
                        dateTime: _selectedDate,
                        totalDuration: 0,
                        isPlanned: true,
                      );
                    }

                    // Open SearchModal to add exercises.
                    if (context.mounted) {
                      await showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (BuildContext context) {
                          return const SearchModal();
                        },
                      );
                    }
                  },
                  icon: const Icon(IconUtils.add),
                  label: const Text('ADD EXERCISES FOR THIS DATE'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
