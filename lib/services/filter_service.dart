import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/signals/allexercisespaths_signal.dart';
import 'package:gymply/signals/favoriteexercises_signal.dart';
import 'package:gymply/signals/searchquery_signal.dart';
import 'package:gymply/signals/selectedequipment_signal.dart';
import 'package:gymply/signals/selectedmusclegroup_signal.dart';
import 'package:gymply/signals/selectedworkouttype_signal.dart';
import 'package:signals/signals_flutter.dart';

// Takes raw data from ExerciseService and user input to calculate final
// filtered list. Watches sAllExercisePaths for raw list, sFavoriteExercises
// for sorting favorites and creates cFilteredExercises for UI to consume.

class FilterService {
  // Singleton pattern.
  factory FilterService() {
    return _instance;
  }

  FilterService._internal();
  static final FilterService _instance = FilterService._internal();

  // Computed Signal recalculates whenever ANY of the watched Signals change.
  late final Computed<List<ExercisePath>> cFilteredExercises = computed(() {
    // Gather all relevant state.
    final WorkoutType? workoutType = sSelectedWorkoutType.value;
    final MuscleGroup? musclegroup = sSelectedMuscleGroup.value;
    final Equipment? equipment = sSelectedEquipment.value;
    final String searchQuery = sSearchQuery.value.trim().toLowerCase();
    final List<ExercisePath> allExercisesPaths = sAllExercisePaths.value;
    final List<int> favoriteExercises = sFavoriteExercises.value;

    // INITIAL FILTER: Nothing selected, show empty list.
    if (workoutType == null && searchQuery.isEmpty) return <ExercisePath>[];

    // Apply filtering criteria.
    final List<ExercisePath> filtered =
        allExercisesPaths.where((ExercisePath ex) {
            // Allow fuzzy search: 'bench chest' retrieves 'Chest-Bench Press'.
            if (searchQuery.isNotEmpty) {
              final List<String> tokens = searchQuery.split(' ').where((
                String t,
              ) {
                return t.isNotEmpty;
              }).toList();
              final String searchBlob =
                  '${ex.exerciseName} ${ex.id} '
                          '${ex.muscleSegment} ${ex.equipmentSegment}'
                      .toLowerCase();

              // Match ONLY if EVERY token typed by user exists in data.
              if (!tokens.every(searchBlob.contains)) return false;
            }

            // WorkoutType (Strength / Cardio / Stretch) logic.
            if (workoutType != null) {
              if (workoutType == WorkoutType.strength) {
                if (ex.muscleSegment == 'Cardio' ||
                    ex.equipmentSegment == 'Stretch') {
                  return false;
                }
              } else if (workoutType == WorkoutType.cardio) {
                if (ex.muscleSegment != 'Cardio') return false;
              } else if (workoutType == WorkoutType.stretch) {
                if (ex.equipmentSegment != 'Stretch') return false;
              }
            }

            // Musclegroup ChoiceChip logic.
            if (musclegroup != null && workoutType != WorkoutType.cardio) {
              if (ex.muscleSegment.toLowerCase() !=
                  musclegroup.name.toLowerCase()) {
                return false;
              }
            }

            // Equipment ChoiceChip logic.
            if (equipment != null && workoutType != WorkoutType.stretch) {
              if (ex.equipmentSegment.toLowerCase() !=
                  equipment.name.toLowerCase()) {
                return false;
              }
            }

            return true;
          }).toList()
          // Apply sorting: Favorites first, then alphabetical.
          ..sort((ExercisePath a, ExercisePath b) {
            final bool isAFavorite = favoriteExercises.contains(
              int.parse(a.id),
            );
            final bool isBFavorite = favoriteExercises.contains(
              int.parse(b.id),
            );

            if (isAFavorite && !isBFavorite) return -1;
            if (!isAFavorite && isBFavorite) return 1;
            return a.exerciseName.compareTo(b.exerciseName);
          });

    return filtered;
  }, debugLabel: 'cFilteredExercises');

  // Helper Signals to help UI decide which ChoiceChips to show.
  late final Computed<bool> sShowMuscleGroups = computed(() {
    final WorkoutType? type = sSelectedWorkoutType.value;
    return type == WorkoutType.strength || type == WorkoutType.stretch;
  }, debugLabel: 'sShowMuscleGroups');

  late final Computed<bool> sShowEquipment = computed(() {
    final WorkoutType? type = sSelectedWorkoutType.value;
    return type == WorkoutType.strength || type == WorkoutType.cardio;
  }, debugLabel: 'sShowEquipment');
}

// Globalize FilterService.
final FilterService filterService = FilterService();
