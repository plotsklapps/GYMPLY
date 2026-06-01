import 'package:signals/signals_flutter.dart';

final Signal<bool> sOnboardingCompleted = Signal<bool>(
  false,
  options: const SignalOptions<bool>(name: 'sOnboardingCompleted'),
);
