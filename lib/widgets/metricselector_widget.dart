import 'package:flutter/material.dart';
import 'package:gymply/modals/monthstat_modal.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MetricSelector extends StatelessWidget {
  const MetricSelector({
    required this.selectedMetric,
    required this.onSelected,
    super.key,
  });

  final WorkoutMetric selectedMetric;
  final ValueChanged<WorkoutMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: WorkoutMetric.values.map((WorkoutMetric metric) {
          final bool isSelected = selectedMetric == metric;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: true,
              label: Text(metric.name.capitalizeFirst()),
              avatar: isSelected ? const Icon(LucideIcons.circleCheck) : null,
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) {
                  onSelected(metric);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
