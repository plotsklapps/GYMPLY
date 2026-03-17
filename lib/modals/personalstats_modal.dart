import 'package:flutter/material.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BodyMetricsModal extends StatefulWidget {
  const BodyMetricsModal({super.key});

  @override
  State<BodyMetricsModal> createState() {
    return _BodyMetricsModalState();
  }
}

class _BodyMetricsModalState extends State<BodyMetricsModal> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  // 0 male, 1 female.
  late int _sex;

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
    // Kill controllers.
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveBodyMetrics() {
    sAge.value = int.tryParse(_ageController.text) ?? 0;
    sHeight.value = double.tryParse(_heightController.text) ?? 0;
    sWeight.value = double.tryParse(_weightController.text) ?? 0;
    sSex.value = _sex;

    // Show toast to user.
    ToastService.showSuccess(
      title: 'Body Metrics Saved',
      subtitle: 'Calculations are now done with new values',
    );

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
            // SizedBox to balance close button.
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'BODY METRICS',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                // Pop and return false.
                Navigator.pop(context, false);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),
        // Sex Selection.
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
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: 'Age',
            prefixIcon: Icon(LucideIcons.cake),
            suffixText: 'yrs',
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ...<Widget>[
          TextField(
            controller: _heightController,
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
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
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: _saveBodyMetrics,
                child: const Text('SAVE'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
