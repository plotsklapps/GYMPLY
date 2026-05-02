import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConvertCalculator extends StatefulWidget {
  const ConvertCalculator({super.key});

  @override
  State<ConvertCalculator> createState() {
    return _ConvertCalculatorState();
  }
}

class _ConvertCalculatorState extends State<ConvertCalculator> {
  bool isMetric = false;
  String inputWeight = '0';
  String result = '0.0';

  void _calculate() {
    final double weight = double.tryParse(inputWeight) ?? 0;
    setState(() {
      if (isMetric) {
        // KGS to LBS.
        result = (weight * 2.20462).toStringAsFixed(1);
      } else {
        // LBS to KGS.
        result = (weight / 2.20462).toStringAsFixed(1);
      }
    });
  }

  void _onKeyTap(String label) {
    setState(() {
      if (inputWeight == '0') {
        inputWeight = label;
      } else {
        if (inputWeight.length < 4) {
          inputWeight += label;
        }
      }
    });
    _calculate();
  }

  void _onDeleteTap() {
    setState(() {
      if (inputWeight.length > 1) {
        inputWeight = inputWeight.substring(
          0,
          inputWeight.length - 1,
        );
      } else {
        inputWeight = '0';
      }
    });
    _calculate();
  }

  void _onClearTap() {
    setState(() {
      inputWeight = '0';
    });
    _calculate();
  }

  Widget _buildKey(String label, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FloatingActionButton(
          heroTag: 'btn_$label',
          onPressed: () {
            _onKeyTap(label);
          },
          child: Text(
            label,
            style: theme.textTheme.titleLarge,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(width: 48),
            Expanded(
              child: isMetric
                  ? Text(
                      'CONVERT KGS > LBS',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      'CONVERT LBS > KGS',
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            DisplayColumn(
              value: inputWeight,
              unit: isMetric ? 'kgs' : 'lbs',
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  isMetric = !isMetric;
                });
                _calculate();
              },
              icon: Icon(
                LucideIcons.arrowRightLeft,
                color: theme.colorScheme.secondary,
                size: 32,
              ),
            ),
            DisplayColumn(
              value: result,
              unit: isMetric ? 'lbs' : 'kgs',
              isSecondary: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  _buildKey('1', theme),
                  _buildKey('2', theme),
                  _buildKey('3', theme),
                ],
              ),
              Row(
                children: <Widget>[
                  _buildKey('4', theme),
                  _buildKey('5', theme),
                  _buildKey('6', theme),
                ],
              ),
              Row(
                children: <Widget>[
                  _buildKey('7', theme),
                  _buildKey('8', theme),
                  _buildKey('9', theme),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: FloatingActionButton(
                        heroTag: 'btn_clear',
                        onPressed: _onClearTap,
                        backgroundColor: theme.colorScheme.error,
                        child: const Text(
                          'C',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                  _buildKey('0', theme),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: FloatingActionButton(
                        heroTag: 'btn_delete',
                        onPressed: _onDeleteTap,
                        child: Icon(
                          LucideIcons.delete,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class DisplayColumn extends StatelessWidget {
  const DisplayColumn({
    required this.value,
    required this.unit,
    super.key,
    this.isSecondary = false,
  });

  final String value;
  final String unit;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            color: isSecondary ? theme.colorScheme.secondary : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}
