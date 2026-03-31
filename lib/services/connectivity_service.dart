import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:signals/signals_flutter.dart';

// Global bool Signal to track online status.
final Signal<bool> sIsOnline = Signal<bool>(true, debugLabel: 'sIsOnline');

class ConnectivityService {
  // Singleton pattern.
  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  static final ConnectivityService _instance = ConnectivityService._internal();

  final Logger _logger = Logger();
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  // Initialize monitoring.
  Future<void> init() async {
    // Check initial state.
    final List<ConnectivityResult> initial = await Connectivity()
        .checkConnectivity();
    _updateStatus(initial);

    // Listen for changes.
    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);

    _logger.i('ConnectivityService: Initialized (Online: ${sIsOnline.value})');
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.x returns a List.
    // We are online if any result is NOT .none.
    final bool isConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (sIsOnline.value != isConnected) {
      sIsOnline.value = isConnected;
      _logger.i(
        'ConnectivityService: Status changed to ${isConnected ? "ONLINE" : "OFFLINE"}',
      );
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}

// Globalize ConnectivityService.
final ConnectivityService connectivityService = ConnectivityService();
