import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/settings_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WorkoutService {
  // Create a singleton instance of WorkoutService.
  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal();

  static final WorkoutService _instance = WorkoutService._internal();

  // Initialize Logger.
  final Logger _logger = Logger();

  // Hive boxes.
  late Box<Workout> _workoutBox;
  late Box<Settings> _settingsBox;

  // Box names (prevents typos).
  static const String _workoutBoxName = 'workouts';
  static const String _settingsBoxName = 'settings';

  // Signal for ALL workout history.
  final Signal<List<Workout>> sWorkoutHistory = Signal<List<Workout>>(
    <Workout>[],
    debugLabel: 'sWorkoutHistory',
  );

  // Signal to track current active workout (defaults to today).
  final Signal<Workout> sActiveWorkout = Signal<Workout>(
    Workout(
      id: const Uuid().v4(),
      title: "Today's Workout",
      dateTime: DateTime.now(),
      totalDuration: 0,
    ),
    debugLabel: 'sActiveWorkout',
  );

  // Signal to track active exercise in ExerciseScreen.
  final Signal<WorkoutExercise?> sSelectedExercise = Signal<WorkoutExercise?>(
    null,
    debugLabel: 'sSelectedExercise',
  );

  // Signal to track favorite exercises (by id).
  final Signal<List<int>> sFavoriteExercises = Signal<List<int>>(
    <int>[],
    debugLabel: 'sFavoriteExercises',
  );

  // Initialize Hive Boxes and load today's state.
  Future<void> init() async {
    _logger.i('WorkoutService: Initializing Hive boxes and loading state');

    _workoutBox = await Hive.openBox<Workout>(_workoutBoxName);
    _settingsBox = await Hive.openBox<Settings>(_settingsBoxName);

    // Load settings.
    final Settings? settings = _settingsBox.get('settings');
    if (settings != null) {
      // Set ThemeMode.
      sDarkMode.value = settings.darkMode;
      // Set RestTimer.
      RestTimer.sInitialRestTime.value = settings.initialRestTime;
      RestTimer.sElapsedRestTime.value = settings.initialRestTime;
      // Set Favorites.
      sFavoriteExercises.value = List<int>.from(settings.favoriteExercises);
      // Set Wakelock.
      sWakelock.value = settings.isWakelock;

      // Log settings.
      _logger.i(
        'WorkoutService: Loaded settings - '
        'DarkMode: ${settings.darkMode}, '
        'RestTime: ${settings.initialRestTime}, '
        'Favorites: ${sFavoriteExercises.value.length}, '
        'Wakelock: ${settings.isWakelock}',
      );
    }

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
      TotalTimer.sElapsedTotalTime.value = todayWorkout.totalDuration;

      // Log workout for today.
      _logger.i(
        'WorkoutService: '
        "Resuming today's workout ($todayKey) with "
        '${todayWorkout.exercises.length} exercises',
      );
    } else {
      // Log no workout found.
      _logger.i(
        'WorkoutService: '
        'No workout found for today ($todayKey).',
      );
      // Reset Signal to a fresh workout.
      sActiveWorkout.value = Workout(
        id: const Uuid().v4(),
        title: "Today's Workout",
        dateTime: DateTime.now(),
        totalDuration: 0,
      );

      // Set TotalTimer to 0.
      TotalTimer.sElapsedTotalTime.value = 0;
    }

    // Auto-save active workout whenever it changes.
    effect(() async {
      // Create Workout Object.
      final Workout workout = sActiveWorkout.value;

      // Store to Hive.
      await _workoutBox.put(workout.dateKey, workout);

      // Log save.
      _logger.d('WorkoutService: Auto-saved workout for ${workout.dateKey}');
    });

    // Auto-save settings whenever they change.
    effect(() async {
      // Fetch Signal values.
      final bool darkMode = sDarkMode.value;
      final int restTime = RestTimer.sInitialRestTime.value;
      final List<int> favorites = sFavoriteExercises.value;
      final bool isWakelock = sWakelock.value;

      // Create Settings Object.
      final Settings settings = Settings(
        darkMode: darkMode,
        initialRestTime: restTime,
        favoriteExercises: favorites,
        isWakelock: isWakelock,
      );

      // Store to Hive.
      await _settingsBox.put('settings', settings);

      // Log save.
      _logger.d('WorkoutService: Auto-saved settings');
    });

    // Handle Wakelock state changes.
    effect(() async {
      final bool enabled = sWakelock.value;
      await WakelockPlus.toggle(enable: enabled);
      _logger.d('WorkoutService: Wakelock toggled to $enabled');
    });
  }

  // Toggle favorite exercise by id.
  void toggleFavorite(int exerciseId) {
    final List<int> currentFavorites = List<int>.from(sFavoriteExercises.value);
    if (currentFavorites.contains(exerciseId)) {
      // Remove from favorites.
      currentFavorites.remove(exerciseId);
      // Log removal.
      _logger.i('WorkoutService: Removed $exerciseId from favorites');
    } else {
      // Add to favorites.
      currentFavorites.add(exerciseId);
      // Log add.
      _logger.i('WorkoutService: Added $exerciseId from favorites');
    }
    // Set sFavoriteExercises Signal.
    sFavoriteExercises.value = currentFavorites;
  }

  // Finish current workout.
  Future<void> finishWorkout() async {
    // Create Workout Object.
    final Workout finalWorkout = sActiveWorkout.value.copyWith(
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );

    // Explicitly save the final state.
    await _workoutBox.put(finalWorkout.dateKey, finalWorkout);

    // Update history Signal so UI reflects the final duration/state.
    sWorkoutHistory.value = _workoutBox.values.toList();

    // Pause the timer.
    TotalTimer().pauseTimer();

    // Log the save.
    _logger.i('WorkoutService: Workout saved ${sWorkoutHistory.value.length}');
  }

  // Add exercise to sActiveWorkout Signal.
  void addExercise(ExercisePath path) {
    // Fetch latest List<WorkoutExercise> from sActiveWorkout Signal.
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    // Determine type to create correct Object.
    WorkoutExercise newExercise;

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

    // Update sActiveWorkout Signal with a new copy and snapshot current
    // timer.
    sActiveWorkout.value = sActiveWorkout.value.copyWith(
      exercises: currentExercises,
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );
  }

  // Deletes an entire exercise from the active workout.
  void deleteExercise(WorkoutExercise exercise) {
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    if (currentExercises.remove(exercise)) {
      // Update sActiveWorkout Signal with the new list.
      sActiveWorkout.value = sActiveWorkout.value.copyWith(
        exercises: currentExercises,
        totalDuration: TotalTimer.sElapsedTotalTime.value,
      );

      // If the deleted exercise was selected, clear the selection.
      if (sSelectedExercise.value == exercise) {
        sSelectedExercise.value = null;
      }

      _logger.i('WorkoutService: Deleted exercise: ${exercise.exerciseName}');
    }
  }

  // Reorder exercise within the active workout.
  void moveExercise(int oldIndex, int newIndex) {
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final WorkoutExercise item = currentExercises.removeAt(oldIndex);
    currentExercises.insert(newIndex, item);

    // Update sActiveWorkout Signal.
    sActiveWorkout.value = sActiveWorkout.value.copyWith(
      exercises: currentExercises,
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );

    _logger.i('WorkoutService: Moved exercise from $oldIndex to $newIndex');
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

    // Helper method to replace the Object inside the active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log the input.
    _logger.i(
      'WorkoutService: Strength Input Updated -> '
      'Weight: ${updatedExercise.weightInput}, '
      'Sreps: ${updatedExercise.repsInput}',
    );
  }

  // Updates input state for CardioExercise.
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

    // Helper method to replace the Object inside the active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log the input.
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
    int? intensity,
  }) {
    // Create StretchExercise Object.
    final StretchExercise updatedExercise = exercise.copyWith(
      stretchDurationInput: stretchDuration,
      restDurationInput: restDuration,
      intensityInput: intensity,
    );

    // Helper method to replace the Object inside the active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log the input.
    _logger.i(
      'WorkoutService: Stretch Input Updated -> '
      'Hold: ${updatedExercise.stretchDurationInput}',
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

    // Helper method to replace the Object inside the active workout.
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

    // Helper method to replace the Object inside the active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log the deletion.
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

    // Helper method to replace the Object inside the active workout.
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

    // Helper method to replace the Object inside the active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log deletion.
    _logger.i('WorkoutService: Deleting Cardio set');
  }

  // Add set to StretchExercise.
  void addStretchSet(
    StretchExercise exercise, {
    required Duration stretchDuration,
    required Duration restDuration,
    required Duration totalDuration,
    int? intensity,
  }) {
    // Create StretchSet Object.
    final StretchSet newSet = StretchSet(
      stretchDuration: stretchDuration,
      restDuration: restDuration,
      totalDuration: totalDuration,
      intensity: intensity,
    );

    // Add StretchSet to StretchExercise Object.
    final StretchExercise updatedExercise = exercise.copyWith(
      sets: <StretchSet>[...exercise.sets, newSet],
    );

    // Helper method to replace the Object inside the active workout.
    _replaceExercise(exercise, updatedExercise);

    // Log addition.
    _logger.i(
      'WorkoutService: Adding Stretch set - '
      '${newSet.totalDuration.inSeconds}s',
    );
  }

  // Delete set from StretchExercise.
  void deleteStretchSet(StretchExercise exercise, StretchSet set) {
    // Create updated List<StretchSet>.
    final List<StretchSet> updatedSets = List<StretchSet>.from(exercise.sets)
      ..remove(set);

    // Create updated StretchExercise Object.
    final StretchExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    // Helper method to replace the Object inside the active workout.
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
      _logger.d(
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
      // Log failure.
      _logger.w('WorkoutService: Could not find exercise to replace');
    }
  }
}

/// Custom Hive Adapter for Duration since it's not supported natively.
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
