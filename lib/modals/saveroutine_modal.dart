import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/routine_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/routine_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class SaveRoutineModal extends SignalStatefulWidget {
  const SaveRoutineModal({super.key});

  @override
  State<SaveRoutineModal> createState() {
    return _SaveRoutineModalState();
  }
}

class _SaveRoutineModalState extends State<SaveRoutineModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  bool _keepRoutineValues = true;

  @override
  void initState() {
    super.initState();
    final Workout workout = sActiveWorkout.value;
    _titleController = TextEditingController(
      text: workout.title != DateTime.now().defaultWorkoutTitle
          ? workout.title
          : '',
    );
    _notesController = TextEditingController(text: workout.notes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Workout workout = sActiveWorkout.value;

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
                    'SAVE ROUTINE TEMPLATE',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'REUSABLE WORKOUT',
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Routine Title
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Routine Title',
                      hintText: 'e.g., Chest & Triceps Power',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description / Notes
                  TextField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Cues',
                      hintText: 'e.g., Focus on controlled eccentric, 90s rest',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Exercise Summary List
                  Text(
                    'ROUTINE EXERCISES (${workout.exercises.length})',
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

                  const SizedBox(height: 16),

                  // Keep Values Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Keep Sets, Reps & Weight Values',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Preserve set values in template (otherwise empty sets).',
                    ),
                    value: _keepRoutineValues,
                    onChanged: (bool value) {
                      setState(() {
                        _keepRoutineValues = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final String title =
                            _titleController.text.trim().isEmpty
                            ? 'My Routine'
                            : _titleController.text.trim();

                        final List<WorkoutExercise> routineExercises =
                            <WorkoutExercise>[];
                        for (final WorkoutExercise ex in workout.exercises) {
                          if (_keepRoutineValues) {
                            routineExercises.add(ex.copyWith());
                          } else {
                            if (ex is StrengthExercise) {
                              routineExercises.add(
                                ex.copyWith(sets: <StrengthSet>[]),
                              );
                            } else if (ex is CardioExercise) {
                              routineExercises.add(
                                ex.copyWith(sets: <CardioSet>[]),
                              );
                            } else if (ex is StretchExercise) {
                              routineExercises.add(
                                ex.copyWith(sets: <StretchSet>[]),
                              );
                            } else {
                              routineExercises.add(ex.copyWith());
                            }
                          }
                        }

                        final Routine newRoutine = Routine(
                          id: workout.id,
                          title: title,
                          exercises: routineExercises,
                          notes: _notesController.text.trim(),
                        );

                        await routineService.saveRoutine(newRoutine);

                        // Reset active workout back to blank today session!
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
                      label: const Text('SAVE ROUTINE'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
