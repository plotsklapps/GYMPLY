import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gymply/services/resttimer_service.dart';
import 'package:gymply/services/timeformat_service.dart';
import 'package:signals/signals_flutter.dart';

class RestTimerSheet extends StatelessWidget {
  const RestTimerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Watch Signals.
    final int initialSeconds = RestTimer.sInitialRestTime.watch(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'SET REST DURATION',
          style: theme.textTheme.titleLarge,
        ),
        const Divider(),
        const SizedBox(height: 40),
        // Circular Picker.
        _CircularRestPicker(
          seconds: initialSeconds,
          onChanged: (int newSeconds) {
            RestTimer.sInitialRestTime.value = newSeconds;
            // Also update elapsed time if timer isn't running.
            if (!RestTimer.sRestTimerRunning.value) {
              RestTimer.sElapsedRestTime.value = newSeconds;
            }
          },
        ),
        const SizedBox(height: 40),
        // Cancel/Confirm Buttons.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  RestTimer.sInitialRestTime.value = 60;
                  RestTimer.sElapsedRestTime.value = 60;
                  Navigator.pop(context);
                },
                child: const Text('DEFAULT'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
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

class _CircularRestPicker extends StatelessWidget {
  const _CircularRestPicker({
    required this.seconds,
    required this.onChanged,
  });

  final int seconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const int maxSeconds = 300; // 5 Minutes.

    return GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        _handleGesture(details.localPosition);
      },
      onTapDown: (TapDownDetails details) {
        _handleGesture(details.localPosition);
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Visual Ring.
          CustomPaint(
            size: const Size(200, 200),
            painter: _RingPainter(
              percentage: seconds / maxSeconds,
              theme: theme,
            ),
          ),
          // Time Text.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                seconds.formatMSS(),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              Text(
                'MIN:SEC',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleGesture(Offset localPosition) {
    const Offset center = Offset(200 / 2, 200 / 2);
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;

    // Calculate angle in radians (atan2 returns -PI to PI).
    // Adjust so 0 is at the top (12 o'clock).
    double angle = atan2(dy, dx) + (pi / 2);
    if (angle < 0) angle += 2 * pi;

    // Convert angle to seconds (0 to 300).
    final double rawSeconds = (angle / (2 * pi)) * 300;

    // Snap to nearest 10 seconds.
    int snappedSeconds = (rawSeconds / 10).round() * 10;

    // Clamp between 10 and 300 (avoid 0 for rest).
    snappedSeconds = snappedSeconds.clamp(10, 300);

    onChanged(snappedSeconds);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.percentage, required this.theme});

  final double percentage;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2;
    const double strokeWidth = 30;

    // Background track.
    final Paint trackPaint = Paint()
      ..color = theme.colorScheme.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Active progress arc.
    final Paint progressPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Handle/Knob.
    final Paint knobPaint = Paint()
      ..color = theme.colorScheme.secondary
      ..style = PaintingStyle.fill;

    // Draw track.
    canvas
      ..drawCircle(center, radius, trackPaint)
      // Draw progress arc (starting from top -PI/2).
      ..drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * percentage,
        false,
        progressPaint,
      );

    // Draw Knob at the end of the arc.
    final double knobAngle = (2 * pi * percentage) - (pi / 2);
    final Offset knobOffset = Offset(
      center.dx + radius * cos(knobAngle),
      center.dy + radius * sin(knobAngle),
    );
    canvas.drawCircle(knobOffset, 12, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.theme != theme;
  }
}
