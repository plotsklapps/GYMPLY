import 'package:flutter/services.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/signals/allexercisespaths_signal.dart';
import 'package:logger/logger.dart';

// Source of truth for raw database of exercises. Reads asset manifest,
// parses file paths and populates sAllExercisePaths Signal.

class ExerciseService {
  // Singleton pattern.
  factory ExerciseService() {
    return _instance;
  }

  ExerciseService._internal();
  static final ExerciseService _instance = ExerciseService._internal();

  final Logger _logger = Logger();

  // INITIALIZATION: Load database from assets.
  Future<void> init() async {
    try {
      // Access AssetManifest to get list of all exercise images.
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );

      final List<String> allAssets = manifest.listAssets();
      final List<ExercisePath> parsedExercisePaths = <ExercisePath>[];

      // Parse file paths into structured ExercisePath Objects.
      for (final String path in allAssets) {
        if (path.contains('images/exercises/') &&
            (path.endsWith('.webp') || path.endsWith('.png'))) {
          final String fileName = path.split('/').last.split('.').first;
          final List<String> segments = fileName.split('-');

          // Segments 0: ID, 1: Muscle group, 2: Equipment, 3+: Exercise name.
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

      // Update Signal to notify all watchers.
      sAllExercisePaths.value = parsedExercisePaths;

      // Log success.
      _logger.i(
        'Loaded ${parsedExercisePaths.length} exercises into ExerciseService.',
      );
    } on Object catch (e) {
      // Log error.
      _logger.e('Failed to load exercises: $e');

      // Show toast to user.
      ToastService.showError(title: 'Failed to load exercises', subtitle: '$e');

      // Reset Signal.
      sAllExercisePaths.value = <ExercisePath>[];
    }
  }
}

// Globalize ExerciseService.
final ExerciseService exerciseService = ExerciseService();
