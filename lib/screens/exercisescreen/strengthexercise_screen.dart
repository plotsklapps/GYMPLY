import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/modals/exercisehistory_modal.dart';
import 'package:gymply/modals/exercisestats_modal.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/screens/exercisescreen/rep_controls.dart';
import 'package:gymply/screens/exercisescreen/strengthset_card.dart';
import 'package:gymply/screens/exercisescreen/weight_controls.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:gymply/widgets/calculator_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StrengthExerciseScreen extends StatelessWidget {
  const StrengthExerciseScreen({required this.exercise, super.key});

  final StrengthExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Determine values from model's input fields or fall back to last set.
    final double? currentWeight =
        exercise.weightInput ?? exercise.sets.lastOrNull?.weight;
    final int? currentReps =
        exercise.repsInput ?? exercise.sets.lastOrNull?.reps;

    void updateInput(StrengthExercise exercise, {double? weight, int? reps}) {
      workoutService.updateStrengthInput(
        exercise,
        // Do not allow negative input on weight/reps.
        weight: weight != null ? (weight < 0 ? 0 : weight) : null,
        reps: reps != null ? (reps < 0 ? 0 : reps) : null,
      );
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Exercise Image.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    exercise.imagePath,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),

                // Weight Row.
                WeightControls(
                  currentValue: currentWeight,
                  onDecrementLarge: () {
                    updateInput(exercise, weight: (currentWeight ?? 0) - 10);
                  },
                  onDecrementSmall: () {
                    updateInput(exercise, weight: (currentWeight ?? 0) - 1);
                  },
                  onIncrementSmall: () {
                    updateInput(exercise, weight: (currentWeight ?? 0) + 1);
                  },
                  onIncrementLarge: () {
                    updateInput(exercise, weight: (currentWeight ?? 0) + 10);
                  },
                ),

                const SizedBox(height: 4),

                // Reps Row.
                RepControls(
                  currentValue: currentReps,
                  onDecrementLarge: () {
                    updateInput(exercise, reps: (currentReps ?? 0) - 10);
                  },
                  onDecrementSmall: () {
                    updateInput(exercise, reps: (currentReps ?? 0) - 1);
                  },
                  onIncrementSmall: () {
                    updateInput(exercise, reps: (currentReps ?? 0) + 1);
                  },
                  onIncrementLarge: () {
                    updateInput(exercise, reps: (currentReps ?? 0) + 10);
                  },
                ),
                const SizedBox(height: 4),

                Row(
                  children: <Widget>[
                    // History Button.
                    IconButton(
                      onPressed: () async {
                        await ModalService.showModal(
                          context: context,
                          child: ExerciseHistoryModal(exercise: exercise),
                        );
                      },
                      icon: Icon(
                        LucideIcons.history,
                        color: theme.colorScheme.secondary,
                      ),
                    ),

                    // Statistics Button.
                    IconButton(
                      onPressed: () async {
                        await ModalService.showModal(
                          context: context,
                          child: ExerciseStatsModal(exercise: exercise),
                        );
                      },
                      icon: Icon(
                        LucideIcons.chartColumn,
                        color: theme.colorScheme.secondary,
                      ),
                    ),

                    // Calculator Button.
                    IconButton(
                      onPressed: () async {
                        // Show metric to us system modal.
                        await ModalService.showModal(
                          context: context,
                          child: const ConvertCalculator(),
                        );
                      },
                      icon: Icon(
                        LucideIcons.calculator,
                        color: theme.colorScheme.secondary,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Add Set Button.
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          // Give a little bzzz.
                          await HapticFeedback.lightImpact();

                          if (currentWeight != null && currentReps != null) {
                            workoutService.addStrengthSet(
                              exercise,
                              currentWeight,
                              currentReps,
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.circlePlus),
                        label: const Text(
                          'ADD SET',
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),

          // Scrollable Set List Section.
          StrengthSetCard(exercise: exercise),
        ],
      ),
    );
  }
}
