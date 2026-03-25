import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/models/cardio_model.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/models/settings_model.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/models/stretch_model.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/screens/home_screen.dart';
import 'package:gymply/screens/onboarding_screen.dart';
import 'package:gymply/services/exercise_service.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/signals/onboarding_signal.dart';
import 'package:gymply/theme/flexscheme.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:signals/signals_flutter.dart';
import 'package:toastification/toastification.dart';

void main() async {
  // Mandatory Flutter framework binding.
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive CE.
  await Hive.initFlutter();

  // Register Hive Adapters, when altered, run:
  // $ dart run build_runner build --delete-conflicting-outputs
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

  // ExerciseService loads raw image assets.
  await exerciseService.init();

  // WorkoutService loads favorites, settings and history.
  await workoutService.init();

  // NostrService loads keys from secure storage.
  await nostrService.init();

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
        home: sOnboardingCompleted.watch(context)
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
