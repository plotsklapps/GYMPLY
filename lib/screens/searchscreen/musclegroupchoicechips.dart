import 'package:flutter/material.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MuscleGroupChoiceChips extends StatelessWidget {
  const MuscleGroupChoiceChips({
    required this.selectedMuscleGroup,
    required this.theme,
    super.key,
  });

  final MuscleGroup? selectedMuscleGroup;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
                      ? const Icon(
                          LucideIcons.circleCheck,
                        )
                      : Image.asset(
                          'assets/images/musclegroups/$assetName.png',
                        ),
                  label: Text(
                    assetName,
                    style: theme.textTheme.titleLarge,
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
