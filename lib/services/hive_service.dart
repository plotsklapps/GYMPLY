import 'package:gymply/models/bodymetrics_model.dart';
import 'package:gymply/models/settings_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:logger/logger.dart';

// Central provider for Hive database access. It knows where the data is
// stored.
//
// init(): Opens workouts, settings and bodymetrics boxes.
// getters: workoutBox, settingsBox, bodyMetricsBox provide Hive box
//          instances to all other services.

class HiveService {
  // Singleton pattern.
  factory HiveService() {
    return _instance;
  }

  HiveService._internal();
  static final HiveService _instance = HiveService._internal();

  final Logger _logger = Logger();

  // Hive boxes.
  late Box<Workout> _workoutBox;
  late Box<Settings> _settingsBox;
  late Box<BodyMetric> _bodyMetricsBox;

  // Box names.
  static const String _workoutBoxName = 'workouts';
  static const String _settingsBoxName = 'settings';
  static const String _bodyMetricsBoxName = 'bodymetrics';

  // Getters for boxes.
  Box<Workout> get workoutBox {
    return _workoutBox;
  }

  Box<Settings> get settingsBox {
    return _settingsBox;
  }

  Box<BodyMetric> get bodyMetricsBox {
    return _bodyMetricsBox;
  }

  // Initialize Hive Boxes.
  Future<void> init() async {
    try {
      // Open or create Hive boxes.
      _workoutBox = await Hive.openBox<Workout>(_workoutBoxName);
      _settingsBox = await Hive.openBox<Settings>(_settingsBoxName);
      _bodyMetricsBox = await Hive.openBox<BodyMetric>(_bodyMetricsBoxName);

      // Log success.
      _logger.i('HiveService: All boxes initialized successfully');
    } catch (e, stackTrace) {
      // Log error.
      _logger.e(
        'HiveService: Failed to initialize Hive boxes',
        error: e,
        stackTrace: stackTrace,
      );

      // Show toast to user.
      ToastService.showError(
        title: 'Storage Error',
        subtitle: 'Failed to load app data. Please restart the app.',
      );

      rethrow;
    }
  }
}

// Globalize HiveService.
final HiveService hiveService = HiveService();
