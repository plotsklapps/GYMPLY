// Signal to track search loading state.
import 'package:signals/signals_flutter.dart' show Signal;

final Signal<bool> sSearchLoading = Signal<bool>(
  false,
  debugLabel: 'sSearchLoading',
);
