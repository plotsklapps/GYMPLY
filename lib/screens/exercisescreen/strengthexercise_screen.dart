import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/models/strength_model.dart';
import 'package:gymply/services/workout_service.dart';

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
                    // 1. History/Statistics Buttons.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            // History logic later.
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.clockRotateLeft,
                            color: theme.colorScheme.secondary.withAlpha(140),
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Statistics logic later.
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.chartColumn,
                            color: theme.colorScheme.secondary.withAlpha(140),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    // 2. Exercise Image.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        exercise.imagePath,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
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
                    icon: const FaIcon(FontAwesomeIcons.circlePlus),
                    label: const Text('ADD SET'),
                  ),
                ),
                const Divider(),
              ],
            ),
          ),

          // SCROLLABLE LIST SECTION
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: exercise.sets.length,
              itemBuilder: (BuildContext context, int index) {
                // Reverse index for visual ordering (latest on top)
                final int displayIndex = exercise.sets.length - index;
                final StrengthSet set = exercise.sets.reversed.toList()[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        displayIndex.toString(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${set.weight.toStringAsFixed(0)} kg x ${set.reps} reps',
                      style: theme.textTheme.titleLarge,
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
                              children: <Widget>[
                                FaIcon(
                                  FontAwesomeIcons.trashCan,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ),
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

    return Row(
      children: <Widget>[
        FloatingActionButton(
          heroTag: 'WeightDecrement10',
          elevation: 0,
          onPressed: onDecrementLarge,
          child: const FaIcon(FontAwesomeIcons.solidCircleDown),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightDecrement1',
          elevation: 0,
          onPressed: onDecrementSmall,
          child: const FaIcon(FontAwesomeIcons.circleChevronDown),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currentValue == null ? 'WEIGHT' : currentValue!.toStringAsFixed(0),
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'WeightIncrement1',
          elevation: 0,
          onPressed: onIncrementSmall,
          child: const FaIcon(FontAwesomeIcons.circleChevronUp),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'WeightIncrement10',
          elevation: 0,
          onPressed: onIncrementLarge,
          child: const FaIcon(FontAwesomeIcons.solidCircleUp),
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

    return Row(
      children: <Widget>[
        FloatingActionButton(
          heroTag: 'RepsDecrement10',
          elevation: 0,
          onPressed: onDecrementLarge,
          child: const FaIcon(FontAwesomeIcons.solidCircleDown),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'RepsDecrement1',
          elevation: 0,
          onPressed: onDecrementSmall,
          child: const FaIcon(FontAwesomeIcons.circleChevronDown),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            currentValue == null ? 'REPS' : currentValue!.toString(),
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'RepsIncrement1',
          elevation: 0,
          onPressed: onIncrementSmall,
          child: const FaIcon(FontAwesomeIcons.circleChevronUp),
        ),
        const SizedBox(width: 4),
        FloatingActionButton(
          heroTag: 'RepsIncrement10',
          elevation: 0,
          onPressed: onIncrementLarge,
          child: const FaIcon(FontAwesomeIcons.solidCircleUp),
        ),
      ],
    );
  }
}
