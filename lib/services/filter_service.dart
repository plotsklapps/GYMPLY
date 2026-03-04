import 'package:flutter/services.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/loading_signal.dart';
import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

part 'filter_service.g.dart';

// -- Enums for ChoiceChips in SearchScreen --
@HiveType(typeId: 9)
enum WorkoutType {
  @HiveField(0)
  strength,
  @HiveField(1)
  cardio,
  @HiveField(2)
  stretch,
}

@HiveType(typeId: 7)
enum MuscleGroup {
  @HiveField(0)
  fullbody,
  @HiveField(1)
  chest,
  @HiveField(2)
  back,
  @HiveField(3)
  legs,
  @HiveField(4)
  shoulders,
  @HiveField(5)
  biceps,
  @HiveField(6)
  triceps,
  @HiveField(7)
  abs,
  @HiveField(8)
  forearms,
  @HiveField(9)
  neck,
}

@HiveType(typeId: 8)
enum Equipment {
  @HiveField(0)
  bodyweight,
  @HiveField(1)
  barbell,
  @HiveField(2)
  dumbbell,
  @HiveField(3)
  machine,
  @HiveField(4)
  cable,
  @HiveField(5)
  ezbar,
  @HiveField(6)
  smith,
  @HiveField(7)
  kettlebell,
  @HiveField(8)
  band,
  @HiveField(9)
  plate,
  @HiveField(10)
  medicineball,
  @HiveField(11)
  landmine,
  @HiveField(12)
  powersled,
  @HiveField(13)
  safetybar,
  @HiveField(14)
  trapbar,
  @HiveField(15)
  stretch,
}

enum StrengthEquipment {
  bodyweight,
  barbell,
  dumbbell,
  machine,
  cable,
  ezbar,
  smith,
  kettlebell,
  band,
  plate,
  medicineball,
  landmine,
  powersled,
  safetybar,
  trapbar,
}

enum CardioEquipment {
  bodyweight,
  machine,
  kettlebell,
  medicineball,
}

// Signal<WorkoutType?> to track current selected type.
final Signal<WorkoutType?> sSelectedWorkoutType = Signal<WorkoutType?>(
  null,
  debugLabel: 'sSelectedWorkoutType',
);

// Signal<MuscleGroup?> to track selected muscle group.
final Signal<MuscleGroup?> sSelectedMuscleGroup = Signal<MuscleGroup?>(
  null,
  debugLabel: 'sSelectedMuscleGroup',
);

// Signal<Equipment?> to track selected equipment.
final Signal<Equipment?> sSelectedEquipment = Signal<Equipment?>(
  null,
  debugLabel: 'sSelectedEquipment',
);

// Metadata for exercise parsed from asset path.
class ExercisePath {
  ExercisePath({
    required this.fullPath,
    required this.id,
    required this.muscleSegment,
    required this.equipmentSegment,
    required this.exerciseName,
  });
  final String fullPath;
  final String id;
  final String muscleSegment;
  final String equipmentSegment;
  final String exerciseName;
}

class FilterService {
  // Create a singleton instance of FilterService.
  factory FilterService() {
    return _instance;
  }
  FilterService._internal();
  static final FilterService _instance = FilterService._internal();

  // Initialize Logger for debugging purposes.
  final Logger _logger = Logger();

  // --- Data Signals ---
  final Signal<List<ExercisePath>> sAllExercisePaths =
      Signal<List<ExercisePath>>(
        <ExercisePath>[],
        debugLabel: 'sAllExercisePaths',
      );

  // Initialize FilterService by loading and parsing the AssetManifest.
  Future<void> init() async {
    sLoading.value = true;

    try {
      // Use AssetManifest API.
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );

      // Get all assets from the manifest.
      final List<String> allAssets = manifest.listAssets();

      final List<ExercisePath> parsedExercisePaths = <ExercisePath>[];

      for (final String path in allAssets) {
        if (path.contains('images/exercises/') &&
            (path.endsWith('.webp') || path.endsWith('.png'))) {
          final String fileName = path.split('/').last.split('.').first;
          final List<String> segments = fileName.split('-');

          if (segments.length >= 4) {
            parsedExercisePaths.add(
              ExercisePath(
                fullPath: path,
                id: segments[0],
                muscleSegment: segments[1],
                equipmentSegment: segments[2],
                exerciseName: segments.sublist(3).join(' '),
              ),
            );
          }
        }
      }

      sAllExercisePaths.value = parsedExercisePaths;

      // Log the success.
      _logger.i('Loaded ${parsedExercisePaths.length} exercises.');
    } on Exception catch (e) {
      // Log the error.
      _logger.e('Error loading exercises: $e');

      // Set sAllExercises Signal to empty list.
      sAllExercisePaths.value = <ExercisePath>[];
    } finally {
      sLoading.value = false;
    }
  }

  // --- Computed Signals for Filtering ---

  // Filters exercises list based on user selections.
  late final Computed<List<ExercisePath>> cFilteredExercises = computed(() {
    final WorkoutType? workoutType = sSelectedWorkoutType.value;
    final MuscleGroup? muscleGroup = sSelectedMuscleGroup.value;
    final Equipment? equipment = sSelectedEquipment.value;
    final List<ExercisePath> allExercisePaths = sAllExercisePaths.value;
    final List<int> favorites = workoutService.sFavoriteExercises.value;

    if (workoutType == null) return <ExercisePath>[];

    final List<ExercisePath> filtered = allExercisePaths.where((
      ExercisePath ex,
    ) {
      // 1. WorkoutType Logic.
      if (workoutType == WorkoutType.strength) {
        if (ex.muscleSegment == 'Cardio' || ex.equipmentSegment == 'Stretch') {
          return false;
        }
      } else if (workoutType == WorkoutType.cardio) {
        if (ex.muscleSegment != 'Cardio') return false;
      } else if (workoutType == WorkoutType.stretch) {
        if (ex.equipmentSegment != 'Stretch') return false;
      }

      // 2. MuscleGroup Filter.
      if (muscleGroup != null) {
        if (workoutType != WorkoutType.cardio) {
          if (ex.muscleSegment.toLowerCase() !=
              muscleGroup.name.toLowerCase()) {
            return false;
          }
        }
      }

      // 3. Equipment Filter.
      if (equipment != null) {
        if (workoutType != WorkoutType.stretch) {
          if (ex.equipmentSegment.toLowerCase() !=
              equipment.name.toLowerCase()) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    // Sort: Favorites first, then alphabetically.
    filtered.sort((ExercisePath a, ExercisePath b) {
      final bool isAFavorite = favorites.contains(int.parse(a.id));
      final bool isBFavorite = favorites.contains(int.parse(b.id));

      if (isAFavorite && !isBFavorite) return -1;
      if (!isAFavorite && isBFavorite) return 1;

      return a.exerciseName.compareTo(b.exerciseName);
    });

    return filtered;
  }, debugLabel: 'cFilteredExercises');

  // --- Computed Signals for UI ---

  // Musclegroup ChoiceChips visible or not.
  late final Computed<bool> sShowMuscleGroups = computed(
    () {
      final WorkoutType? type = sSelectedWorkoutType.value;
      return type == WorkoutType.strength || type == WorkoutType.stretch;
    },
    debugLabel: 'sShowMuscleGroups',
  );

  // Equipment ChoiceChips visible or not.
  late final Computed<bool> sShowEquipment = computed(
    () {
      final WorkoutType? type = sSelectedWorkoutType.value;
      return type == WorkoutType.strength || type == WorkoutType.cardio;
    },
    debugLabel: 'sShowEquipment',
  );
}

// Globalize FilterService.
final FilterService filterService = FilterService();
