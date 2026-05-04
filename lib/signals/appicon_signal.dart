import 'package:signals/signals_flutter.dart';

// Current active app icon alias name.
final Signal<String> sAppIcon = Signal<String>(
  'MainActivityDefault',
  debugLabel: 'sAppIcon',
);
