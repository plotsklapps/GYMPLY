import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/screens/searchscreen/equipmentchoicechips.dart';
import 'package:gymply/screens/searchscreen/musclegroupchoicechips.dart';
import 'package:gymply/screens/searchscreen/workouttypechoicechips.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/sheet_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/sheets/exercisedetail_sheet.dart';
import 'package:gymply/signals/loading_signal.dart';
import 'package:signals/signals_flutter.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final WorkoutType? workoutType = sSelectedWorkoutType.watch(context);
    final MuscleGroup? selectedMuscleGroup = sSelectedMuscleGroup.watch(
      context,
    );
    final Equipment? selectedEquipment = sSelectedEquipment.watch(context);
    final String searchQuery = sSearchQuery.watch(context);

    final bool showMuscleGroups = filterService.sShowMuscleGroups.watch(
      context,
    );
    final bool showEquipment = filterService.sShowEquipment.watch(context);
    final List<ExercisePath> filteredExercises = filterService
        .cFilteredExercises
        .watch(context);
    final bool isLoading = sLoading.watch(context);
    final List<int> favorites = workoutService.sFavoriteExercises.watch(
      context,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Workout Type ChoiceChips.
                WorkoutTypeChoiceChips(
                  workoutType: workoutType,
                  theme: theme,
                ),
                const SizedBox(width: 8),
                // Keyboard Search.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SearchBar(
                      constraints: const BoxConstraints(),
                      hintStyle: WidgetStatePropertyAll<TextStyle?>(
                        theme.textTheme.bodySmall,
                      ),
                      textStyle: WidgetStatePropertyAll<TextStyle?>(
                        theme.textTheme.bodySmall,
                      ),
                      leading: const FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        size: 12,
                      ),
                      onChanged: (String value) {
                        // Trigger per-letter filtering (FilterService).
                        sSearchQuery.value = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MuscleGroup ChoiceChips (Conditional).
          if (showMuscleGroups) ...<Widget>[
            MuscleGroupChoiceChips(
              selectedMuscleGroup: selectedMuscleGroup,
              theme: theme,
            ),
          ],

          // Equipment ChoiceChips (Conditional).
          if (showEquipment) ...<Widget>[
            EquipmentChoiceChips(
              workoutType: workoutType,
              selectedEquipment: selectedEquipment,
              theme: theme,
            ),
          ],

          const Divider(),

          // Exercise GridView.
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          // Search results empty.
          else if (filteredExercises.isEmpty &&
              (workoutType != null || searchQuery.isNotEmpty))
            const Expanded(
              child: Center(
                child: Text('No exercises found matching these filters.'),
              ),
            )
          else if (filteredExercises.isNotEmpty)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.3,
                ),
                itemCount: filteredExercises.length,
                itemBuilder: (BuildContext context, int index) {
                  final ExercisePath exercise = filteredExercises[index];
                  final bool isFavorite = favorites.contains(
                    int.parse(exercise.id),
                  );

                  return InkWell(
                    onTap: () async {
                      await SheetService.showSheet(
                        context: context,
                        child: ExerciseDetailSheet(exercise: exercise),
                      );
                    },
                    child: Card(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          // Exercise Image.
                          Image.asset(
                            exercise.fullPath,
                            fit: BoxFit.contain,
                          ),
                          // Favorite Star (Conditional).
                          if (isFavorite)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: FaIcon(
                                FontAwesomeIcons.solidStar,
                                color: theme.colorScheme.secondary,
                                size: 16,
                              ),
                            ),
                          // Exercise Name.
                          Positioned(
                            bottom: 8,
                            right: 8,
                            left: 8,
                            child: Text(
                              exercise.exerciseName,
                              textAlign: TextAlign.right,
                              softWrap: false,
                              style: theme.textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
