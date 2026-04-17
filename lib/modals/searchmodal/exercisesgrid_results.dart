import 'package:flutter/material.dart';
import 'package:gymply/modals/exercisedetail_modal.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExercisesGridResults extends StatelessWidget {
  const ExercisesGridResults({
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
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.3,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final ExercisePath exercise = exercises[index];
            final bool isFavorite = favorites.contains(
              int.parse(exercise.id),
            );

            return InkWell(
              onTap: () async {
                searchFocusNode.unfocus();

                final bool confirm = await ModalService.showModal(
                  context: context,
                  child: ExerciseDetailSheet(exercise: exercise),
                );

                if (confirm) {
                  workoutService.addExercise(exercise);
                  // Pop both ExerciseDetailSheet and SearchModal.
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  navigateToTab(AppTab.workout);
                }
              },
              child: Card(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.asset(
                      exercise.fullPath,
                      fit: BoxFit.contain,
                    ),
                    if (isFavorite)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          LucideIcons.star,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      left: 0,
                      child: Container(
                        decoration: theme.brightness == Brightness.dark
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.black.withAlpha(0),
                                    Colors.black.withAlpha(255),
                                  ],
                                ),
                              )
                            : BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.white.withAlpha(0),
                                    Colors.white.withAlpha(255),
                                  ],
                                ),
                              ),
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          exercise.exerciseName,
                          textAlign: TextAlign.right,
                          softWrap: false,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
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
