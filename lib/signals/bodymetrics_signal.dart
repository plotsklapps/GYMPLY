import 'package:gymply/models/bodymetrics_model.dart';
import 'package:signals/signals_flutter.dart';

// Signals for personal stats.
final Signal<int> sAge = Signal<int>(
  0,
  options: const SignalOptions<int>(name: 'sAge'),
);
final Signal<double> sHeight = Signal<double>(
  0,
  options: const SignalOptions<double>(name: 'sHeight'),
);
final Signal<double> sWeight = Signal<double>(
  0,
  options: const SignalOptions<double>(name: 'sWeight'),
);
final Signal<int> sSex = Signal<int>(
  0,
  options: const SignalOptions<int>(name: 'sSex'),
);
final Signal<int> sSomatotype = Signal<int>(
  1,
  options: const SignalOptions<int>(name: 'sSomatotype'),
);

// Signal for body metrics history.
final Signal<List<BodyMetric>> sBodyMetricsHistory = Signal<List<BodyMetric>>(
  <BodyMetric>[],
  options: const SignalOptions<List<BodyMetric>>(name: 'sBodyMetricsHistory'),
);
