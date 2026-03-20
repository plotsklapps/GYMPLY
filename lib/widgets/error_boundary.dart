import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Catch build-time errors to show fallback UI instead red screen of death.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    super.key,
    this.fallback,
  });

  final Widget child;

  // Fallback widget: Receives error and stack trace.
  final Widget Function(FlutterErrorDetails details)? fallback;

  @override
  State<ErrorBoundary> createState() {
    return _ErrorBoundaryState();
  }
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.fallback != null) {
        return widget.fallback!(_errorDetails!);
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                LucideIcons.octagonX,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'The feed could not be loaded due to a rendering error.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Wrap the child in a custom ErrorWidget.builder scope.
    return ErrorWidgetScope(
      onCatch: (FlutterErrorDetails details) {
        setState(() {
          _errorDetails = details;
        });
      },
      child: widget.child,
    );
  }
}

// Helper widget to override ErrorWidget.builder.
class ErrorWidgetScope extends StatelessWidget {
  const ErrorWidgetScope({
    required this.child,
    required this.onCatch,
    super.key,
  });

  final Widget child;
  final void Function(FlutterErrorDetails details) onCatch;

  @override
  Widget build(BuildContext context) {
    // Save the original builder.
    final ErrorWidgetBuilder originalBuilder = ErrorWidget.builder;

    // Set our custom builder for this build pass.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Revert to original builder for other errors.
      ErrorWidget.builder = originalBuilder;

      // Notify the parent boundary.
      // We use a microtask to avoid calling setState during build.
      unawaited(
        Future<void>.microtask(() {
          onCatch(details);
        }),
      );

      // Return a dummy widget while we wait for the parent to rebuild.
      return const SizedBox.shrink();
    };

    return child;
  }
}
