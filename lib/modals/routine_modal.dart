import 'package:gymply/models/routine_model.dart';
import 'package:gymply/services/routine_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

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
                            'Finish a workout and toggle "Save as Routine" on the Save Workout screen to create templates.',
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
                                    PopupMenuButton<String>(
                                      icon: const Icon(IconUtils.more),
                                      onSelected: (String choice) async {
                                        if (choice == 'delete') {
                                          await routineService.deleteRoutine(
                                            routine.id,
                                          );
                                        } else if (choice == 'edit') {
                                          _showEditRoutineDialog(
                                            context,
                                            routine,
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Text('Edit Title/Notes'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Text(
                                              'Delete Routine',
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ];
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
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await routineService.startRoutineToday(
                                        routine,
                                      );
                                    },
                                    icon: const Icon(IconUtils.play),
                                    label: const Text('START THIS ROUTINE'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  void _showEditRoutineDialog(BuildContext context, Routine routine) {
    final TextEditingController titleController = TextEditingController(
      text: routine.title,
    );
    final TextEditingController notesController = TextEditingController(
      text: routine.notes,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Routine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () async {
                final String newTitle = titleController.text.trim().isEmpty
                    ? routine.title
                    : titleController.text.trim();
                final Routine updated = routine.copyWith(
                  title: newTitle,
                  notes: notesController.text.trim(),
                );
                await routineService.updateRoutine(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}
