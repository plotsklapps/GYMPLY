import 'package:flutter/material.dart';
import 'package:gymply/screens/searchscreen/equipmentchoicechips.dart';
import 'package:gymply/screens/searchscreen/musclegroupchoicechips.dart';
import 'package:gymply/screens/searchscreen/workouttypechoicechips.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/sheet_service.dart';
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
    final bool showMuscleGroups = filterService.sShowMuscleGroups.watch(
      context,
    );
    final bool showEquipment = filterService.sShowEquipment.watch(context);
    final List<ExercisePath> filteredExercises = filterService
        .cFilteredExercises
        .watch(context);
    final bool isLoading = sLoading.watch(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. WorkoutType ChoiceChips.
          WorkoutTypeChoiceChips(workoutType: workoutType, theme: theme),

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
          else if (workoutType != null && filteredExercises.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No exercises found matching these filters.'),
              ),
            )
          else if (workoutType != null)
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
