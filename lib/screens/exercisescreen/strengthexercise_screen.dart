import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/modals/exercisehistory_modal.dart';
import 'package:gymply/modals/exercisestats_modal.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/services/modal_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StrengthExerciseScreen extends StatelessWidget {
  const StrengthExerciseScreen({required this.exercise, super.key});

  final StrengthExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Determine values from model's input fields or fall back to the last set.
    final double? currentWeight =
        exercise.weightInput ?? exercise.sets.lastOrNull?.weight;
    final int? currentReps =
        exercise.repsInput ?? exercise.sets.lastOrNull?.reps;

    return Scaffold(
      body: Column(
        children: <Widget>[
          // FIXED TOP SECTION.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    // Exercise Image.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        exercise.imagePath,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // History/Statistics Buttons.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
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
                            size: 20,
                          ),
                        ),
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
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 3. Weight Row.
                WeightControls(
                  currentValue: currentWeight,
                  onDecrementLarge: () =>
                      _updateInput(exercise, weight: (currentWeight ?? 0) - 10),
                  onDecrementSmall: () =>
                      _updateInput(exercise, weight: (currentWeight ?? 0) - 1),
                  onIncrementSmall: () =>
                      _updateInput(exercise, weight: (currentWeight ?? 0) + 1),
                  onIncrementLarge: () =>
                      _updateInput(exercise, weight: (currentWeight ?? 0) + 10),
                ),
                const SizedBox(height: 16),

                // 4. Reps Row.
                RepControls(
                  currentValue: currentReps,
                  onDecrementLarge: () =>
                      _updateInput(exercise, reps: (currentReps ?? 0) - 10),
                  onDecrementSmall: () =>
                      _updateInput(exercise, reps: (currentReps ?? 0) - 1),
                  onIncrementSmall: () =>
                      _updateInput(exercise, reps: (currentReps ?? 0) + 1),
                  onIncrementLarge: () =>
                      _updateInput(exercise, reps: (currentReps ?? 0) + 10),
                ),
                const SizedBox(height: 9),

                // 5. Add Set Button.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (currentWeight != null && currentReps != null) {
                        workoutService.addStrengthSet(
                          exercise,
                          currentWeight,
                          currentReps,
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.circlePlus),
                    label: const Text('ADD SET'),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),

          // SCROLLABLE LIST SECTION
          Expanded(
            child: Builder(
              builder: (BuildContext context) {
                // Fetch historical PRs (excluding current session) to detect "New PR"
                final historicalPR = workoutService.getPersonalRecords(
                  exercise.id,
                  includeActive: false,
                );

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: exercise.sets.length,
                  itemBuilder: (BuildContext context, int index) {
                    // Reverse index for visual ordering (latest on top)
                    final int displayIndex = exercise.sets.length - index;
                    final StrengthSet set =
                        exercise.sets.reversed.toList()[index];

                    // Logic to detect New PR
                    final bool isWeightPR =
                        historicalPR.maxWeight > 0 &&
                        set.weight > historicalPR.maxWeight;
                    final bool isVolumePR =
                        historicalPR.maxSetVolume > 0 &&
                        (set.weight * set.reps) > historicalPR.maxSetVolume;
                    final bool isNewPR = isWeightPR || isVolumePR;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color:
                          isNewPR
                              ? theme.colorScheme.secondaryContainer
                              : theme.cardTheme.color,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isNewPR
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primaryContainer,
                          child: Text(
                            displayIndex.toString(),
                            style: TextStyle(
                              color:
                                  isNewPR
                                      ? theme.colorScheme.onSecondary
                                      : theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: <Widget>[
                            Text(
                              '${set.weight.toStringAsFixed(0)} kg x ${set.reps} reps',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight:
                                    isNewPR
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (isNewPR) ...<Widget>[
                              const SizedBox(width: 8),
                              Icon(
                                LucideIcons.trophy,
                                size: 16,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PR!',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (String value) {
                            if (value == 'delete') {
                              workoutService.deleteStrengthSet(exercise, set);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    const Text('Delete'),
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Center(
                                        child: Icon(
                                          LucideIcons.trash,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateInput(StrengthExercise exercise, {double? weight, int? reps}) {
    workoutService.updateStrengthInput(exercise, weight: weight, reps: reps);
  }
}

class WeightControls extends StatelessWidget {
  const WeightControls({
    required this.currentValue,
    required this.onDecrementLarge,
    required this.onDecrementSmall,
    required this.onIncrementSmall,
    required this.onIncrementLarge,
    super.key,
  });

  final double? currentValue;
  final VoidCallback onDecrementLarge;
  final VoidCallback onDecrementSmall;
  final VoidCallback onIncrementSmall;
  final VoidCallback onIncrementLarge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? displayLargeStyle = theme.textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Row(
      children: <Widget>[
        FloatingActionButton(
          heroTag: 'WeightDecrement10',
          elevation: 0,
          onPressed: () async {
            onDecrementLarge();
            await HapticFeedback.heavyImpact();
          },
          child: const Icon(LucideIcons.chevronsDown),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightDecrement1',
          elevation: 0,
          onPressed: () async {
            onDecrementSmall();
            await HapticFeedback.lightImpact();
          },
          child: const Icon(LucideIcons.chevronDown),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currentValue == null ? 'WEIGHT' : currentValue!.toStringAsFixed(0),
            style:
                (currentValue == null
                        ? theme.textTheme.displayMedium
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
            // StrutStyle to ensure height stays consistent.
            strutStyle: StrutStyle.fromTextStyle(displayLargeStyle!),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'WeightIncrement1',
          elevation: 0,
          onPressed: () async {
            onIncrementSmall();
            await HapticFeedback.lightImpact();
          },
          child: const Icon(LucideIcons.chevronUp),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightIncrement10',
          elevation: 0,
          onPressed: () async {
            onIncrementLarge();
            await HapticFeedback.heavyImpact();
          },
          child: const Icon(LucideIcons.chevronsUp),
        ),
      ],
    );
  }
}

class RepControls extends StatelessWidget {
  const RepControls({
    required this.currentValue,
    required this.onDecrementLarge,
    required this.onDecrementSmall,
    required this.onIncrementSmall,
    required this.onIncrementLarge,
    super.key,
  });

  final int? currentValue;
  final VoidCallback onDecrementLarge;
  final VoidCallback onDecrementSmall;
  final VoidCallback onIncrementSmall;
  final VoidCallback onIncrementLarge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? displayLargeStyle = theme.textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Row(
      children: <Widget>[
        FloatingActionButton(
          heroTag: 'RepsDecrement10',
          elevation: 0,
          onPressed: () async {
            onDecrementLarge();
            await HapticFeedback.lightImpact();
          },
          child: const Icon(LucideIcons.chevronsDown),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'RepsDecrement1',
          elevation: 0,
          onPressed: () async {
            onDecrementSmall();
            await HapticFeedback.lightImpact();
          },
          child: const Icon(LucideIcons.chevronDown),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currentValue == null ? 'REPS' : currentValue!.toString(),
            style:
                (currentValue == null
                        ? theme.textTheme.displayMedium
                        : theme.textTheme.displayLarge)
                    ?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
            // StrutStyle to ensure height stays consistent.
            strutStyle: StrutStyle.fromTextStyle(displayLargeStyle!),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'RepsIncrement1',
          elevation: 0,
          onPressed: () async {
            onIncrementSmall();
            await HapticFeedback.lightImpact();
          },
          child: const Icon(LucideIcons.chevronUp),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'RepsIncrement10',
          elevation: 0,
          onPressed: () async {
            onIncrementLarge();
            await HapticFeedback.lightImpact();
          },
          child: const Icon(LucideIcons.chevronsUp),
        ),
      ],
    );
  }
}
