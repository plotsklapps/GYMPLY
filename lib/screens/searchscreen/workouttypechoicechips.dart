import 'package:flutter/material.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/signals/selectedequipment_signal.dart';
import 'package:gymply/signals/selectedmusclegroup_signal.dart';
import 'package:gymply/signals/selectedworkouttype_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class WorkoutTypeChoiceChips extends StatelessWidget {
  const WorkoutTypeChoiceChips({
    required this.workoutType,
    super.key,
  });

  final WorkoutType? workoutType;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ...WorkoutType.values.map((WorkoutType type) {
          final bool isSelected = workoutType == type;

          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 4, 4),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: isSelected
                  ? Icon(
                      LucideIcons.circleCheck,
                      color: theme.colorScheme.onSecondary,
                    )
                  : null,
              label: Text(
                type.name.capitalizeFirst(),
                style: theme.textTheme.titleLarge,
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                sSelectedWorkoutType.value = selected ? type : null;
                sSelectedMuscleGroup.value = null;
                sSelectedEquipment.value = null;
              },
            ),
          );
        }),
      ],
    );
  }
}
