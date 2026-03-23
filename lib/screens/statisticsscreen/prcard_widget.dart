import 'package:flutter/material.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PRCard extends StatelessWidget {
  const PRCard({
    required this.workoutPRs,
    super.key,
  });

  final List<Map<String, dynamic>> workoutPRs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  LucideIcons.trophy,
                  size: 32,
                  color: theme.colorScheme.onSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'CONGRATULATIONS!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                      Text(
                        'You broke ${workoutPRs.length} Personal Records today!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            ...workoutPRs.map((Map<String, dynamic> pr) {
              final String type = pr['type'] as String;
              final WorkoutExercise exercise =
                  pr['exercise'] as WorkoutExercise;
              final String exerciseName = pr['exerciseName']
                  .toString()
                  .toUpperCase();
              String detail = '';

              if (type == 'REP') {
                detail = '${pr['value'].toStringAsFixed(0)} kg';
              } else if (type == 'SET') {
                detail =
                    '${pr['weight'].toStringAsFixed(0)} kg x ${pr['reps']} reps';
              } else if (type == 'TOTAL') {
                detail = '${pr['value'].toStringAsFixed(1)} kg Volume';
              }

              return ListTile(
                onTap: () {
                  workoutService.sSelectedExercise.value = exercise;
                  navigateToTab(AppTab.exercise);
                },
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.onSecondary,
                  backgroundImage: AssetImage(exercise.imagePath),
                ),
                title: Text(
                  '$exerciseName $type PR',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
                trailing: Icon(
                  LucideIcons.chevronRight,
                  color: theme.colorScheme.onSecondary,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
