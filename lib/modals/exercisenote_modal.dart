import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';

class ExerciseNoteModal extends StatefulWidget {
  const ExerciseNoteModal({required this.exercise, super.key});

  final WorkoutExercise exercise;

  @override
  State<ExerciseNoteModal> createState() {
    return _ExerciseNoteModalState();
  }
}

class _ExerciseNoteModalState extends State<ExerciseNoteModal> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.exercise.notes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            // Empty SizedBox to balance Icon and Text.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'EXERCISE NOTE',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 8),
                Text(
                  widget.exercise.exerciseName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText:
                        'Add notes, seat settings, or personal cues for this '
                        'exercise...',
                    border: OutlineInputBorder(),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final String newNotes = _controller.text.trim();
                          workoutService.updateExerciseNotes(
                            widget.exercise,
                            newNotes,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text('SAVE NOTE'),
                      ),
                    ),
                  ],
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
