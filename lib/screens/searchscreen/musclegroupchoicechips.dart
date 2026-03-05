import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/scroll_service.dart';
import 'package:gymply/services/textformat_service.dart';

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
      child: ScrollService(
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
                      ? const FaIcon(
                          FontAwesomeIcons.solidCircleCheck,
                        )
                      : Image.asset(
                          'assets/images/musclegroups/$assetName.png',
                          height: 24,
                          width: 24,
                        ),
                  label: Text(
                    assetName,
                    style: theme.textTheme.bodyLarge,
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
