import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class SavePlannedWorkoutModal extends SignalStatefulWidget {
  const SavePlannedWorkoutModal({super.key});

  @override
  State<SavePlannedWorkoutModal> createState() {
    return _SavePlannedWorkoutModalState();
  }
}

class _SavePlannedWorkoutModalState extends State<SavePlannedWorkoutModal> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Workout workout = sActiveWorkout.value;
    final String defaultTitle = workout.dateTime.defaultWorkoutTitle;

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
                    'SCHEDULE WORKOUT',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'PRE-FILLED FOR FUTURE',
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Date Badge Card
              Card(
                color: theme.colorScheme.surfaceContainerLow,
                child: ListTile(
                  leading: Icon(
                    IconUtils.calendarMonth,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(workout.dateTime),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${workout.exercises.length} Exercises pre-configured',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title Field
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Workout Title',
                  hintText: defaultTitle,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),

              const SizedBox(height: 16),

              // Exercise List Summary
              Text(
                'PRELOADED EXERCISES (${workout.exercises.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),

              if (workout.exercises.isEmpty)
                Text(
                  'No exercises added yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: workout.exercises.map((WorkoutExercise ex) {
                        return ListTile(
                          dense: true,
                          leading: Image.asset(
                            ex.imagePath,
                            width: 36,
                            fit: BoxFit.contain,
                          ),
                          title: Text(
                            ex.exerciseName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Text(
                            '${ex.totalSets} Sets',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final String title = _titleController.text.trim().isEmpty
                        ? defaultTitle
                        : _titleController.text.trim();

                    final Workout plannedToSave = workout.copyWith(
                      title: title,
                      isPlanned: true,
                    );

                    await workoutService.savePlannedWorkout(plannedToSave);

                    // Reset active workout to fresh today session.
                    sActiveWorkout.value = Workout(
                      id: const Uuid().v4(),
                      title: DateTime.now().defaultWorkoutTitle,
                      dateTime: DateTime.now(),
                      totalDuration: 0,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(IconUtils.save),
                  label: const Text('SAVE PLANNED WORKOUT'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
