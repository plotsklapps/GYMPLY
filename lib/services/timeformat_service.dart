// Extension for Time Formatting.
import 'package:intl/intl.dart';

extension TimeFormatter on int {
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
}
