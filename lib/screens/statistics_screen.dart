import 'package:flutter/material.dart';
import 'package:gymply/models/workout_model.dart';
import 'package:gymply/services/workout_service.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final PageController _pageController;

  // As requested, using the actual year 2026.
  final int _targetYear = 2026;

  @override
  void initState() {
    super.initState();
    // Calculate current quarter index (0-3).
    final int currentQuarter = (DateTime.now().month - 1) ~/ 3;
    _pageController = PageController(initialPage: currentQuarter);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the history to ensure the UI updates when a workout is finished/saved.
    final List<Workout> history = workoutService.sWorkoutHistory.watch(context);

    // Create a Set of date keys for O(1) lookup in the grid.
    final Set<String> workoutDateKeys = history
        .map((Workout w) => w.dateKey)
        .toSet();

    return Scaffold(
      body: Column(
        children: <Widget>[
          // TOP SECTION: Quarterly Month Stats.
          SizedBox(
            height: 110,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 4, // 4 quarters in a year.
              itemBuilder: (BuildContext context, int quarterIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.generate(3, (int monthInQuarter) {
                      final int month = (quarterIndex * 3) + monthInQuarter + 1;
                      return MonthStat(
                        date: DateTime(_targetYear, month),
                        workoutDateKeys: workoutDateKeys,
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // Placeholder for the rest of the statistics.
          const Expanded(
            child: Center(
              child: Text('Statistics Content'),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthStat extends StatelessWidget {
  const MonthStat({
    required this.date,
    required this.workoutDateKeys,
    super.key,
  });

  final DateTime date;
  final Set<String> workoutDateKeys;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String monthName = DateFormat('MMM').format(date).toUpperCase();

    // Calculate days in the month.
    final int daysInMonth = DateTime(date.year, date.month + 1, 0).day;

    // Calculate start day offset (Monday = 0, Sunday = 6).
    // DateTime.weekday: 1 = Mon, 7 = Sun.
    final int firstDayWeekday = DateTime(date.year, date.month).weekday;
    final int startOffset = firstDayWeekday - 1;

    return SizedBox(
      width: 90, // Slightly narrower to fit 7 dots comfortably.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text(
                monthName,
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          // 7-column Grid for aligned monthly dots (Mon-Sun).
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (BuildContext context, int index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final int day = index - startOffset + 1;

              // Actual Logic: Create a dateKey for this dot and check if it's in the history.
              final String key = DateFormat('yyyyMMdd').format(
                DateTime(date.year, date.month, day),
              );
              final bool hasWorkout = workoutDateKeys.contains(key);

              return Center(
                child: Container(
                  width: hasWorkout ? 6 : 4,
                  height: hasWorkout ? 6 : 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasWorkout
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
