import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppMeasurementState { normal, best, incomplete }

class AppMeasurementRow extends StatelessWidget {
  const AppMeasurementRow({
    super.key,
    required this.title,
    required this.details,
    required this.result,
    required this.range,
    this.state = AppMeasurementState.normal,
    this.onTap,
  });

  final String title;
  final String details;
  final String result;
  final String range;
  final AppMeasurementState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBest = state == AppMeasurementState.best;
    final resultColor = switch (state) {
      AppMeasurementState.normal => AppColors.textPrimary,
      AppMeasurementState.best => AppColors.success,
      AppMeasurementState.incomplete => AppColors.warning,
    };

    return Semantics(
      button: onTap != null,
      label: '$title. $details. $result. $range',
      child: Material(
        color: isBest ? AppColors.accentSubtle : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
          side: BorderSide(
            color: isBest ? AppColors.borderAccent : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 82),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        result,
                        maxLines: 1,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: resultColor,
                          fontSize: state == AppMeasurementState.incomplete
                              ? 12
                              : 16,
                          height: state == AppMeasurementState.incomplete
                              ? 16 / 12
                              : 20 / 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(range, maxLines: 1, style: AppTextStyles.navigation),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
