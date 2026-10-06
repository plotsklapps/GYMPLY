import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/routine_model.dart';
import 'package:gymply/services/routine_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';

class EditRoutineModal extends StatefulWidget {
  const EditRoutineModal({required this.routine, super.key});

  final Routine routine;

  @override
  State<EditRoutineModal> createState() {
    return _EditRoutineModalState();
  }
}

class _EditRoutineModalState extends State<EditRoutineModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final FocusNode _titleFocusNode;
  late List<MuscleGroup> _selectedGroups;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController(text: widget.routine.notes);
    _titleFocusNode = FocusNode();
    _selectedGroups = List<MuscleGroup>.from(widget.routine.activeMuscleGroups);

    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        _titleController.clear();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                    'EDIT ROUTINE',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'UPDATE TITLE & AVATARS',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: widget.routine.title,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ROUTINE AVATARS (UP TO 3)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Avatar Picker Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        // Option 0: Default Dumbbell
                        InkWell(
                          onTap: () {
                            setState(_selectedGroups.clear);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedGroups.isEmpty
                                          ? theme.colorScheme.secondary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor:
                                        theme.colorScheme.surfaceContainerHigh,
                                    child: Icon(
                                      IconUtils.dumbbell,
                                      color: theme.colorScheme.secondary,
                                      size: 26,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Default',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: _selectedGroups.isEmpty
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedGroups.isEmpty
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Muscle Group Avatar Options
                        ...MuscleGroup.values.map((MuscleGroup group) {
                          final bool isSelected = _selectedGroups.contains(
                            group,
                          );
                          final String assetName = group.name.capitalizeFirst();

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedGroups.remove(group);
                                  } else {
                                    if (_selectedGroups.length < 3) {
                                      _selectedGroups.add(group);
                                    } else {
                                      ToastService.showError(
                                        title: 'Maximum Reached',
                                        subtitle:
                                            'You can select up to 3 muscle group avatars.',
                                      );
                                    }
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? theme.colorScheme.secondary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: theme
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Image.asset(
                                            'assets/images/musclegroups/$assetName.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      assetName,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? theme.colorScheme.secondary
                                                : theme.colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final String newTitle =
                                _titleController.text.trim().isEmpty
                                ? widget.routine.title
                                : _titleController.text.trim();
                            final Routine updated = widget.routine.copyWith(
                              title: newTitle,
                              notes: _notesController.text.trim(),
                              muscleGroups: _selectedGroups,
                            );
                            await routineService.updateRoutine(updated);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('SAVE'),
                        ),
                      ),
                    ],
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
