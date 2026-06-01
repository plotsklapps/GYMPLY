import 'package:signals/signals_flutter.dart';

// Signals for tracking state in BackupService.
final Signal<bool> sIsBackingUp = Signal<bool>(
  false,
  options: const SignalOptions<bool>(name: 'sIsBackingUp'),
);
final Signal<bool> sIsRestoring = Signal<bool>(
  false,
  options: const SignalOptions<bool>(name: 'sIsRestoring'),
);
final Signal<double> sProgress = Signal<double>(
  0,
  options: const SignalOptions<double>(name: 'sProgress'),
);
