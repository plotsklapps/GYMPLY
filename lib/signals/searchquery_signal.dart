import 'package:signals/signals_flutter.dart';

// Signal to track the search query (from user).
final Signal<String> sSearchQuery = Signal<String>(
  '',
  debugLabel: 'sSearchQuery',
);
