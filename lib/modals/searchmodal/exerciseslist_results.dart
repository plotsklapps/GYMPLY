import 'package:flutter/material.dart';
import 'package:gymply/modals/exercisedetail_modal.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExercisesListResults extends StatelessWidget {
  const ExercisesListResults({
    required this.exercises,
    required this.favorites,
    required this.searchFocusNode,
    super.key,
  });

  final List<ExercisePath> exercises;
  final List<int> favorites;
  final FocusNode searchFocusNode;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final ExercisePath exercise = exercises[index];
            final bool isFavorite = favorites.contains(
              int.parse(exercise.id),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  height: 100,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          exercise.fullPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          onTap: () async {
                            searchFocusNode.unfocus();

                            final bool confirm = await ModalService.showModal(
                              context: context,
                              child: ExerciseDetailSheet(
                                exercise: exercise,
                              ),
                            );

                            if (confirm) {
                              workoutService.addExercise(exercise);
                              // Pop both ExerciseDetailSheet and SearchModal
                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              navigateToTab(AppTab.workout);
                            }
                          },
                          title: Text(
                            exercise.exerciseName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (isFavorite)
                                Icon(
                                  LucideIcons.star,
                                  color: theme.colorScheme.secondary,
                                ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.circleChevronRight),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: exercises.length,
        ),
      ),
    );
  }
}
