import 'package:gymply/models/bodymetrics_model.dart';
import 'package:gymply/services/hive_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/signals/bodymetrics_signal.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';

// Central provider managing time-series body metric data. It knows how
// to track physical progress.
//
// init(): Prepare connection to bodyMetricsBox.

class BodyMetricsService {
  // Singleton pattern.
  factory BodyMetricsService() {
    return _instance;
  }

  BodyMetricsService._internal();
  static final BodyMetricsService _instance = BodyMetricsService._internal();

  final Logger _logger = Logger();

  // Reference to bodyMetrics box from HiveService.
  late final Box<BodyMetric> _bodyMetricsBox;

  // Initialize BodyMetricsService.
  void init() {
    _bodyMetricsBox = hiveService.bodyMetricsBox;
    _logger.i('BodyMetricsService: Initialized');
  }

  // Save new BodyMetric and update history.
  Future<void> saveBodyMetric({
    required int age,
    required double height,
    required double weight,
    required int sex,
    required int somatotype,
    double? manualBmi,
    double? manualBodyFat,
  }) async {
    try {
      final DateTime now = DateTime.now();

      final BodyMetric newMetric = BodyMetric(
        date: now,
        age: age,
        height: height,
        weight: weight,
        sex: sex,
        somatotype: somatotype,
        manualBmi: manualBmi,
        manualBodyFat: manualBodyFat,
      );

      // Check if an entry for today already exists.
      final int existingIndex = _bodyMetricsBox.values.toList().indexWhere(
        (BodyMetric m) {
          return m.date.year == now.year &&
              m.date.month == now.month &&
              m.date.day == now.day;
        },
      );

      if (existingIndex != -1) {
        // Update existing entry for today.
        final dynamic key = _bodyMetricsBox.keyAt(existingIndex);
        await _bodyMetricsBox.put(key, newMetric);
        _logger.i('BodyMetricsService: Body metrics updated for today');
      } else {
        // Save new entry to Hive.
        await _bodyMetricsBox.add(newMetric);
        _logger.i('BodyMetricsService: New body metrics saved to history');
      }

      // Update Signal.
      sBodyMetricsHistory.value = _bodyMetricsBox.values.toList();

      // Update basic stats signals.
      sAge.value = age;
      sHeight.value = height;
      sWeight.value = weight;
      sSex.value = sex;
      sSomatotype.value = somatotype;
    } on Object catch (e, stackTrace) {
      _logger.e(
        'BodyMetricsService: Failed to save body metric',
        error: e,
        stackTrace: stackTrace,
      );
      ToastService.showError(
        title: 'Metrics Error',
        subtitle: 'Failed to save your body metrics.',
      );
    }
  }
}

// Globalize BodyMetricsService.
final BodyMetricsService bodyMetricsService = BodyMetricsService();
