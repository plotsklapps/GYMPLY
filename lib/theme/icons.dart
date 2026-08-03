import 'package:flutter/material.dart';

class IconUtils extends StatelessWidget {
  const IconUtils(
    this.icon, {
    super.key,
    this.size = 20.0,
    this.color,
  });

  /// The Material IconData to display (e.g. Icons.add, Icons.search, Icons.favorite).
  final IconData icon;

  /// Icon size in logical pixels (defaults to 20.0).
  final double size;

  /// Optional color override. If null, inherits color from Theme / IconTheme.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
