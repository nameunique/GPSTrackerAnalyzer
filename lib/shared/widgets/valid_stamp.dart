import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';

class ValidStamp extends StatelessWidget {
  const ValidStamp({super.key, required this.isValid});

  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final color = isValid ? AppColors.validRed : Colors.grey.shade600;
    final label = isValid ? 'Valid' : 'Invalid';
    return Transform.rotate(
      angle: -math.pi / 12,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
