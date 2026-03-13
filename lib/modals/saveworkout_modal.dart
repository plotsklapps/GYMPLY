import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/modals/addimage_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/image_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SaveWorkoutModal extends StatefulWidget {
  const SaveWorkoutModal({super.key});

  @override
  State<SaveWorkoutModal> createState() {
    return _SaveWorkoutModalState();
  }
}

class _SaveWorkoutModalState extends State<SaveWorkoutModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  final int _maxTitleLength = 40;
  final int _maxNoteLength = 150;

  // To store up to two image filenames (relative paths).
  final List<String?> _imageFilenames = <String?>[null, null];

  @override
  void initState() {
    super.initState();
    // Load existing data from the active workout.
    final Workout workout = workoutService.sActiveWorkout.value;
    _titleController.text = workout.title;
    _notesController.text = workout.notes;
    for (int i = 0; i < workout.imagePaths.length && i < 2; i++) {
      _imageFilenames[i] = workout.imagePaths[i];
    }
  }

  @override
  void dispose() {
    // Kill controllers.
    _titleController.dispose();
    _notesController.dispose();
    _titleFocusNode.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    // Modal to choose phone gallery or camera.
    final ImageSource? source = await addImageModal(
      context,
    );

    if (source != null) {
      final String? filename = await imageService.pickAndSaveImage(source);
      if (filename != null) {
        setState(() {
          _imageFilenames[index] = filename;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFilenames[index] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String formattedDate = DateFormat.yMMMMd().format(DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'SAVE WORKOUT',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Text(
              formattedDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Title Field.
        TextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          onTapOutside: (PointerDownEvent event) {
            _titleFocusNode.unfocus();
          },
          decoration: const InputDecoration(
            labelText: 'Workout title',
          ),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLength: _maxTitleLength,
          buildCounter:
              (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
                return Text(
                  '${_maxTitleLength - currentLength} / $_maxTitleLength',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: currentLength >= _maxTitleLength
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                );
              },
        ),

        const SizedBox(height: 16),

        // Notes field.
        TextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          onTapOutside: (PointerDownEvent event) {
            _notesFocusNode.unfocus();
          },
          decoration: const InputDecoration(
            labelText: 'How did it go?',
          ),
          maxLines: 3,
          maxLength: _maxNoteLength,
          buildCounter:
              (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) {
                return Text(
                  '${_maxNoteLength - currentLength} / $_maxNoteLength',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: currentLength >= _maxNoteLength
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                );
              },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (int i = 0; i < 2; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == 1 ? 0 : 4,
                  ),
                  child: InkWell(
                    onTap: () async {
                      await _pickImage(i);
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: 160,
                        child: _imageFilenames[i] == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(LucideIcons.imagePlus),
                                  SizedBox(height: 8),
                                  Text('Add image'),
                                ],
                              )
                            : FutureBuilder<String>(
                                future: imageService.getAbsolutePath(
                                  _imageFilenames[i]!,
                                ),
                                builder:
                                    (
                                      BuildContext context,
                                      AsyncSnapshot<String> snapshot,
                                    ) {
                                      if (snapshot.hasData) {
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: <Widget>[
                                            Image.file(
                                              File(snapshot.data!),
                                              fit: BoxFit.cover,
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: CircleAvatar(
                                                backgroundColor: Colors.black54,
                                                radius: 16,
                                                child: IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: const Icon(
                                                    LucideIcons.trash2,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () =>
                                                      _removeImage(i),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  await HapticFeedback.heavyImpact();

                  // Filter out null values for saving.
                  final List<String> imagesToSave = _imageFilenames
                      .where((String? path) => path != null)
                      .cast<String>()
                      .toList();

                  // Save current workout.
                  await workoutService.finishWorkout(
                    title: _titleController.text,
                    notes: _notesController.text,
                    imagePaths: imagesToSave,
                  );

                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('SAVE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
