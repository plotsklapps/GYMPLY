import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/personalrecord_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/hive_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/signals/selectedexercise_signal.dart';
import 'package:gymply/signals/workouthistory_signal.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

// Central provider managing state and logic of active and completed
// workouts. It knows how to train.
//
// init(): Set up the active session (resume today's workout or create
//         fresh one) and sync timer.

class WorkoutService {
  // Singleton pattern.
  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal();
  static final WorkoutService _instance = WorkoutService._internal();

  final Logger _logger = Logger();

  // Hive boxes.
  late Box<Workout> _workoutBox;

  // Initialize Hive Boxes and load today's state.
  Future<void> init() async {
    // Log status.
    _logger.i('WorkoutService: Initializing Hive boxes and loading state');

    // Retrieve Hive boxes from HiveService.
    _workoutBox = hiveService.workoutBox;

    // Load all workouts into sWorkoutHistory Signal.
    sWorkoutHistory.value = _workoutBox.values.toList();

    // Log workout history list length.
    _logger.i(
      'WorkoutService: Loaded '
      '${sWorkoutHistory.value.length} workouts from history',
    );

    // Check if there's a workout for today.
    final String todayKey = DateFormat('yyyyMMdd').format(DateTime.now());
    final Workout? todayWorkout = _workoutBox.get(todayKey);

    if (todayWorkout != null) {
      // Set today's workout to the active workout.
      sActiveWorkout.value = todayWorkout;

      // Set the total timer to the workout's total duration.
      TotalTimer().syncTotalTime(todayWorkout.totalDuration);

      // Log workout for today.
      _logger.i(
        'WorkoutService: '
        'Resuming current session ($todayKey) with '
        '${todayWorkout.exercises.length} exercises',
      );
    } else {
      // Log no workout found.
      _logger.i(
        'WorkoutService: '
        'No workout found for current date ($todayKey).',
      );
      // Reset Signal to a fresh workout.
      sActiveWorkout.value = Workout(
        id: const Uuid().v4(),
        title: DateTime.now().defaultWorkoutTitle,
        dateTime: DateTime.now(),
        totalDuration: 0,
      );

      // Set TotalTimer to 0.
      TotalTimer().syncTotalTime(0);
    }

    // Auto-save active workout whenever it changes.
    effect(() async {
      // Create Workout Object.
      final Workout workout = sActiveWorkout.value;

      // Only auto-save if workout is "real".
      if (workout.exercises.isNotEmpty || workout.totalDuration > 0) {
        // Store to Hive.
        await _workoutBox.put(workout.dateKey, workout);

        // Update history Signal so Statistics reflects changes.
        sWorkoutHistory.value = _workoutBox.values.toList();

        // Log success.
        _logger.i('WorkoutService: Auto-saved workout for ${workout.dateKey}');
      } else {
        // Log warning.
        _logger.w('WorkoutService: Skipping auto-save for empty template.');
      }
    });
  }

  // Finish current workout.
  Future<void> finishWorkout({
    String? title,
    String? notes,
    List<String>? imagePaths,
  }) async {
    try {
      // Create Workout Object.
      final Workout finalWorkout = sActiveWorkout.value.copyWith(
        title: title,
        totalDuration: TotalTimer.sElapsedTotalTime.value,
        notes: notes,
        imagePaths: imagePaths,
      );

      // Update the active workout signal so state is preserved.
      sActiveWorkout.value = finalWorkout;

      // Explicitly save FINAL state to Hive.
      await _workoutBox.put(finalWorkout.dateKey, finalWorkout);

      // Update history Signal so UI reflects FINAL duration/state.
      sWorkoutHistory.value = _workoutBox.values.toList();

      // Pause timer.
      await TotalTimer().pauseTimer();

      // Log success.
      _logger.i(
        'WorkoutService: Workout saved ${sWorkoutHistory.value.length}',
      );

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Workout saved',
        subtitle: 'Your workout data has been securely stored to your device.',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'WorkoutService: Failed to finish workout',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Workout Error',
        subtitle: 'Failed to save workout.',
      );
    }
  }

  // Delete workout by dateKey.
  Future<void> deleteWorkout(String dateKey) async {
    try {
      // Remove from Hive.
      await _workoutBox.delete(dateKey);

      // Update history Signal.
      sWorkoutHistory.value = _workoutBox.values.toList();

      // If it was in active workout, reset it.
      if (sActiveWorkout.value.dateKey == dateKey) {
        sActiveWorkout.value = Workout(
          id: const Uuid().v4(),
          title: DateTime.now().defaultWorkoutTitle,
          dateTime: DateTime.now(),
          totalDuration: 0,
        );
        // Reset total timer.
        TotalTimer().syncTotalTime(0);
      }

      // Log success.
      _logger.i('WorkoutService: Workout $dateKey deleted.');

      // Show toast to user.
      ToastService.showSuccess(
        title: 'Workout deleted',
        subtitle: 'The workout has been removed from your history.',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'WorkoutService: Failed to delete workout',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Workout Error',
        subtitle: 'Failed to delete workout.',
      );
    }
  }

  // Add exercise to sActiveWorkout Signal.
  void addExercise(ExercisePath path) {
    // Fetch latest List<WorkoutExercise> from sActiveWorkout Signal.
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    WorkoutExercise newExercise;

    // Determine type to create correct Object.
    final bool isCardio = path.muscleSegment == 'Cardio';
    final bool isStretch = path.equipmentSegment == 'Stretch';

    if (isCardio) {
      newExercise = CardioExercise(
        id: int.parse(path.id),
        exerciseName: path.exerciseName,
        imagePath: path.fullPath,
        equipment: Equipment.values.byName(path.equipmentSegment.toLowerCase()),
        sets: <CardioSet>[],
      );

      // Log exercise addition.
      _logger.i('WorkoutService: Adding exercise: ${path.exerciseName}');
    } else if (isStretch) {
      newExercise = StretchExercise(
        id: int.parse(path.id),
        exerciseName: path.exerciseName,
        imagePath: path.fullPath,
        sets: <StretchSet>[],
      );

      // Log exercise addition.
      _logger.i('WorkoutService: Adding exercise: ${path.exerciseName}');
    } else {
      newExercise = StrengthExercise(
        id: int.parse(path.id),
        exerciseName: path.exerciseName,
        imagePath: path.fullPath,
        muscleGroup: MuscleGroup.values.byName(
          path.muscleSegment.toLowerCase(),
        ),
        equipment: Equipment.values.byName(path.equipmentSegment.toLowerCase()),
        sets: <StrengthSet>[],
      );

      // Log exercise addition.
      _logger.i('WorkoutService: Adding exercise: ${path.exerciseName}');
    }

    // Add Object to currentExercises List.
    currentExercises.add(newExercise);

    // Update sActiveWorkout Signal with new copy and snapshot current timer.
    sActiveWorkout.value = sActiveWorkout.value.copyWith(
      exercises: currentExercises,
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );
  }

  // Delete exercise from the active workout.
  void deleteExercise(WorkoutExercise exercise) {
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    if (currentExercises.remove(exercise)) {
      // Update sActiveWorkout Signal with new list.
      sActiveWorkout.value = sActiveWorkout.value.copyWith(
        exercises: currentExercises,
        totalDuration: TotalTimer.sElapsedTotalTime.value,
      );

      // If the deleted exercise was selected, clear selection.
      if (sSelectedExercise.value == exercise) {
        sSelectedExercise.value = null;
      }

      // Log success.
      _logger.i('WorkoutService: Deleted exercise: ${exercise.exerciseName}');
    }
  }

  // Reorder exercise within active workout.
  void moveExercise(int oldIndex, int newIndex) {
    int adjustedNewIndex = newIndex;
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    if (adjustedNewIndex > oldIndex) {
      adjustedNewIndex -= 1;
    }

    final WorkoutExercise item = currentExercises.removeAt(oldIndex);
    currentExercises.insert(adjustedNewIndex, item);

    // Update sActiveWorkout Signal.
    sActiveWorkout.value = sActiveWorkout.value.copyWith(
      exercises: currentExercises,
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );

    // Log success.
    _logger.i(
      'WorkoutService: Moved exercise from $oldIndex to $adjustedNewIndex',
    );
  }

  // Update input state for StrengthExercise.
  void updateStrengthInput(
    StrengthExercise exercise, {
    double? weight,
    int? reps,
  }) {
    // Create StrengthExercise Object.
    final StrengthExercise updatedExercise = exercise.copyWith(
      weightInput: weight,
      repsInput: reps,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log input.
    _logger.i(
      'WorkoutService: Strength Input Updated -> '
      'Weight: ${updatedExercise.weightInput}, '
      'Sreps: ${updatedExercise.repsInput}',
    );
  }

  // Update input state for CardioExercise.
  void updateCardioInput(
    CardioExercise exercise, {
    Duration? cardioDuration,
    Duration? restDuration,
    double? distance,
    int? calories,
    int? intensity,
  }) {
    // Create CardioExercise Object.
    final CardioExercise updatedExercise = exercise.copyWith(
      cardioDurationInput: cardioDuration,
      restDurationInput: restDuration,
      distanceInput: distance,
      caloriesInput: calories,
      intensityInput: intensity,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log input.
    _logger.i(
      'WorkoutService: Cardio Input Updated -> '
      'Duration: ${updatedExercise.cardioDurationInput}, '
      'RestDuration: ${updatedExercise.restDurationInput}, '
      'Distance: ${updatedExercise.distanceInput}'
      'Calories: ${updatedExercise.caloriesInput}, '
      'Intensity: ${updatedExercise.intensityInput}, ',
    );
  }

  // Update input state for StretchExercise.
  void updateStretchInput(
    StretchExercise exercise, {
    Duration? stretchDuration,
    Duration? restDuration,
    int? calories,
    int? intensity,
  }) {
    // Create StretchExercise Object.
    final StretchExercise updatedExercise = exercise.copyWith(
      stretchDurationInput: stretchDuration,
      restDurationInput: restDuration,
      caloriesInput: calories,
      intensityInput: intensity,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log input.
    _logger.i(
      'WorkoutService: Stretch Input Updated -> '
      'Hold: ${updatedExercise.stretchDurationInput}, '
      'Rest: ${updatedExercise.restDurationInput}, '
      'Calories: ${updatedExercise.caloriesInput}, '
      'Intensity: ${updatedExercise.intensityInput}',
    );
  }

  // Add set to StrengthExercise Object.
  void addStrengthSet(StrengthExercise exercise, double weight, int reps) {
    // Create StrengthSet Object.
    final StrengthSet newSet = StrengthSet(weight: weight, reps: reps);
    // Add StrengthSet to StrengthExercise.
    final StrengthExercise updatedExercise = exercise.copyWith(
      sets: <StrengthSet>[...exercise.sets, newSet],
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log addition.
    _logger.i('WorkoutService: Adding Strength set - $weight kg x $reps reps');
  }

  // Delete set from StrengthExercise Object.
  void deleteStrengthSet(StrengthExercise exercise, StrengthSet set) {
    // Create updated List<StrengthSet>.
    final List<StrengthSet> updatedSets = List<StrengthSet>.from(exercise.sets)
      ..remove(set);

    // Create updated StrengthExercise Object.
    final StrengthExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log deletion.
    _logger.i('WorkoutService: Deleting Strength set');
  }

  // Add set to CardioExercise.
  void addCardioSet(
    CardioExercise exercise, {
    required Duration cardioDuration,
    required Duration restDuration,
    required Duration totalDuration,
    double? distance,
    int? calories,
    int? intensity,
  }) {
    // Create CardioSet Object.
    final CardioSet newSet = CardioSet(
      cardioDuration: cardioDuration,
      restDuration: restDuration,
      totalDuration: totalDuration,
      distance: distance,
      calories: calories,
      intensity: intensity,
    );

    // Add CardioSet to CardioExercise.
    final CardioExercise updatedExercise = exercise.copyWith(
      sets: <CardioSet>[...exercise.sets, newSet],
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log addition.
    _logger.i(
      'WorkoutService: Adding Cardio set - '
      '${newSet.totalDuration.inSeconds}s',
    );
  }

  // Delete set from CardioExercise.
  void deleteCardioSet(CardioExercise exercise, CardioSet set) {
    // Create updated Llist<CardioSet>.
    final List<CardioSet> updatedSets = List<CardioSet>.from(exercise.sets)
      ..remove(set);

    // Create updated CardioExercise Object.
    final CardioExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log deletion.
    _logger.i('WorkoutService: Deleting Cardio set');
  }

  // Update set in CardioExercise.
  void updateCardioSet(
    CardioExercise exercise,
    CardioSet oldSet, {
    Duration? cardioDuration,
    Duration? restDuration,
    Duration? totalDuration,
    double? distance,
    int? calories,
    int? intensity,
  }) {
    // Find index of set to update.
    final int index = exercise.sets.indexOf(oldSet);
    if (index == -1) return;

    // Create new CardioSet Object with updated values.
    final CardioSet newSet = CardioSet(
      cardioDuration: cardioDuration ?? oldSet.cardioDuration,
      restDuration: restDuration ?? oldSet.restDuration,
      totalDuration: totalDuration ?? oldSet.totalDuration,
      distance: distance ?? oldSet.distance,
      calories: calories ?? oldSet.calories,
      intensity: intensity ?? oldSet.intensity,
    );

    // Create updated List<CardioSet> and replace Object.
    final List<CardioSet> updatedSets = List<CardioSet>.from(exercise.sets);
    updatedSets[index] = newSet;

    // Create updated CardioExercise Object.
    final CardioExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log update.
    _logger.i('WorkoutService: Updated Cardio set');
  }

  // Add set to StretchExercise.
  void addStretchSet(
    StretchExercise exercise, {
    required Duration stretchDuration,
    required Duration restDuration,
    required Duration totalDuration,
    int? calories,
    int? intensity,
  }) {
    // Create StretchSet Object.
    final StretchSet newSet = StretchSet(
      stretchDuration: stretchDuration,
      restDuration: restDuration,
      totalDuration: totalDuration,
      calories: calories,
      intensity: intensity,
    );

    // Add StretchSet to StretchExercise Object.
    final StretchExercise updatedExercise = exercise.copyWith(
      sets: <StretchSet>[...exercise.sets, newSet],
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log addition.
    _logger.i(
      'WorkoutService: Adding Stretch set - '
      '${newSet.totalDuration.inSeconds}s',
    );
  }

  // Update set in StretchExercise.
  void updateStretchSet(
    StretchExercise exercise,
    StretchSet oldSet, {
    Duration? stretchDuration,
    Duration? restDuration,
    Duration? totalDuration,
    int? calories,
    int? intensity,
  }) {
    // Find index of set to update.
    final int index = exercise.sets.indexOf(oldSet);
    if (index == -1) return;

    // Create new StretchSet Object with updated values.
    final StretchSet newSet = StretchSet(
      stretchDuration: stretchDuration ?? oldSet.stretchDuration,
      restDuration: restDuration ?? oldSet.restDuration,
      totalDuration: totalDuration ?? oldSet.totalDuration,
      calories: calories ?? oldSet.calories,
      intensity: intensity ?? oldSet.intensity,
    );

    // Create updated List<StretchSet> and replace Object.
    final List<StretchSet> updatedSets = List<StretchSet>.from(exercise.sets);
    updatedSets[index] = newSet;

    // Create updated StretchExercise Object.
    final StretchExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log update.
    _logger.i('WorkoutService: Updated Stretch set');
  }

  // Delete set from StretchExercise.
  void deleteStretchSet(StretchExercise exercise, StretchSet set) {
    // Create updated List<StretchSet>.
    final List<StretchSet> updatedSets = List<StretchSet>.from(exercise.sets)
      ..remove(set);

    // Create updated StretchExercise Object.
    final WorkoutExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    // Helper method to replace Object inside active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log deletion.
    _logger.i('WorkoutService: Deleting Stretch set');
  }

  // Helper to replace exercise instance in active workout.
  void _replaceExercise(WorkoutExercise oldEx, WorkoutExercise newEx) {
    // Create new List<WorkoutExercises>.
    final List<WorkoutExercise> exercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    final int index = exercises.indexOf(oldEx);
    if (index != -1) {
      // Log replacement.
      _logger.i(
        'WorkoutService: Replacing exercise instance: ${oldEx.exerciseName}',
      );

      // Replace Object.
      exercises[index] = newEx;

      // Update sActiveWorkout Signal and snapshot timer.
      sActiveWorkout.value = sActiveWorkout.value.copyWith(
        exercises: exercises,
        totalDuration: TotalTimer.sElapsedTotalTime.value,
      );

      // Sync selection to new Object.
      sSelectedExercise.value = newEx;
    } else {
      // Log warning.
      _logger.w('WorkoutService: Could not find exercise to replace');
    }
  }

  // Copy a workout to today's active session.
  void copyWorkoutToToday(
    Workout workoutToCopy, {
    required bool merge,
    required bool keepValues,
    required bool addTime,
  }) {
    final List<WorkoutExercise> exercisesToAdd = <WorkoutExercise>[];

    for (final WorkoutExercise ex in workoutToCopy.exercises) {
      if (keepValues) {
        exercisesToAdd.add(ex.copyWith());
      } else {
        if (ex is StrengthExercise) {
          exercisesToAdd.add(
            ex.copyWith(
              sets: <StrengthSet>[],
            ),
          );
        } else if (ex is CardioExercise) {
          exercisesToAdd.add(
            ex.copyWith(
              sets: <CardioSet>[],
            ),
          );
        } else if (ex is StretchExercise) {
          exercisesToAdd.add(
            ex.copyWith(
              sets: <StretchSet>[],
            ),
          );
        } else {
          exercisesToAdd.add(ex.copyWith());
        }
      }
    }

    final List<WorkoutExercise> newExercises = <WorkoutExercise>[];
    if (merge) {
      newExercises
        ..addAll(sActiveWorkout.value.exercises)
        ..addAll(exercisesToAdd);
    } else {
      newExercises.addAll(exercisesToAdd);
    }

    // Prevent doubling duration if we are copying today's workout to itself.
    final bool isSameWorkout = workoutToCopy.id == sActiveWorkout.value.id;
    final int durationToAdd = isSameWorkout ? 0 : workoutToCopy.totalDuration;

    final int newTotalDuration = addTime
        ? TotalTimer.sElapsedTotalTime.value + durationToAdd
        : workoutToCopy.totalDuration;

    sActiveWorkout.value = sActiveWorkout.value.copyWith(
      exercises: newExercises,
      totalDuration: newTotalDuration,
    );

    // Update TotalTimer correctly (handling running state).
    TotalTimer().syncTotalTime(newTotalDuration);

    ToastService.showSuccess(
      title: 'Workout Copied',
      subtitle: 'Successfully copied to today.',
    );

    // Log success.
    _logger.i(
      'WorkoutService: Workout copied. '
      'Merge: $merge, KeepValues: $keepValues, AddTime: $addTime',
    );
  }

  // Calculates Personal Records for a specific Exercise ID.
  // If [includeActive] is false, it only considers historical workouts.
  PersonalRecord getPersonalRecords(
    int exerciseId, {
    bool includeActive = true,
  }) {
    // Strength PRs.
    double maxWeight = 0;
    double maxSetVolume = 0;
    double maxExerciseVolume = 0;
    double maxLombardi = 0;
    double maxBrzycki = 0;
    double maxEpley = 0;

    // Cardio PRs.
    Duration maxSetDurationCardio = Duration.zero;
    double maxDistance = 0;
    Duration maxTotalDurationCardio = Duration.zero;

    // Stretch PRs.
    Duration maxSetDurationStretch = Duration.zero;
    int maxExerciseStretches = 0;
    Duration maxTotalDurationStretch = Duration.zero;

    // Helper to update PR values from a single exercise instance.
    void processExercise(WorkoutExercise exercise) {
      if (exercise is StrengthExercise) {
        // Track max exercise volume.
        if (exercise.totalWeight > maxExerciseVolume) {
          maxExerciseVolume = exercise.totalWeight;
        }

        // Track max weight, set volume, and calculated 1RMs.
        for (final StrengthSet set in exercise.sets) {
          if (set.weight > maxWeight) {
            maxWeight = set.weight;
          }
          final double setVolume = set.weight * set.reps;
          if (setVolume > maxSetVolume) {
            maxSetVolume = setVolume;
          }

          if (set.reps > 0) {
            if (set.oneRepMaxLombardi > maxLombardi) {
              maxLombardi = set.oneRepMaxLombardi;
            }
            if (set.oneRepMaxBrzycki > maxBrzycki) {
              maxBrzycki = set.oneRepMaxBrzycki;
            }
            if (set.oneRepMaxEpley > maxEpley) {
              maxEpley = set.oneRepMaxEpley;
            }
          }
        }
      } else if (exercise is CardioExercise) {
        // Track max total duration.
        if (exercise.totalDuration > maxTotalDurationCardio) {
          maxTotalDurationCardio = exercise.totalDuration;
        }

        // Track max set duration and distance.
        for (final CardioSet set in exercise.sets) {
          if (set.cardioDuration > maxSetDurationCardio) {
            maxSetDurationCardio = set.cardioDuration;
          }
          if ((set.distance ?? 0) > maxDistance) {
            maxDistance = set.distance!;
          }
        }
      } else if (exercise is StretchExercise) {
        // Track max total duration and max stretches per session.
        if (exercise.totalDuration > maxTotalDurationStretch) {
          maxTotalDurationStretch = exercise.totalDuration;
        }
        if (exercise.sets.length > maxExerciseStretches) {
          maxExerciseStretches = exercise.sets.length;
        }

        // Track max set (hold) duration.
        for (final StretchSet set in exercise.sets) {
          if (set.stretchDuration > maxSetDurationStretch) {
            maxSetDurationStretch = set.stretchDuration;
          }
        }
      }
    }

    // Iterate through all workouts in history.
    for (final Workout workout in sWorkoutHistory.value) {
      // Skip active workout if requested.
      if (!includeActive && workout.id == sActiveWorkout.value.id) continue;

      for (final WorkoutExercise exercise in workout.exercises) {
        if (exercise.id == exerciseId) {
          processExercise(exercise);
        }
      }
    }

    // Manually process active workout if requested and not yet in history.
    if (includeActive) {
      final Workout active = sActiveWorkout.value;
      for (final WorkoutExercise exercise in active.exercises) {
        if (exercise.id == exerciseId) {
          processExercise(exercise);
        }
      }
    }

    return PersonalRecord(
      // Strength.
      maxWeight: maxWeight,
      maxSetVolume: maxSetVolume,
      maxExerciseVolume: maxExerciseVolume,
      oneRepMaxLombardi: maxLombardi,
      oneRepMaxBrzycki: maxBrzycki,
      oneRepMaxEpley: maxEpley,
      // Cardio.
      maxSetDuration: maxSetDurationCardio.inSeconds > 0
          ? maxSetDurationCardio
          : maxSetDurationStretch,
      maxDistance: maxDistance,
      maxTotalDuration: maxTotalDurationCardio.inSeconds > 0
          ? maxTotalDurationCardio
          : maxTotalDurationStretch,
      // Stretch.
      maxExerciseStretches: maxExerciseStretches,
    );
  }

  // Return list of PRs achieved in given workout.
  List<Map<String, dynamic>> getWorkoutPRs(Workout workout) {
    final List<Map<String, dynamic>> prs = <Map<String, dynamic>>[];
    for (final WorkoutExercise exercise in workout.exercises) {
      // Fetch best values achieved PRIOR to this workout.
      final PersonalRecord historicalPR = getPersonalRecords(
        exercise.id,
        includeActive: false,
      );

      if (exercise is StrengthExercise) {
        double maxWeightInSession = 0;
        double maxSetVolInSession = 0;

        // Calculate session peaks.
        for (final StrengthSet set in exercise.sets) {
          if (set.weight > maxWeightInSession) {
            maxWeightInSession = set.weight;
          }
          final double vol = set.weight * set.reps;
          if (vol > maxSetVolInSession) {
            maxSetVolInSession = vol;
          }
        }

        // Check for max weight PR.
        if (maxWeightInSession > historicalPR.maxWeight) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'REP',
            'value': maxWeightInSession,
          });
        }

        // Check for set volume PR.
        if (maxSetVolInSession > historicalPR.maxSetVolume) {
          final StrengthSet volSet = exercise.sets.firstWhere(
            (StrengthSet s) {
              return (s.weight * s.reps) == maxSetVolInSession;
            },
          );
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'SET',
            'value': maxSetVolInSession,
            'weight': volSet.weight,
            'reps': volSet.reps,
          });
        }

        // Check for total exercise volume PR.
        if (exercise.totalWeight > historicalPR.maxExerciseVolume) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'TOTAL',
            'value': exercise.totalWeight,
          });
        }
      } else if (exercise is CardioExercise) {
        Duration maxSetDur = Duration.zero;
        double maxDist = 0;

        // Calculate session peaks.
        for (final CardioSet set in exercise.sets) {
          if (set.cardioDuration > maxSetDur) maxSetDur = set.cardioDuration;
          if ((set.distance ?? 0) > maxDist) maxDist = set.distance!;
        }

        // Check for set duration PR.
        if (maxSetDur > historicalPR.maxSetDuration) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'TIME',
            'value': maxSetDur,
          });
        }

        // Check for distance PR.
        if (maxDist > historicalPR.maxDistance && maxDist > 0) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'DIST',
            'value': maxDist,
          });
        }

        // Check for total duration PR.
        if (exercise.totalDuration > historicalPR.maxTotalDuration) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'TOTAL',
            'value': exercise.totalDuration,
          });
        }
      } else if (exercise is StretchExercise) {
        Duration maxSetDur = Duration.zero;

        // Calculate session peaks.
        for (final StretchSet set in exercise.sets) {
          if (set.stretchDuration > maxSetDur) maxSetDur = set.stretchDuration;
        }

        // Check for set duration (hold) PR.
        if (maxSetDur > historicalPR.maxSetDuration) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'HOLD',
            'value': maxSetDur,
          });
        }

        // Check for set count PR.
        if (exercise.sets.length > historicalPR.maxExerciseStretches) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'SETS',
            'value': exercise.sets.length,
          });
        }

        // Check for total duration PR.
        if (exercise.totalDuration > historicalPR.maxTotalDuration) {
          prs.add(<String, dynamic>{
            'exercise': exercise,
            'exerciseName': exercise.exerciseName,
            'type': 'TOTAL',
            'value': exercise.totalDuration,
          });
        }
      }
    }
    return prs;
  }
}

// Custom Hive Adapter for Duration since it's not supported natively.
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 10;

  @override
  Duration read(BinaryReader reader) {
    return Duration(microseconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}

// Globalize WorkoutService.
final WorkoutService workoutService = WorkoutService();
