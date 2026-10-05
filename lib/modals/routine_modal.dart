import 'package:gymply/modals/searchmodal/search_modal.dart';
import 'package:gymply/models/routine_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/routine_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class RoutineModal extends SignalStatefulWidget {
  const RoutineModal({super.key});

  @override
  State<RoutineModal> createState() {
    return _RoutineModalState();
  }
}

class _RoutineModalState extends State<RoutineModal> {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Routine> routines = sRoutines.value;

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
                    'ROUTINES & TEMPLATES',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'REUSABLE WORKOUTS',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (routines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            IconUtils.list,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NO ROUTINES SAVED YET',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a routine template or save your completed workouts as routines.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: routines.map((Routine routine) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHigh,
                                      child: Icon(
                                        IconUtils.dumbbell,
                                        color: theme.colorScheme.secondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            routine.title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            '${routine.exercises.length} Exercises',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(IconUtils.delete),
                                      color: theme.colorScheme.error,
                                      onPressed: () async {
                                        await routineService.deleteRoutine(
                                          routine.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                if (routine.notes.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Text(
                                    routine.notes,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          // Load routine into sActiveWorkout as a routine template session
                                          sActiveWorkout.value = Workout(
                                            id: routine.id,
                                            title: routine.title,
                                            dateTime: DateTime.now(),
                                            totalDuration: 0,
                                            exercises: routine.exercises,
                                            notes: routine.notes,
                                            isPlanned: true,
                                            isRoutine: true,
                                          );

                                          Navigator.pop(context);
                                          navigateToTab(AppTab.workout);
                                        },
                                        icon: const Icon(IconUtils.edit),
                                        label: const Text('EDIT ROUTINE'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await routineService
                                              .startRoutineToday(routine);
                                        },
                                        icon: const Icon(IconUtils.play),
                                        label: const Text('START'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 16),

                  // Create New Routine Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);

                        // Start a fresh routine template container in sActiveWorkout
                        sActiveWorkout.value = Workout(
                          id: const Uuid().v4(),
                          title: 'New Routine',
                          dateTime: DateTime.now(),
                          totalDuration: 0,
                          isPlanned: true,
                          isRoutine: true,
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
                      },
                      icon: const Icon(IconUtils.add),
                      label: const Text('CREATE NEW ROUTINE'),
                    ),
                  ),
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
