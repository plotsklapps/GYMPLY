import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/services/filter_service.dart';
import 'package:gymply/services/textformat_service.dart';

class EquipmentChoiceChips extends StatelessWidget {
  const EquipmentChoiceChips({
    required this.workoutType,
    required this.selectedEquipment,
    required this.theme,
    super.key,
  });

  final WorkoutType? workoutType;
  final Equipment? selectedEquipment;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          // Map on current WorkoutType.
          if (workoutType == WorkoutType.strength)
            ...StrengthEquipment.values.map((StrengthEquipment e) {
              final Equipment equipment = Equipment.values.byName(
                e.name,
              );
              final bool isSelected = selectedEquipment == equipment;
              final String assetName = equipment.name.capitalizeFirst();

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: isSelected
                      ? const FaIcon(
                          FontAwesomeIcons.solidCircleCheck,
                        )
                      : Image.asset(
                          'assets/images/equipment/$assetName.png',
                          height: 24,
                          width: 24,
                        ),
                  label: Text(
                    e.name.capitalizeFirst(),
                    style: theme.textTheme.labelLarge,
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    sSelectedEquipment.value = selected ? equipment : null;
                  },
                ),
              );
            }),
          if (workoutType == WorkoutType.cardio)
            ...CardioEquipment.values.map((CardioEquipment e) {
              final Equipment equip = Equipment.values.byName(e.name);
              final bool isSelected = selectedEquipment == equip;
              final String assetName = equip.name.capitalizeFirst();

              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  showCheckmark: false,
                  avatar: isSelected
                      ? const FaIcon(
                          FontAwesomeIcons.solidCircleCheck,
                        )
                      : Image.asset(
                          'assets/images/equipment/$assetName.png',
                          height: 24,
                          width: 24,
                        ),
                  label: Text(
                    e.name.capitalizeFirst(),
                    style: theme.textTheme.labelLarge,
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    sSelectedEquipment.value = selected ? equip : null;
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
