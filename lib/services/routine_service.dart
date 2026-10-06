import 'dart:async';

import 'package:gymply/models/routine_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/hive_service.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/totaltimer_service.dart';
import 'package:gymply/signals/activeworkout_signal.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

final Signal<List<Routine>> sRoutines = Signal<List<Routine>>(
  <Routine>[],
  options: const SignalOptions<List<Routine>>(name: 'sRoutines'),
);

class RoutineService {
  factory RoutineService() {
    return _instance;
  }

  RoutineService._internal();
  static final RoutineService _instance = RoutineService._internal();

  final Logger _logger = Logger();
  late Box<Routine> _routineBox;

  Future<void> init() async {
    _routineBox = hiveService.routineBox;

    // Purge any legacy prefilled mockup routine titled "Chest + Triceps"
    final List<String> mockupKeys = _routineBox.values
        .where((Routine r) => r.title == 'Chest + Triceps')
        .map((Routine r) => r.id)
        .toList();
    for (final String key in mockupKeys) {
      await _routineBox.delete(key);
    }

    sRoutines.value = _routineBox.values.toList();
    _logger.i('RoutineService: Loaded ${sRoutines.value.length} routines');
  }

  Future<void> saveRoutine(Routine routine) async {
    try {
      await _routineBox.put(routine.id, routine);
      sRoutines.value = _routineBox.values.toList();

      _logger.i('RoutineService: Saved routine ${routine.title}');
      ToastService.showSuccess(
        title: 'Routine Saved',
        subtitle: '${routine.title} template is ready to use.',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'RoutineService: Failed to save routine',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Routine Error',
        subtitle: 'Failed to save routine template.',
      );
    }
  }

  Future<void> updateRoutine(Routine routine) async {
    try {
      await _routineBox.put(routine.id, routine);
      sRoutines.value = _routineBox.values.toList();

      _logger.i('RoutineService: Updated routine ${routine.title}');
      ToastService.showSuccess(
        title: 'Routine Updated',
        subtitle: '${routine.title} template updated.',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'RoutineService: Failed to update routine',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Routine Error',
        subtitle: 'Failed to update routine template.',
      );
    }
  }

  Future<void> deleteRoutine(String id) async {
    try {
      await _routineBox.delete(id);
      sRoutines.value = _routineBox.values.toList();
      _logger.i('RoutineService: Deleted routine $id');
      ToastService.showSuccess(
        title: 'Routine Deleted',
        subtitle: 'Template removed.',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'RoutineService: Failed to delete routine',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> startRoutineToday(Routine routine) async {
    try {
      // Build fresh copy of exercises for active session
      final List<WorkoutExercise> exercisesToStart = <WorkoutExercise>[];
      for (final WorkoutExercise ex in routine.exercises) {
        final String latestNote = sExerciseNotes.value[ex.id] ?? ex.notes;
        exercisesToStart.add(ex.copyWith(notes: latestNote));
      }

      sActiveWorkout.value = Workout(
        id: const Uuid().v4(),
        title: routine.title,
        dateTime: DateTime.now(),
        totalDuration: 0,
        exercises: exercisesToStart,
        routineId: routine.id,
      );

      // Start TotalTimer
      await totalTimer.startTimer();

      // Navigate to WorkoutScreen
      navigateToTab(AppTab.workout);

      ToastService.showSuccess(
        title: 'Routine Started',
        subtitle: 'Active session: ${routine.title}',
      );
    } on Object catch (e, stackTrace) {
      _logger.e(
        'RoutineService: Failed to start routine',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

final RoutineService routineService = RoutineService();
