import 'package:flutter/material.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart' as atlas;
import 'package:gymply/models/exercise_model.dart' as gymply;
import 'package:gymply/services/atlas_mapper.dart' as mapper;

class AtlasService {
  factory AtlasService() => _instance;
  AtlasService._internal();
  // Singleton instance
  static final AtlasService _instance = AtlasService._internal();

  /// Calculates a map of [atlas.MuscleInfo] to [Color] for the heatmap
  /// based on the intensity of muscle groups used in a list of exercises.
  Map<atlas.MuscleInfo, Color> getAtlasColors(
    List<gymply.MuscleGroup> workedMuscles,
    ColorScheme colorScheme,
  ) {
    final Map<String, double> intensityMap = mapper.getAtlasIntensityMap(
      workedMuscles,
    );
    final Map<atlas.MuscleInfo, Color> atlasColors =
        <atlas.MuscleInfo, Color>{};

    if (intensityMap.isNotEmpty) {
      final double maxVal = intensityMap.values.fold(
        0,
        (double a, double b) => a > b ? a : b,
      );

      intensityMap.forEach((String id, double val) {
        final atlas.MuscleInfo element = atlas.MuscleCatalog.byIdOrThrow(id);

        // Intensity mapping logic:
        // Muscles with higher volume (val) appear as solid secondary color (alpha: 1.0).
        // Muscles with lower volume appear as fainter/translucent secondary color (alpha: 0.2).
        // This creates a heatmap effect using only the theme's secondary color.
        atlasColors[element] = colorScheme.secondary.withValues(
          alpha: (val / (maxVal == 0 ? 1.0 : maxVal)).clamp(0.2, 1.0),
        );
      });
    }

    return atlasColors;
  }
}

final AtlasService atlasService = AtlasService();
