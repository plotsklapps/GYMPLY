import 'package:gymply/models/exercise_model.dart';
import 'package:signals/signals_flutter.dart';

// Signal to track the selected equipment.
final Signal<Equipment?> sSelectedEquipment = Signal<Equipment?>(
  null,
  debugLabel: 'sSelectedEquipment',
);
