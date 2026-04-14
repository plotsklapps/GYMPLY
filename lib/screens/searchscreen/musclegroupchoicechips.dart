import 'package:flutter/material.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/signals/selectedmusclegroup_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MuscleGroupChoiceChips extends StatelessWidget {
  const MuscleGroupChoiceChips({
    required this.selectedMuscleGroup,
    super.key,
  });

  final MuscleGroup? selectedMuscleGroup;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            ...MuscleGroup.values.map((MuscleGroup group) {
              final bool isSelected = selectedMuscleGroup == group;
              final String assetName = group.name.capitalizeFirst();

              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 4),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: isSelected
                      ? Icon(
                          LucideIcons.circleCheck,
                          color: theme.colorScheme.onSecondary,
                        )
                      : Image.asset(
                          'assets/images/musclegroups/$assetName.png',
                        ),
                  label: Text(
                    assetName,
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    sSelectedMuscleGroup.value = selected ? group : null;
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
