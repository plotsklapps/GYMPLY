import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gymply/modals/deleteworkout_modal.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/statisticsscreen/exercisedetailcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/sectionheader_widget.dart';
import 'package:gymply/screens/statisticsscreen/stattile_widget.dart';
import 'package:gymply/services/image_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutSummaryModal extends StatelessWidget {
  const WorkoutSummaryModal({required this.workout, super.key});

  final Workout workout;

  Future<void> _showFullScreenImage(BuildContext context, String path) async {
    final ThemeData theme = Theme.of(context);

    // Show user's picture.
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSecondary,
                    foregroundColor: theme.colorScheme.secondary,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.circleX),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String cardioDistance = workout.totalCardioDistance.toStringAsFixed(
      1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // --- STICKY HEADER ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    workout.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    workout.formattedDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(LucideIcons.circleEllipsis),
              onSelected: (String value) async {
                if (value == 'delete') {
                  // Confirm deletion.
                  final bool confirm = await ModalService.showModal(
                    context: context,
                    child: const DeleteWorkoutModal(),
                  );

                  if (confirm) {
                    // Close WorkoutSummary modal first.
                    if (context.mounted) Navigator.pop(context);
                    // Perform actual deletion.
                    await workoutService.deleteWorkout(workout.dateKey);
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text('Delete'),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: Icon(
                              LucideIcons.trash,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),

        // ID and dateKey.
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'ID: ${workout.id.substring(0, 8)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              'dateKey: ${workout.dateKey}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),

        const Divider(),

        // --- SCROLLABLE BODY ---
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 16),
                if (workout.notes.isNotEmpty) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withAlpha(100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          LucideIcons.notebookPen,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            workout.notes,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // --- IMAGES SECTION ---
                if (workout.imagePaths.isNotEmpty) ...<Widget>[
                  Row(
                    children: <Widget>[
                      for (int i = 0; i < workout.imagePaths.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: i == 0 ? 0 : 4,
                              right: i == workout.imagePaths.length - 1 ? 0 : 4,
                            ),
                            child: FutureBuilder<String>(
                              future: imageService.getAbsolutePath(
                                workout.imagePaths[i],
                              ),
                              builder:
                                  (
                                    BuildContext context,
                                    AsyncSnapshot<String> snapshot,
                                  ) {
                                    if (snapshot.hasData) {
                                      return GestureDetector(
                                        onTap: () => _showFullScreenImage(
                                          context,
                                          snapshot.data!,
                                        ),
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          child: SizedBox(
                                            height: 160,
                                            child: Image.file(
                                              File(snapshot.data!),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox(
                                      height: 160,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                      // Fill remaining space if only 1 image.
                      if (workout.imagePaths.length == 1)
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                const StatisticsSectionHeader(title: 'WORKOUT OVERVIEW'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: <Widget>[
                    StatTile(
                      label: 'Exercises',
                      value: workout.exerciseCount.toString(),
                      icon: LucideIcons.dumbbell,
                    ),
                    StatTile(
                      label: 'Sets',
                      value: workout.totalSets.toString(),
                      icon: LucideIcons.arrowUpWideNarrow,
                    ),
                    StatTile(
                      label: 'Time',
                      value: workout.totalDuration.formatHHMM(),
                      icon: LucideIcons.timer,
                    ),
                  ],
                ),

                if (workout.strengthExerciseCount > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  const StatisticsSectionHeader(title: 'STRENGTH TOTALS'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: <Widget>[
                      StatTile(
                        label: 'Volume',
                        value: '${workout.totalStrengthVolume} kg',
                        icon: LucideIcons.weight,
                      ),
                      StatTile(
                        label: 'Reps',
                        value: workout.totalReps.toString(),
                        icon: LucideIcons.arrowUp10,
                      ),
                      StatTile(
                        label: 'Avg Weight',
                        value:
                            '${workout.avgWorkoutWeight.toStringAsFixed(1)}kg',
                        icon: LucideIcons.circleGauge,
                      ),
                    ],
                  ),
                ],

                if (workout.cardioExerciseCount > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  const StatisticsSectionHeader(title: 'CARDIO TOTALS'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: <Widget>[
                      StatTile(
                        label: 'Distance',
                        value: '${cardioDistance}km',
                        icon: LucideIcons.rulerDimensionLine,
                      ),
                      StatTile(
                        label: 'Calories',
                        value: '${workout.totalCardioCalories}kcal',
                        icon: LucideIcons.flame,
                      ),
                      StatTile(
                        label: 'Duration',
                        value: workout.totalCardioTime.format(),
                        icon: LucideIcons.clock,
                      ),
                    ],
                  ),
                ],

                if (workout.stretchExerciseCount > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  const StatisticsSectionHeader(title: 'STRETCH TOTALS'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: <Widget>[
                      StatTile(
                        label: 'Stretch Count',
                        value: workout.stretchExerciseCount.toString(),
                        icon: LucideIcons.arrowUp10,
                      ),
                      StatTile(
                        label: 'Stretch',
                        value: workout.totalStretchTime.format(),
                        icon: LucideIcons.personStanding,
                      ),
                      StatTile(
                        label: 'Duration',
                        value: workout.totalCardioDuration.format(),
                        icon: LucideIcons.timer,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const StatisticsSectionHeader(title: 'EXERCISE BREAKDOWN'),
                ...workout.exercises.map(
                  (WorkoutExercise ex) {
                    return ExerciseDetailCard(exercise: ex);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
