import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymply/models/stretch_model.dart';

class StretchExerciseScreen extends StatelessWidget {
  const StretchExerciseScreen({required this.exercise, super.key});

  final StretchExercise exercise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          // FIXED TOP SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // 1. Header.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.exerciseName,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: FaIcon(
                        FontAwesomeIcons.clockRotateLeft,
                        color: theme.colorScheme.secondary.withAlpha(140),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                // 2. Exercise Image.
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    exercise.imagePath,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text('Stretch logging coming soon...'),
                ),
                const SizedBox(height: 32),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
