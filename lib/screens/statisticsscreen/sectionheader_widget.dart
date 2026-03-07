import 'package:flutter/material.dart';

class StatisticsSectionHeader extends StatelessWidget {
  const StatisticsSectionHeader({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      textAlign: TextAlign.center,
    );
  }
}
