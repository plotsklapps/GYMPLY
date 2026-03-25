import 'package:signals/signals_flutter.dart';

final Signal<bool> sOnboardingCompleted = Signal<bool>(
  false,
  debugLabel: 'sOnboardingCompleted',
);
