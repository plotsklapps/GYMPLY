import 'package:flutter/material.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PersonalStatsModal extends StatefulWidget {
  const PersonalStatsModal({super.key});

  @override
  State<PersonalStatsModal> createState() => _PersonalStatsModalState();
}

class _PersonalStatsModalState extends State<PersonalStatsModal> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late int _sex; // 0 for male, 1 for female

  @override
  void initState() {
    super.initState();
    _ageController = TextEditingController(
      text: sAge.value == 0 ? '' : sAge.value.toString(),
    );
    _heightController = TextEditingController(
      text: sHeight.value == 0 ? '' : sHeight.value.toString(),
    );
    _weightController = TextEditingController(
      text: sWeight.value == 0 ? '' : sWeight.value.toString(),
    );
    _sex = sSex.value;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _save() {
    sAge.value = int.tryParse(_ageController.text) ?? 0;
    sHeight.value = double.tryParse(_heightController.text) ?? 0;
    sWeight.value = double.tryParse(_weightController.text) ?? 0;
    sSex.value = _sex;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'BODY METRICS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        // Sex Selection
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(
                value: 0,
                label: Text('Male'),
                icon: Icon(LucideIcons.mars),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text('Female'),
                icon: Icon(LucideIcons.venus),
              ),
            ],
            selected: <int>{_sex},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _sex = newSelection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ageController,
          decoration: const InputDecoration(
            labelText: 'Age',
            prefixIcon: Icon(LucideIcons.calendar),
            suffixText: 'years',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ...[
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height',
              prefixIcon: Icon(LucideIcons.ruler),
              suffixText: 'cm',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight',
              prefixIcon: Icon(LucideIcons.weight),
              suffixText: 'kg',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _save,
                child: const Text('SAVE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
