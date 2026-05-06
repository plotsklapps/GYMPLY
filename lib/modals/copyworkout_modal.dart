import 'package:flutter/material.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/navigation_service.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopyWorkoutModal extends StatefulWidget {
  const CopyWorkoutModal({required this.workout, super.key});

  final Workout workout;

  @override
  State<CopyWorkoutModal> createState() {
    return _CopyWorkoutModalState();
  }
}

class _CopyWorkoutModalState extends State<CopyWorkoutModal> {
  // Overwrite vs Merge.
  bool _overwrite = true;
  // Empty vs Copy Values.
  bool _emptyExercises = true;
  // Overwrite Timer vs Add.
  bool _keepCurrentTime = true;
  bool _isLoading = false;

  Future<void> _performCopy() async {
    setState(() {
      _isLoading = true;
    });

    // Small delay to show spinner.
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Perform copy Logic.
    WorkoutService().copyWorkoutToToday(
      widget.workout,
      merge: !_overwrite,
      keepValues: !_emptyExercises,
      keepCurrentTime: _keepCurrentTime,
    );

    // Switch to workout tab.
    navigateToTab(AppTab.workout);

    if (mounted) {
      // Close CopyWorkoutModal, return true.
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // --- FIXED HEADER ---
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                'COPY WORKOUT',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(LucideIcons.circleX),
            ),
          ],
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Overwrite vs Merge Toggle.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _overwrite
                        ? "Overwrite Today's Workout"
                        : "Merge with Today's Workout",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _overwrite
                        ? 'Current active workout exercises will be replaced.'
                        : "Copied exercises will be appended to today's "
                              'active workout.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _overwrite,
                  onChanged: (bool value) {
                    setState(() {
                      _overwrite = value;
                    });
                  },
                ),

                // Empty vs Values Toggle.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _emptyExercises
                        ? 'Copy as Empty Template'
                        : 'Copy All Values',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _emptyExercises
                        ? 'Only exercise selections will be copied. '
                              'Sets, reps, and durations will be empty.'
                        : 'All sets, reps, weight, and durations will be '
                              'copied exactly.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _emptyExercises,
                  onChanged: (bool value) {
                    setState(() {
                      _emptyExercises = value;
                    });
                  },
                ),

                // Timer Toggle.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _keepCurrentTime
                        ? 'Keep Current Total Time'
                        : 'Add To Total Time',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    _keepCurrentTime
                        ? "Today's current total time will remain unaffected."
                        : "The copied workout's total time will be added to today's current total time.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _keepCurrentTime,
                  onChanged: (bool value) {
                    setState(() {
                      _keepCurrentTime = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Buttons Row.
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Close CopyWorkoutModal, return false.
                                Navigator.pop(context, false);
                              },
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _performCopy,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              )
                            : const Text('COPY'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
