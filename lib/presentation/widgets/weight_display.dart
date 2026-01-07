import 'package:flutter/material.dart';

/// Widget hiển thị cân nặng
class WeightDisplay extends StatelessWidget {
  final double weight;
  final bool isStable;
  final String unit;
  final double fontSize;

  const WeightDisplay({
    super.key,
    required this.weight,
    this.isStable = false,
    this.unit = 'kg',
    this.fontSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${weight.toStringAsFixed(0)} $unit',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: isStable ? Colors.green : Colors.orange,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isStable ? Icons.check_circle : Icons.sync,
              color: isStable ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isStable ? 'Ổn định' : 'Đang cân...',
              style: TextStyle(
                color: isStable ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
