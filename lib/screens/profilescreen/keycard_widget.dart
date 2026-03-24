import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class KeyCard extends StatefulWidget {
  const KeyCard({
    required this.label,
    required this.icon, required this.isSensitive, this.keyValue,
    this.onFetchValue,
    super.key,
  });

  final String label;
  final String? keyValue;
  final Future<String?> Function()? onFetchValue;
  final IconData icon;
  final bool isSensitive;

  @override
  State<KeyCard> createState() {
    return _KeyCardState();
  }
}

class _KeyCardState extends State<KeyCard> {
  bool _isHidden = true;
  String? _fetchedValue;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String displayValue = widget.isSensitive
        ? (_fetchedValue ?? widget.keyValue ?? '')
        : (widget.keyValue ?? '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(widget.icon, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.isSensitive && _isHidden
                        ? '*************************************************'
                        : displayValue,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isSensitive)
                  IconButton(
                    onPressed: () async {
                      if (_isHidden &&
                          _fetchedValue == null &&
                          widget.onFetchValue != null) {
                        final String? val = await widget.onFetchValue!();
                        if (mounted) {
                          setState(() {
                            _fetchedValue = val;
                          });
                        }
                      }
                      setState(() {
                        _isHidden = !_isHidden;
                      });
                    },
                    icon: Icon(
                      _isHidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 16,
                    ),
                  ),
                IconButton(
                  onPressed: () async {
                    String? textToCopy = displayValue;

                    if (widget.isSensitive &&
                        _fetchedValue == null &&
                        widget.onFetchValue != null) {
                      textToCopy = await widget.onFetchValue!();
                    }

                    if (textToCopy != null) {
                      await Clipboard.setData(
                        ClipboardData(text: textToCopy),
                      );
                      // Show toast to user.
                      ToastService.showSuccess(
                        title: 'Copied to Clipboard',
                        subtitle: 'Use the key at your own discretion',
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.copy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
