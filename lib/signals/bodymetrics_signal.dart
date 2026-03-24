import 'package:signals/signals_flutter.dart';

// Signals for personal stats.
final Signal<int> sAge = Signal<int>(0, debugLabel: 'sAge');
final Signal<double> sHeight = Signal<double>(0, debugLabel: 'sHeight');
final Signal<double> sWeight = Signal<double>(0, debugLabel: 'sWeight');
final Signal<int> sSex = Signal<int>(0, debugLabel: 'sSex');
