import 'package:gymply/modals/editroutine_modal.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/routine_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/routine_service.dart';
import 'package:gymply/services/textformat_service.dart';
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
                    'ROUTINES',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'REUSABLE TEMPLATES',
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
              padding: const EdgeInsets.only(bottom: 8),
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
                        final List<MuscleGroup> activeGroups =
                            routine.activeMuscleGroups;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    if (activeGroups.isEmpty)
                                      CircleAvatar(
                                        backgroundColor: theme
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        child: Icon(
                                          IconUtils.dumbbell,
                                          color: theme.colorScheme.secondary,
                                          size: 20,
                                        ),
                                      )
                                    else
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: activeGroups.map((
                                          MuscleGroup group,
                                        ) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: CircleAvatar(
                                              radius: 18,
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .surfaceContainerHigh,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: Image.asset(
                                                  'assets/images/musclegroups/${group.name.capitalizeFirst()}.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${routine.exercises.length} Exercises'
                                            '${activeGroups.isNotEmpty ? " • ${activeGroups.map((MuscleGroup g) => g.name.capitalizeFirst()).join(' + ')}" : ""}',
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
                                          await ModalService.showModal(
                                            context: context,
                                            child: EditRoutineModal(
                                              routine: routine,
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'edit',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(IconUtils.notes),
                                                SizedBox(width: 8),
                                                Text('Edit Title/Avatars'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  IconUtils.trash,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Delete Routine',
                                                  style: TextStyle(
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                ),
                                              ],
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
}
