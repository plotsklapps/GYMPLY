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

    // Watch Signals for UI state and filtering.
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

    // Watch Favorites to reactively show/hide stars on cards.
    final List<int> favorites = workoutService.sFavoriteExercises.watch(
      context,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. WorkoutType ChoiceChips & SearchBar.
          Row(
            children: <Widget>[
              // Category Selection (Takes only needed space).
              WorkoutTypeChoiceChips(
                workoutType: workoutType,
                theme: theme,
              ),
              const SizedBox(width: 8),
              // Keyboard Search (Fills remaining space).
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: SearchBar(
                    elevation: const WidgetStatePropertyAll<double>(0.0),
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    hintText: 'Search...',
                    hintStyle: WidgetStatePropertyAll<TextStyle?>(
                      theme.textTheme.bodySmall,
                    ),
                    textStyle: WidgetStatePropertyAll<TextStyle?>(
                      theme.textTheme.bodySmall,
                    ),
                    leading: const FaIcon(
                      FontAwesomeIcons.magnifyingGlass,
                      size: 14,
                    ),
                    onChanged: (String value) {
                      // Triggers snappy, per-letter filtering in FilterService.
                      sSearchQuery.value = value;
                    },
                  ),
                ),
              ),
            ],
          ),

          // 2. MuscleGroup ChoiceChips (Conditional).
          if (showMuscleGroups) ...<Widget>[
            MuscleGroupChoiceChips(
              selectedMuscleGroup: selectedMuscleGroup,
              theme: theme,
            ),
          ],

          // 3. Equipment ChoiceChips (Conditional).
          if (showEquipment) ...<Widget>[
            EquipmentChoiceChips(
              workoutType: workoutType,
              selectedEquipment: selectedEquipment,
              theme: theme,
            ),
          ],

          const Divider(),

          // 4. Exercise GridView.
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          // Show message if search results are empty and the user is actually searching/filtering.
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
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          // Exercise Image.
                          Image.asset(
                            exercise.fullPath,
                            fit: BoxFit.contain,
                          ),
                          // Favorite Star (Only shown if isFavorite).
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
