import 'package:flutter/material.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/statisticsscreen/exercisedetailcard_widget.dart';
import 'package:gymply/screens/statisticsscreen/sectionheader_widget.dart';
import 'package:gymply/screens/statisticsscreen/stattile_widget.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutSummaryModal extends StatelessWidget {
  const WorkoutSummaryModal({required this.workout, super.key});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),

        // Subtle row for ID and dateKey.
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

        const Divider(height: 24),

        // --- SCROLLABLE BODY ---
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (workout.notes.isNotEmpty) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Notes: ${workout.notes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
                        value:
                            '${workout.totalCardioDistance.toStringAsFixed(1)}km',
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
                  (WorkoutExercise ex) => ExerciseDetailCard(exercise: ex),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
