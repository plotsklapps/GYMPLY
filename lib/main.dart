import 'package:flutter/material.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/settings_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/home_screen.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive CE.
  await Hive.initFlutter();

  // Register Hive Adapters.
  Hive
    ..registerAdapter(WorkoutAdapter())
    ..registerAdapter(StrengthExerciseAdapter())
    ..registerAdapter(CardioExerciseAdapter())
    ..registerAdapter(StretchExerciseAdapter())
    ..registerAdapter(StrengthSetAdapter())
    ..registerAdapter(CardioSetAdapter())
    ..registerAdapter(StretchSetAdapter())
    ..registerAdapter(MuscleGroupAdapter())
    ..registerAdapter(EquipmentAdapter())
    ..registerAdapter(WorkoutTypeAdapter())
    ..registerAdapter(DurationAdapter())
    ..registerAdapter(SettingsAdapter());

  // Initialize FilterService & WorkoutService.
  await filterService.init();
  await workoutService.init();

  // Enable Wakelock to keep screen on.
  await WakelockPlus.enable();

  // Run the app.
  runApp(const MainEntry());
}

class MainEntry extends StatelessWidget {
  const MainEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapper for context-free toasts.
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'GYMPLY.',
        theme: cThemeData.watch(context),
        home: const HomeScreen(),
      ),
    );
  }
}
