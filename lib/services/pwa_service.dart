import 'package:flutter/foundation.dart';
import 'package:gymply/theme/icons.dart';
import 'package:material_ui/material_ui.dart';

class PwaService {
  factory PwaService() {
    return _instance;
  }

  PwaService._internal();
  static final PwaService _instance = PwaService._internal();

  bool _isStandalone = false;
  bool get isStandalone => _isStandalone;

  void init() {
    if (!kIsWeb) return;
    _isStandalone = false;
  }

  void promptInstall(BuildContext context) {
    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                IconUtils.download,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'INSTALL GYMPLY. APP',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'To install GYMPLY to your app drawer or home screen:\n\n'
                '• On Chrome / Android / Desktop: Tap the Install icon in '
                'your browser address bar or menu.\n\n'
                '• On iOS Safari: Tap the Share button and select "Add to '
                'Home Screen".',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('GOT IT'),
              ),
            ],
          ),
        );
      },
    );
  }
}

final PwaService pwaService = PwaService();
