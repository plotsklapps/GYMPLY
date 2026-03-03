import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutService {
  // Create a singleton instance of WorkoutService.
  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal();

  static final WorkoutService _instance = WorkoutService._internal();

  // Initialize Logger.
  final Logger _logger = Logger();

  // Box names.
  static const String _workoutBoxName = 'workout_history';
  static const String _activeWorkoutBoxName = 'active_session';

  late Box<Workout> _historyBox;
  late Box<Workout> _activeBox;

  // Signal for workout history.
  final Signal<List<Workout>> sWorkoutHistory = signal<List<Workout>>(
    <Workout>[],
    debugLabel: 'sWorkoutHistory',
  );

  // Current active workout session Signal.
  final Signal<Workout> sActiveWorkout = signal<Workout>(
    Workout(
      id: const Uuid().v4(),
      title: "Today's Workout",
      dateTime: DateTime.now(),
      totalDuration: 0,
    ),
    debugLabel: 'sActiveWorkout',
  );

  // Track which exercise is currently being edited/viewed in ExerciseScreen.
  final Signal<WorkoutExercise?> sSelectedExercise = signal<WorkoutExercise?>(
    null,
    debugLabel: 'sSelectedExercise',
  );

  /// Initialize Hive boxes and load data.
  Future<void> init() async {
    _logger.i('WorkoutService: Initializing Hive boxes and loading state');

    _historyBox = await Hive.openBox<Workout>(_workoutBoxName);
    _activeBox = await Hive.openBox<Workout>(_activeWorkoutBoxName);

    // Load history into signal.
    sWorkoutHistory.value = _historyBox.values.toList();
    _logger.i(
      'WorkoutService: Loaded ${sWorkoutHistory.value.length} workouts from history',
    );

    // 1. Check if there's an ongoing workout in the active box.
    final Workout? savedActive = _activeBox.get('current');
    if (savedActive != null) {
      _logger.i(
        'WorkoutService: Found unfinished active session. Resuming workout with ${savedActive.exercises.length} exercises...',
      );
      sActiveWorkout.value = savedActive;
      TotalTimer.sElapsedTotalTime.value = savedActive.totalDuration;
    }
    // 2. If no active session, check history for today.
    else {
      final String todayKey = DateFormat('yyyyMMdd').format(DateTime.now());
      final Workout? todayWorkout = _historyBox.get(todayKey);
      if (todayWorkout != null) {
        _logger.i(
          'WorkoutService: Resuming today\'s completed workout from history with ${todayWorkout.exercises.length} exercises',
        );
        sActiveWorkout.value = todayWorkout;
        TotalTimer.sElapsedTotalTime.value = todayWorkout.totalDuration;
      }
    }

    // Auto-save active workout when it changes.
    // Register the effect AFTER the initial load to avoid immediate overwriting.
    effect(() {
      final Workout workout = sActiveWorkout.value;
      _activeBox.put('current', workout);
    });
  }

  /// Finishes the current workout, saves it to history using the dateKey, and pauses.
  Future<void> finishWorkout() async {
    final String key = sActiveWorkout.value.dateKey;
    _logger.i('WorkoutService: Finishing workout for date key: $key');

    final Workout finalWorkout = sActiveWorkout.value.copyWith(
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );

    // Save to history using the dateKey (YYYYMMDD) as the unique identifier.
    await _historyBox.put(key, finalWorkout);
    _logger.i(
      'WorkoutService: Workout with ${finalWorkout.exercises.length} exercises saved to history box',
    );

    // Update history signal.
    sWorkoutHistory.value = _historyBox.values.toList();

    // Pause the timer.
    TotalTimer().pauseTimer();
    _logger.i('WorkoutService: Timer paused');
  }

  // Helper to add exercise to sActiveWorkout Signal.
  void addExercise(ExercisePath path) {
    _logger.i('WorkoutService: Adding exercise: ${path.exerciseName}');
    final List<WorkoutExercise> currentExercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    // Determine the type to create the correct model object
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
    } else if (isStretch) {
      newExercise = StretchExercise(
        id: int.parse(path.id),
        exerciseName: path.exerciseName,
        imagePath: path.fullPath,
        sets: <StretchSet>[],
      );
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
    }

    currentExercises.add(newExercise);

    // Update the workout signal with a new copy and snapshot the current timer.
    sActiveWorkout.value = sActiveWorkout.value.copyWith(
      exercises: currentExercises,
      totalDuration: TotalTimer.sElapsedTotalTime.value,
    );
  }

  /// Updates the input state for a StrengthExercise.
  void updateStrengthInput(
    StrengthExercise exercise, {
    double? weight,
    int? reps,
  }) {
    final StrengthExercise updatedExercise = exercise.copyWith(
      weightInput: weight,
      repsInput: reps,
    );

    _logger.i(
      'WorkoutService: Strength Input Updated -> Weight: ${updatedExercise.weightInput}, Reps: ${updatedExercise.repsInput}',
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Updates the input state for a StretchExercise.
  void updateStretchInput(
    StretchExercise exercise, {
    int? hold,
  }) {
    final StretchExercise updatedExercise = exercise.copyWith(
      holdInput: hold,
    );

    _logger.i(
      'WorkoutService: Stretch Input Updated -> Hold: ${updatedExercise.holdInput}',
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Updates the input state for a CardioExercise.
  void updateCardioInput(
    CardioExercise exercise, {
    Duration? duration,
    Duration? restDuration,
    double? distance,
    int? calories,
    int? intensity,
  }) {
    final CardioExercise updatedExercise = exercise.copyWith(
      durationInput: duration,
      restDurationInput: restDuration,
      distanceInput: distance,
      caloriesInput: calories,
      intensityInput: intensity,
    );

    _logger.i(
      'WorkoutService: Cardio Input Updated -> Dur: ${updatedExercise.durationInput}, Dist: ${updatedExercise.distanceInput}',
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Adds a set to a StrengthExercise.
  void addStrengthSet(StrengthExercise exercise, double weight, int reps) {
    _logger.i('WorkoutService: Adding Strength set - $weight kg x $reps reps');
    final StrengthSet newSet = StrengthSet(weight: weight, reps: reps);
    final StrengthExercise updatedExercise = exercise.copyWith(
      sets: <StrengthSet>[...exercise.sets, newSet],
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Deletes a set from a StrengthExercise.
  void deleteStrengthSet(StrengthExercise exercise, StrengthSet set) {
    _logger.i('WorkoutService: Deleting Strength set');
    final List<StrengthSet> updatedSets = List<StrengthSet>.from(exercise.sets);
    updatedSets.remove(set);
    final StrengthExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Adds a set to a CardioExercise.
  void addCardioSet(
    CardioExercise exercise, {
    required Duration cardioDuration,
    required Duration restDuration,
    required Duration totalDuration,
    double? distance,
    int? calories,
    int? intensity,
  }) {
    _logger.i('WorkoutService: Adding Cardio set');
    final CardioSet newSet = CardioSet(
      cardioDuration: cardioDuration,
      restDuration: restDuration,
      totalDuration: totalDuration,
      distance: distance,
      calories: calories,
      intensity: intensity,
    );
    final CardioExercise updatedExercise = exercise.copyWith(
      sets: <CardioSet>[...exercise.sets, newSet],
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Deletes a set from a CardioExercise.
  void deleteCardioSet(CardioExercise exercise, CardioSet set) {
    _logger.i('WorkoutService: Deleting Cardio set');
    final List<CardioSet> updatedSets = List<CardioSet>.from(exercise.sets);
    updatedSets.remove(set);
    final CardioExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Adds a set to a StretchExercise.
  void addStretchSet(StretchExercise exercise, Duration duration) {
    _logger.i('WorkoutService: Adding Stretch set - ${duration.inSeconds}s');
    final StretchSet newSet = StretchSet(duration: duration);
    final StretchExercise updatedExercise = exercise.copyWith(
      sets: <StretchSet>[...exercise.sets, newSet],
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Deletes a set from a StretchExercise.
  void deleteStretchSet(StretchExercise exercise, StretchSet set) {
    _logger.i('WorkoutService: Deleting Stretch set');
    final List<StretchSet> updatedSets = List<StretchSet>.from(exercise.sets);
    updatedSets.remove(set);
    final StretchExercise updatedExercise = exercise.copyWith(
      sets: updatedSets,
    );

    _replaceExercise(exercise, updatedExercise);
  }

  /// Private helper to replace an exercise instance in the active workout.
  void _replaceExercise(WorkoutExercise oldEx, WorkoutExercise newEx) {
    final List<WorkoutExercise> exercises = List<WorkoutExercise>.from(
      sActiveWorkout.value.exercises,
    );

    final int index = exercises.indexOf(oldEx);
    if (index != -1) {
      _logger.d(
        'WorkoutService: Replacing exercise instance: ${oldEx.exerciseName}',
      );
      exercises[index] = newEx;

      // Update workout signal and snapshot the timer.
      sActiveWorkout.value = sActiveWorkout.value.copyWith(
        exercises: exercises,
        totalDuration: TotalTimer.sElapsedTotalTime.value,
      );

      // Sync the selection to the new object instance.
      sSelectedExercise.value = newEx;
    } else {
      _logger.w('WorkoutService: Could not find exercise to replace!');
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

final WorkoutService workoutService = WorkoutService();
