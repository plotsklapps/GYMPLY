// Signal to track search loading state.
import 'package:signals/signals_flutter.dart';

final Signal<bool> sSearchLoading = Signal<bool>(
  false,
  options: const SignalOptions<bool>(name: 'sSearchQuery'),
);
