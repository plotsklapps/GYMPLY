import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/exercise_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:signals/signals_flutter.dart';

// RE-EXPORT the models so the UI can find WorkoutType, MuscleGroup, etc.
// This maintains compatibility while keeping the logic split.
export 'package:gymply/models/exercise_model.dart';

/// -- FILTERING & SEARCH LOGIC SERVICE --
///
/// Responsibility: Business Logic and UI State Management.
/// This service takes the "Raw Data" from the ExerciseService and the
/// "User Input" (Search query, ChoiceChips) to calculate the final filtered list.
///
/// RELATIONS:
/// - Watches ExerciseService.sAllExercisePaths for the raw list.
/// - Watches WorkoutService.sFavoriteExercises for sorting favorites.
/// - Provides a final Computed signal: cFilteredExercises for the UI to consume.

class FilterService {
  // Singleton pattern for globally shared logic state.
  factory FilterService() => _instance;
  FilterService._internal();
  static final FilterService _instance = FilterService._internal();

  /// -- UI INPUT SIGNALS --
  /// These track the user's current selections and search string.

  final Signal<WorkoutType?> sSelectedWorkoutType = Signal<WorkoutType?>(
    null,
    debugLabel: 'sSelectedWorkoutType',
  );

  final Signal<MuscleGroup?> sSelectedMuscleGroup = Signal<MuscleGroup?>(
    null,
    debugLabel: 'sSelectedMuscleGroup',
  );

  final Signal<Equipment?> sSelectedEquipment = Signal<Equipment?>(
    null,
    debugLabel: 'sSelectedEquipment',
  );

  final Signal<String> sSearchQuery = Signal<String>(
    '',
    debugLabel: 'sSearchQuery',
  );

  /// -- CORE FILTERING ENGINE --
  /// This 'Computed' signal is the "Single Source of Truth" for the UI list.
  /// It automatically re-calculates whenever any of the watched signals change.
  late final Computed<List<ExercisePath>> cFilteredExercises = computed(() {
    // 1. GATHER ALL RELEVANT STATE
    final WorkoutType? type = sSelectedWorkoutType.value;
    final MuscleGroup? muscle = sSelectedMuscleGroup.value;
    final Equipment? equip = sSelectedEquipment.value;
    final String query = sSearchQuery.value.trim().toLowerCase();

    // Fetch raw database from ExerciseService and user favorites from WorkoutService
    final List<ExercisePath> all = exerciseService.sAllExercisePaths.value;
    final List<int> favorites = workoutService.sFavoriteExercises.value;

    // 2. INITIAL FILTER (Safety net)
    // If no category is selected and no search typed, show an empty list.
    if (type == null && query.isEmpty) return <ExercisePath>[];

    // 3. APPLY FILTERING CRITERIA (AND Logic)
    final List<ExercisePath> filtered = all.where((ExercisePath ex) {
      // A. Tokenized Search Logic (Fuzzy search)
      // Allows for queries like "bench chest" to find "Chest - Bench Press"
      if (query.isNotEmpty) {
        final List<String> tokens = query
            .split(' ')
            .where((String t) => t.isNotEmpty)
            .toList();
        final String searchBlob =
            '${ex.exerciseName} ${ex.id} ${ex.muscleSegment} ${ex.equipmentSegment}'
                .toLowerCase();

        // Match ONLY if EVERY token typed by the user exists somewhere in the exercise data.
        if (!tokens.every(searchBlob.contains)) return false;
      }

      // B. WorkoutType (Strength / Cardio / Stretch) logic.
      if (type != null) {
        if (type == WorkoutType.strength) {
          if (ex.muscleSegment == 'Cardio' || ex.equipmentSegment == 'Stretch') {
            return false;
          }
        } else if (type == WorkoutType.cardio) {
          if (ex.muscleSegment != 'Cardio') return false;
        } else if (type == WorkoutType.stretch) {
          if (ex.equipmentSegment != 'Stretch') return false;
        }
      }

      // C. Muscle Group Chip logic.
      if (muscle != null && type != WorkoutType.cardio) {
        if (ex.muscleSegment.toLowerCase() != muscle.name.toLowerCase()) {
          return false;
        }
      }

      // D. Equipment Chip logic.
      if (equip != null && type != WorkoutType.stretch) {
        if (ex.equipmentSegment.toLowerCase() != equip.name.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    // 4. APPLY SORTING (Favorites first, then Alphabetical)
    filtered.sort((ExercisePath a, ExercisePath b) {
      final bool isAFavorite = favorites.contains(int.parse(a.id));
      final bool isBFavorite = favorites.contains(int.parse(b.id));

      if (isAFavorite && !isBFavorite) return -1;
      if (!isAFavorite && isBFavorite) return 1;
      return a.exerciseName.compareTo(b.exerciseName);
    });

    return filtered;
  }, debugLabel: 'cFilteredExercises');

  /// -- UI HELPER SIGNALS --
  /// These signals decide which UI elements (like Muscle Chips) should be visible.

  late final Computed<bool> sShowMuscleGroups = computed(() {
    final WorkoutType? type = sSelectedWorkoutType.value;
    return type == WorkoutType.strength || type == WorkoutType.stretch;
  }, debugLabel: 'sShowMuscleGroups');

  late final Computed<bool> sShowEquipment = computed(() {
    final WorkoutType? type = sSelectedWorkoutType.value;
    return type == WorkoutType.strength || type == WorkoutType.cardio;
  }, debugLabel: 'sShowEquipment');
}

// THE "BRAIN" - Global instance of the service logic.
final FilterService filterService = FilterService();

/// COMPATIBILITY REDIRECTS
/// These ensure your existing UI files (which watch these signals) do not break.
Signal<WorkoutType?> get sSelectedWorkoutType =>
    filterService.sSelectedWorkoutType;
Signal<MuscleGroup?> get sSelectedMuscleGroup =>
    filterService.sSelectedMuscleGroup;
Signal<Equipment?> get sSelectedEquipment => filterService.sSelectedEquipment;
Signal<String> get sSearchQuery => filterService.sSearchQuery;
