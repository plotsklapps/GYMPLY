import 'package:flutter/material.dart';
import 'package:gymply/modals/exercisedetail_sheet.dart';
import 'package:gymply/screens/searchscreen/equipmentchoicechips.dart';
import 'package:gymply/screens/searchscreen/musclegroupchoicechips.dart';
import 'package:gymply/screens/searchscreen/workouttypechoicechips.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/loading_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:signals/signals_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() {
    return _SearchScreenState();
  }
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchController searchController = SearchController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

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
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SearchBar(
              controller: searchController,
              focusNode: searchFocusNode,
              onTapOutside: (PointerDownEvent event) {
                searchFocusNode.unfocus();
              },
              leading: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        // Clear SearchBar.
                        searchController.clear();

                        // Clear Signal.
                        sSearchQuery.value = '';

                        // Dismiss keyboard.
                        searchFocusNode.unfocus();
                      },
                      icon: const Icon(LucideIcons.searchX),
                    )
                  : IconButton(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.search),
                    ),
              onChanged: (String value) {
                // Trigger per-letter filtering (FilterService).
                sSearchQuery.value = value;
              },
            ),
          ),
          Row(
            children: <Widget>[
              // Workout Type ChoiceChips.
              WorkoutTypeChoiceChips(
                workoutType: workoutType,
                theme: theme,
              ),

              // Keyboard Search.
            ],
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
                      // Dismiss keyboard.
                      searchFocusNode.unfocus();

                      // Show ExerciseDetailSheet.
                      final bool confirm = await ModalService.showModal(
                        context: context,
                        child: ExerciseDetailSheet(exercise: exercise),
                      );

                      if (confirm) {
                        // Add the exercise to today's workout.
                        workoutService.addExercise(exercise);

                        // Navigate to WorkoutScreen.
                        navigateToTab(AppTabs.workout);
                      }
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
                              child: Icon(
                                LucideIcons.star,
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
