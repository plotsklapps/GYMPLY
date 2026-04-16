import 'package:flutter/material.dart';
import 'package:gymply/models/exercise_model.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:gymply/signals/selectedequipment_signal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EquipmentChoiceChips extends StatelessWidget {
  const EquipmentChoiceChips({
    required this.workoutType,
    required this.selectedEquipment,
    super.key,
  });

  final WorkoutType? workoutType;
  final Equipment? selectedEquipment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
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

                // Equipment ChoiceChips on Strength.
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    showCheckmark: false,
                    avatar: isSelected
                        ? Icon(
                            LucideIcons.circleCheck,
                            color: theme.colorScheme.onSecondary,
                          )
                        : Image.asset(
                            'assets/images/equipment/$assetName.png',
                          ),
                    label: Text(
                      e.name.capitalizeFirst(),
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

                // Equipment ChoiceChips on Cardio.
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    showCheckmark: false,
                    avatar: isSelected
                        ? Icon(
                            LucideIcons.circleCheck,
                            color: theme.colorScheme.onSecondary,
                          )
                        : Image.asset(
                            'assets/images/equipment/$assetName.png',
                            height: 24,
                            width: 24,
                          ),
                    label: Text(
                      e.name.capitalizeFirst(),
                      style: theme.textTheme.titleLarge,
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
      ),
    );
  }
}
