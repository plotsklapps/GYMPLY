import 'package:flutter/material.dart';
import 'package:gymply/services/textformat_service.dart';
import 'package:intl/intl.dart';

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
    final String monthName = DateFormat('MMM').format(date).capitalizeFirst();

    // Calculate days in the month.
    final int daysInMonth = DateTime(date.year, date.month + 1, 0).day;

    // Calculate start day offset (Monday = 0, Sunday = 6).
    // DateTime.weekday: 1 = Mon, 7 = Sun.
    final int firstDayWeekday = DateTime(date.year, date.month).weekday;
    final int startOffset = firstDayWeekday - 1;

    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 4),
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

              // Skip empty cells, check day number has a workout.
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
