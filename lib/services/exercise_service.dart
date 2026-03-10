import 'package:flutter/services.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/signals/loading_signal.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

/// -- EXERCISE DATA SERVICE --
///
/// Responsibility: Data Fetching and Raw Data Management.
/// This service is the "Source of Truth" for the raw database of exercises.
/// It reads the asset manifest, parses the file paths, and populates
/// the sAllExercisePaths signal.

class ExerciseService {
  // Singleton pattern for globally shared data.
  factory ExerciseService() => _instance;
  ExerciseService._internal();
  static final ExerciseService _instance = ExerciseService._internal();

  final Logger _logger = Logger();

  /// RAW DATA SIGNAL
  /// This holds the complete, unfiltered list of all exercises found in assets.
  final Signal<List<ExercisePath>> sAllExercisePaths =
      Signal<List<ExercisePath>>(<ExercisePath>[]);

  /// INITIALIZATION
  /// Call this when the app starts to load the database from assets.
  Future<void> init() async {
    sLoading.value = true;

    try {
      // 1. Access the AssetManifest to get a list of all exercise images.
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      final List<String> allAssets = manifest.listAssets();

      final List<ExercisePath> parsedExercisePaths = <ExercisePath>[];

      // 2. Parse file paths into structured ExercisePath objects.
      // Expected format: .../00011101-Abs-Bodyweight-3-Quarter-Sit-Up.png
      for (final String path in allAssets) {
        if (path.contains('images/exercises/') &&
            (path.endsWith('.webp') || path.endsWith('.png'))) {
          final String fileName = path.split('/').last.split('.').first;
          final List<String> segments = fileName.split('-');

          // Segments 0: ID, 1: Muscle, 2: Equipment, 3+: Name words
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

      // 3. Update the signal to notify any watchers (like FilterService).
      sAllExercisePaths.value = parsedExercisePaths;
      _logger.i(
        'Loaded ${parsedExercisePaths.length} exercises into ExerciseService.',
      );
    } catch (e) {
      _logger.e('Failed to load exercises: $e');
      sAllExercisePaths.value = <ExercisePath>[];
    } finally {
      sLoading.value = false;
    }
  }
}

// Global instance of the service.
final ExerciseService exerciseService = ExerciseService();
