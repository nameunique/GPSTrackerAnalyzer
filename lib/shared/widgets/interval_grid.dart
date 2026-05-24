import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';

class IntervalGrid extends StatelessWidget {
  const IntervalGrid({super.key, required this.splitTimesSec});

  final Map<int, double?> splitTimesSec;

  String _format(double? sec) {
    if (sec == null) return '—';
    return '${sec.toStringAsFixed(2)}s';
  }

  @override
  Widget build(BuildContext context) {
    final leftTargets = [10, 20, 30, 40, 50];
    final rightTargets = [60, 70, 80, 90, 100];

    Widget row(int kmh) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.speedLine,
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '0-$kmh:',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _format(splitTimesSec[kmh]),
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftTargets.map(row).toList())),
        Expanded(child: Column(children: rightTargets.map(row).toList())),
      ],
    );
  }
}
