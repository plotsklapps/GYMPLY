import 'package:gymply/modals/copyworkout_modal.dart';
import 'package:gymply/modals/saveplannedworkout_modal.dart';
import 'package:gymply/modals/searchmodal/search_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/signals/workouthistory_signal.dart';
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
  late DateTime _viewDate;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    _viewDate = DateTime(_selectedDate.year, _selectedDate.month);
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
    final DateTime currentMonthStart = DateTime(now.year, now.month);

    // Calendar Calculations
    final int daysInMonth = DateTime(
      _viewDate.year,
      _viewDate.month + 1,
      0,
    ).day;
    final int firstDayWeekday = DateTime(
      _viewDate.year,
      _viewDate.month,
    ).weekday;
    final int startOffset = firstDayWeekday - 1;

    final List<String> weekdays = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final bool isCanGoBack = _viewDate.isAfter(currentMonthStart);

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
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: <Widget>[
                  // Month Selector Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      IconButton(
                        onPressed: isCanGoBack
                            ? () {
                                setState(() {
                                  _viewDate = DateTime(
                                    _viewDate.year,
                                    _viewDate.month - 1,
                                  );
                                });
                              }
                            : null,
                        icon: Icon(
                          IconUtils.chevronLeft,
                          color: isCanGoBack
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_viewDate).toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _viewDate = DateTime(
                              _viewDate.year,
                              _viewDate.month + 1,
                            );
                          });
                        },
                        icon: const Icon(IconUtils.chevronRight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Weekday Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      for (final String day in weekdays)
                        Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: startOffset + daysInMonth,
                    itemBuilder: (BuildContext context, int index) {
                      if (index < startOffset) {
                        return const SizedBox.shrink();
                      }

                      final int day = index - startOffset + 1;
                      final DateTime currentDay = DateTime(
                        _viewDate.year,
                        _viewDate.month,
                        day,
                      );
                      final String dateKey = currentDay.yyyyMMdd;

                      final bool isPast = currentDay.isBefore(todayStart);
                      final bool isSelected =
                          currentDay.year == _selectedDate.year &&
                          currentDay.month == _selectedDate.month &&
                          currentDay.day == _selectedDate.day;
                      final bool hasPlannedWorkout = plannedDateKeys.contains(
                        dateKey,
                      );
                      final bool isToday =
                          currentDay.year == todayStart.year &&
                          currentDay.month == todayStart.month &&
                          currentDay.day == todayStart.day;

                      return InkWell(
                        onTap: isPast
                            ? null
                            : () {
                                setState(() {
                                  _selectedDate = currentDay;
                                });
                              },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? theme.colorScheme.secondary
                                : hasPlannedWorkout
                                ? theme.colorScheme.surfaceContainerHigh
                                : isToday
                                ? theme.colorScheme.surfaceContainerHighest
                                : null,
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.secondary,
                                    width: 2,
                                  )
                                : hasPlannedWorkout
                                ? Border.all(
                                    color: theme.colorScheme.secondary,
                                    width: 2,
                                  )
                                : isToday
                                ? Border.all(color: theme.colorScheme.outline)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight:
                                    isSelected || hasPlannedWorkout || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isPast
                                    ? theme.colorScheme.outlineVariant
                                    : isSelected
                                    ? theme.colorScheme.onSecondary
                                    : hasPlannedWorkout
                                    ? theme.colorScheme.secondary
                                    : isToday
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Calendar Key Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.secondary,
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Planned Workout',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Selected Date',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Selected Date Info Badge
                  Card(
                    color: theme.colorScheme.surfaceContainerLow,
                    child: ListTile(
                      onTap: plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                          ? () async {
                              final String targetKey = _selectedDate.yyyyMMdd;
                              final Workout? existingPlanned = plannedWorkouts
                                  .where((Workout w) => w.dateKey == targetKey)
                                  .firstOrNull;
                              if (existingPlanned != null) {
                                sActiveWorkout.value = existingPlanned;
                                Navigator.pop(context);
                                await ModalService.showModal(
                                  context: context,
                                  child: const SavePlannedWorkoutModal(),
                                );
                              }
                            }
                          : null,
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
                            ? 'Has a scheduled workout • Tap for options'
                            : 'No workout scheduled yet',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      trailing: plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                          ? Icon(
                              IconUtils.chevronRight,
                              color: theme.colorScheme.secondary,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final String targetKey = _selectedDate.yyyyMMdd;
                        final Workout? existingPlanned = plannedWorkouts
                            .where((Workout w) => w.dateKey == targetKey)
                            .firstOrNull;

                        Navigator.pop(context);

                        if (existingPlanned != null) {
                          // Directly edit workout on WorkoutScreen!
                          sActiveWorkout.value = existingPlanned;
                          navigateToTab(AppTab.workout);
                        } else {
                          // Create new planned workout session and open exercise search.
                          sActiveWorkout.value = Workout(
                            id: const Uuid().v4(),
                            title: _selectedDate.defaultWorkoutTitle,
                            dateTime: _selectedDate,
                            totalDuration: 0,
                            isPlanned: true,
                          );

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
                        }
                      },
                      icon: Icon(
                        plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                            ? IconUtils.edit
                            : IconUtils.add,
                      ),
                      label: Text(
                        plannedDateKeys.contains(_selectedDate.yyyyMMdd)
                            ? 'EDIT SCHEDULED WORKOUT'
                            : 'ADD EXERCISES FOR THIS DATE',
                      ),
                    ),
                  ),

                  // Recent Workouts to Copy Section
                  if (sWorkoutHistory.value.isNotEmpty &&
                      !plannedDateKeys.contains(
                        _selectedDate.yyyyMMdd,
                      )) ...<Widget>[
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR COPY A RECENT WORKOUT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...sWorkoutHistory.value.reversed.take(6).map((Workout w) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () async {
                            final bool? copied = await ModalService.showModal(
                              context: context,
                              child: CopyWorkoutModal(
                                workout: w,
                                initialTargetDate: _selectedDate,
                              ),
                            );
                            if (copied == true && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHigh,
                            child: Icon(
                              IconUtils.dumbbell,
                              size: 20,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          title: Text(
                            w.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${w.formattedDate} • ${w.exercises.length} exercises',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          trailing: Icon(
                            IconUtils.chevronRight,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
