import 'package:gymply/models/exercise_model.dart' as gymply;

// Returns a Map of SVG IDs (from MuscleCatalog) to their intensity.
Map<String, double> getAtlasIntensityMap(
  List<gymply.MuscleGroup> muscleGroups,
) {
  final Map<String, double> intensityMap = <String, double>{};

  for (final gymply.MuscleGroup group in muscleGroups) {
    final List<String> muscleIds = _mapToMuscleIds(group);
    for (final String id in muscleIds) {
      intensityMap[id] = (intensityMap[id] ?? 0.0) + 1.0;
    }
  }

  return intensityMap;
}

List<String> _mapToMuscleIds(gymply.MuscleGroup group) {
  switch (group) {
    case gymply.MuscleGroup.chest:
      return <String>['pectoralis_major_r', 'pectoralis_major_l'];
    case gymply.MuscleGroup.back:
      return <String>[
        'latissimus_dorsi_r',
        'latissimus_dorsi_l',
        'trapezius_upper_r',
        'trapezius_upper_l',
        'trapezius_middle_r',
        'trapezius_middle_l',
        'trapezius_lower_r',
        'trapezius_lower_l',
        'infraspinatus_r',
        'infraspinatus_l',
      ];
    case gymply.MuscleGroup.legs:
      return <String>[
        'rectus_femoris_r',
        'rectus_femoris_l',
        'vastus_lateralis_r',
        'vastus_lateralis_l',
        'vastus_medialis_r',
        'vastus_medialis_l',
        'biceps_femoris_r',
        'biceps_femoris_l',
        'gluteus_maximus_r',
        'gluteus_maximus_l',
        'gluteus_medius_1_r',
        'gluteus_medius_1_l',
        'gluteus_medius_2_r',
        'gluteus_medius_2_l',
        'semimembranosus_1_r',
        'semimembranosus_1_l',
        'semimembranosus_2_r',
        'semimembranosus_2_l',
        'semitendinosus_r',
        'semitendinosus_l',
        'gastrocnemius_r',
        'gastrocnemius_l',
        'tibialis_anterior_r',
        'tibialis_anterior_l',
        'sartoris_r',
        'sartoris_l',
        'gracilis_r',
        'gracilis_l',
        'adductor_magnus_r',
        'adductor_magnus_l',
        'adductor_longus_r',
        'adductor_longus_l',
        'pectineus_r',
        'pectineus_l',
        'iliotibial_tract_r',
        'iliotibial_tract_l',
      ];
    case gymply.MuscleGroup.shoulders:
      return <String>[
        'anterior_deltoid_r',
        'anterior_deltoid_l',
        'lateral_deltoid_r',
        'lateral_deltoid_l',
        'posterior_deltoid_r',
        'posterior_deltoid_l',
      ];
    case gymply.MuscleGroup.biceps:
      return <String>[
        'biceps_brachii_caput_longum_r',
        'biceps_brachii_caput_longum_l',
        'biceps_brachii_caput_breve_r',
        'biceps_brachii_caput_breve_l',
      ];
    case gymply.MuscleGroup.triceps:
      return <String>[
        'triceps_brachii_caput_laterale_r',
        'triceps_brachii_caput_laterale_l',
        'triceps_brachii_caput_longum_r',
        'triceps_brachii_caput_longum_l',
        'triceps_brachii_caput_mediale_r',
        'triceps_brachii_caput_mediale_l',
        'anconeus_r',
        'anconeus_l',
      ];
    case gymply.MuscleGroup.abs:
      return <String>[
        'rectus_abdominis_1',
        'rectus_abdominis_2_r',
        'rectus_abdominis_2_l',
        'rectus_abdominis_3_r',
        'rectus_abdominis_3_l',
        'rectus_abdominis_4_r',
        'rectus_abdominis_4_l',
        'external_oblique_r',
        'external_oblique_l',
        'external_oblique_1_r',
        'external_oblique_1_l',
        'external_oblique_2_r',
        'external_oblique_2_l',
        'external_oblique_3_r',
        'external_oblique_3_l',
        'external_oblique_4_r',
        'external_oblique_4_l',
        'external_oblique_5_r',
        'external_oblique_5_l',
        'external_oblique_6_r',
        'external_oblique_6_l',
        'external_oblique_7_r',
        'external_oblique_7_l',
        'external_oblique_8_r',
        'external_oblique_8_l',
      ];
    case gymply.MuscleGroup.forearms:
      return <String>[
        'brachioradialis_r',
        'brachioradialis_l',
        'flexor_carpi_ulnaris_r',
        'flexor_carpi_ulnaris_l',
        'flexor_carpi_radialis_r',
        'flexor_carpi_radialis_l',
        'flexor_digitorum_superficialis_r',
        'flexor_digitorum_superficialis_l',
        'extensor_carpi_ulnaris_r',
        'extensor_carpi_ulnaris_l',
        'extensor_carpi_radialis_longus_r',
        'extensor_carpi_radialis_longus_l',
        'extensor_digitorum_r',
        'extensor_digitorum_l',
        'palmaris_longus_r',
        'palmaris_longus_l',
        'pronator_teres_r',
        'pronator_teres_l',
        'pronator_quadratus_r',
        'pronator_quadratus_l',
      ];
    case gymply.MuscleGroup.neck:
      return <String>[
        'sternocleidomastoid_r',
        'sternocleidomastoid_l',
        'platysma',
        'sternohyoid',
      ];
    case gymply.MuscleGroup.fullbody:
      return <String>[];
  }
}
