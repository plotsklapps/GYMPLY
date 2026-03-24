import 'package:signals/signals_flutter.dart';

// Signals for tracking state in BackupService.
final Signal<bool> sIsBackingUp = Signal<bool>(
  false,
  debugLabel: 'sIsBackingUp',
);
final Signal<bool> sIsRestoring = Signal<bool>(
  false,
  debugLabel: 'sIsRestoring',
);
final Signal<double> sProgress = Signal<double>(0, debugLabel: 'sProgress');
