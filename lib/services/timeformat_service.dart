// Extension for Time Formatting.
import 'package:intl/intl.dart';

extension TimeFormatter on int {
  /// Formats as HH:MM
  String formatHHMM() {
    final int hours = this ~/ 3600;
    final int minutes = (this % 3600) ~/ 60;

    final String hoursStr = hours.toString().padLeft(2, '0');
    final String minutesStr = minutes.toString().padLeft(2, '0');

    return '$hoursStr:$minutesStr';
  }

  /// Formats as H:MM:SS
  String formatHMMSS() {
    final int hours = this ~/ 3600;
    final int minutes = (this % 3600) ~/ 60;
    final int remainingSeconds = this % 60;

    final String hoursStr = NumberFormat('0').format(hours);
    final String minutesStr = NumberFormat('00').format(minutes);
    final String secondsStr = NumberFormat('00').format(remainingSeconds);

    return '$hoursStr:$minutesStr:$secondsStr';
  }

  /// Formats as M:SS.
  String formatMSS() {
    final int minutes = this ~/ 60;
    final int remainingSeconds = this % 60;

    final String minutesStr = NumberFormat('0').format(minutes);
    final String secondsStr = NumberFormat('00').format(remainingSeconds);

    return '$minutesStr:$secondsStr';
  }

  /// Formats as H:MM:SS:CC (from milliseconds)
  String formatHMMSSCC() {
    final int hours = this ~/ 3600000;
    final int minutes = (this % 3600000) ~/ 60000;
    final int seconds = (this % 60000) ~/ 1000;
    final int centiseconds = (this % 1000) ~/ 10;

    final String hoursStr = NumberFormat('0').format(hours);
    final String minutesStr = NumberFormat('00').format(minutes);
    final String secondsStr = NumberFormat('00').format(seconds);
    final String centiStr = NumberFormat('00').format(centiseconds);

    return '$hoursStr:$minutesStr:$secondsStr:$centiStr';
  }

  /// Formats as H:MM:SS:T (from milliseconds, T is tenths of a second)
  String formatHMMSSD() {
    final int hours = this ~/ 3600000;
    final int minutes = (this % 3600000) ~/ 60000;
    final int seconds = (this % 60000) ~/ 1000;
    final int tenths = (this % 1000) ~/ 100;

    final String hoursStr = NumberFormat('0').format(hours);
    final String minutesStr = NumberFormat('00').format(minutes);
    final String secondsStr = NumberFormat('00').format(seconds);
    final String tenthsStr = NumberFormat('0').format(tenths);

    return '$hoursStr:$minutesStr:$secondsStr:$tenthsStr';
  }

  /// Formats a Unix timestamp (seconds) as "yyyy, MMMM dd"
  String formatWorkoutDate() {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(this * 1000);
    return DateFormat('yyyy, MMMM dd').format(date);
  }
}

extension DurationFormatter on Duration {
  /// Formats Duration as H:MM:SS (if hours > 0) or MM:SS
  String format() {
    final String minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final String seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    if (inHours > 0) {
      return '$inHours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

extension DateTimeFormatter on DateTime {
  /// Returns date formatted as yyyyMMdd (e.g. 20231027)
  String get yyyyMMdd {
    return DateFormat('yyyyMMdd').format(this);
  }

  /// Returns a descriptive default workout title.
  /// Example: "Saturday Morning Workout"
  String get defaultWorkoutTitle {
    final String dayStr = DateFormat('EEEE').format(this);

    String timeOfDay;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'Morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'Afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeOfDay = 'Evening';
    } else {
      timeOfDay = 'Night';
    }

    return '$dayStr $timeOfDay Workout';
  }
}
