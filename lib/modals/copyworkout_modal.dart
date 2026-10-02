import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

class CopyWorkoutModal extends StatefulWidget {
  const CopyWorkoutModal({
    required this.workout,
    this.initialTargetDate,
    super.key,
  });

  final Workout workout;
  final DateTime? initialTargetDate;

  @override
  State<CopyWorkoutModal> createState() {
    return _CopyWorkoutModalState();
  }
}

class _CopyWorkoutModalState extends State<CopyWorkoutModal> {
  late DateTime _targetDate;

  // Overwrite vs Merge.
  bool _overwrite = true;
  // Empty vs Copy Values.
  bool _emptyExercises = true;
  // Overwrite Timer vs Add.
  bool _keepCurrentTime = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _targetDate = widget.initialTargetDate ?? DateTime.now();
  }

  bool get _isToday {
    final DateTime now = DateTime.now();
    return _targetDate.year == now.year &&
        _targetDate.month == now.month &&
        _targetDate.day == now.day;
  }

  Future<void> _performCopy() async {
    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (_isToday) {
      // Copy to today's active workout session.
      workoutService.copyWorkoutToToday(
        widget.workout,
        merge: !_overwrite,
        keepValues: !_emptyExercises,
        keepCurrentTime: _keepCurrentTime,
      );

      navigateToTab(AppTab.workout);
    } else {
      // Copy / schedule to a future target date.
      final List<WorkoutExercise> exercisesToAdd = <WorkoutExercise>[];

      for (final WorkoutExercise ex in widget.workout.exercises) {
        if (!_emptyExercises) {
          exercisesToAdd.add(ex.copyWith());
        } else {
          if (ex is StrengthExercise) {
            exercisesToAdd.add(ex.copyWith(sets: <StrengthSet>[]));
          } else if (ex is CardioExercise) {
            exercisesToAdd.add(ex.copyWith(sets: <CardioSet>[]));
          } else if (ex is StretchExercise) {
            exercisesToAdd.add(ex.copyWith(sets: <StretchSet>[]));
          } else {
            exercisesToAdd.add(ex.copyWith());
          }
        }
      }

      final String targetKey = _targetDate.yyyyMMdd;
      final Workout? existingPlanned = sPlannedWorkouts.value
          .where((Workout w) => w.dateKey == targetKey)
          .firstOrNull;

      List<WorkoutExercise> finalExercises = <WorkoutExercise>[];
      if (existingPlanned != null && !_overwrite) {
        finalExercises
          ..addAll(existingPlanned.exercises)
          ..addAll(exercisesToAdd);
      } else {
        finalExercises = exercisesToAdd;
      }

      final Workout plannedToSave = Workout(
        id: existingPlanned?.id ?? const Uuid().v4(),
        title: _targetDate.defaultWorkoutTitle,
        dateTime: _targetDate,
        totalDuration: 0,
        exercises: finalExercises,
        isPlanned: true,
      );

      await workoutService.savePlannedWorkout(plannedToSave);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // --- FIXED HEADER ---
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'COPY WORKOUT',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Target Date Selector Card
                Card(
                  color: theme.colorScheme.surfaceContainerLow,
                  child: ListTile(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _targetDate.isBefore(todayStart)
                            ? todayStart
                            : _targetDate,
                        firstDate: todayStart,
                        lastDate: todayStart.add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          _targetDate = picked;
                        });
                      }
                    },
                    leading: Icon(
                      IconUtils.calendarMonth,
                      color: theme.colorScheme.secondary,
                    ),
                    title: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_targetDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _isToday
                          ? "Destination: Today's Active Session"
                          : 'Destination: Scheduled Future Date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    trailing: Icon(
                      IconUtils.edit,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Overwrite vs Merge Toggle.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _overwrite
                        ? (_isToday
                              ? "Overwrite Today's Workout"
                              : 'Overwrite Scheduled Workout')
                        : (_isToday
                              ? "Merge with Today's Workout"
                              : 'Merge with Scheduled Workout'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _overwrite
                        ? 'Current exercises on destination date will be replaced.'
                        : 'Copied exercises will be appended to destination date.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _overwrite,
                  onChanged: (bool value) {
                    setState(() {
                      _overwrite = value;
                    });
                  },
                ),

                // Empty vs Values Toggle.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _emptyExercises
                        ? 'Copy as Empty Template'
                        : 'Copy All Values',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _emptyExercises
                        ? 'Only exercise selections will be copied. '
                              'Sets, reps, and durations will be empty.'
                        : 'All sets, reps, weight, and durations will be '
                              'copied exactly.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _emptyExercises,
                  onChanged: (bool value) {
                    setState(() {
                      _emptyExercises = value;
                    });
                  },
                ),

                // Timer Toggle (Only relevant if copying to Today).
                if (_isToday)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _keepCurrentTime
                          ? 'Keep Current Total Time'
                          : 'Add To Total Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _keepCurrentTime
                          ? "Today's current total time will remain unaffected."
                          : "The copied workout's total time will be "
                                "added to today's current total time.",
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: _keepCurrentTime,
                    onChanged: (bool value) {
                      setState(() {
                        _keepCurrentTime = value;
                      });
                    },
                  ),

                const SizedBox(height: 24),

                // Buttons Row.
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context, false);
                              },
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _performCopy,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              )
                            : Text(
                                _isToday
                                    ? 'COPY TO TODAY'
                                    : 'SCHEDULE FOR '
                                          '${DateFormat('MMM d').format(_targetDate).toUpperCase()}',
                              ),
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
