import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StretchSetStatsModal extends StatefulWidget {
  const StretchSetStatsModal({
    required this.initialIntensity,
    required this.onConfirm,
    super.key,
  });

  final int initialIntensity;
  final void Function(int intensity) onConfirm;

  @override
  State<StretchSetStatsModal> createState() {
    return _StretchSetStatsModalState();
  }
}

class _StretchSetStatsModalState extends State<StretchSetStatsModal> {
  late int _currentIntensity;

  @override
  void initState() {
    super.initState();
    _currentIntensity = widget.initialIntensity;
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
                'SET STATS',
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
        // Intensity SegmentedButton
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            segments: <ButtonSegment<int>>[
              ButtonSegment<int>(
                value: 0,
                label: const Text('Light'),
                icon: Icon(
                  LucideIcons.flame,
                  color: theme.colorScheme.secondary,
                ),
              ),
              ButtonSegment<int>(
                value: 1,
                label: const Text('Medium'),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                  ],
                ),
              ),
              ButtonSegment<int>(
                value: 2,
                label: const Text('Hard'),
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                    Icon(LucideIcons.flame, color: theme.colorScheme.secondary),
                  ],
                ),
              ),
            ],
            selected: <int>{_currentIntensity},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() => _currentIntensity = newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
                onPressed: () {
                  widget.onConfirm(_currentIntensity);
                  Navigator.pop(context, true);
                },
                child: const Text('CONFIRM'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
