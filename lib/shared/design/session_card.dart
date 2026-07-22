import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppSessionState { active, completed }

class AppSessionCard extends StatelessWidget {
  const AppSessionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.measurementCount,
    required this.recordCount,
    required this.onAction,
    this.state = AppSessionState.completed,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final int measurementCount;
  final int recordCount;
  final VoidCallback? onAction;
  final AppSessionState state;
  final String? actionLabel;

  bool get _isActive => state == AppSessionState.active;

  String get _defaultActionLabel =>
      _isActive ? 'Продолжить серию' : 'Открыть результаты';

  @override
  Widget build(BuildContext context) {
    final effectiveActionLabel = actionLabel ?? _defaultActionLabel;
    final statusLabel = _isActive ? 'В работе' : 'Готово';

    return Semantics(
      container: true,
      label:
          '$title. $subtitle. $measurementCount замеров, $recordCount записей. '
          '$statusLabel',
      child: Container(
        constraints: const BoxConstraints(minHeight: 172),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: _isActive ? AppColors.accentSubtle : AppColors.surface,
          borderRadius: AppRadii.largeBorder,
          border: Border.all(
            color: _isActive ? AppColors.borderAccent : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _isActive
                        ? AppColors.accent
                        : AppColors.surfaceRaised,
                    borderRadius: AppRadii.fullBorder,
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.navigation.copyWith(
                      color: _isActive
                          ? AppColors.textOnAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  '$measurementCount ${_measurementWord(measurementCount)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('•', style: AppTextStyles.navigation),
                ),
                Text(
                  '$recordCount ${_recordWord(recordCount)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _isActive
                      ? AppColors.accent
                      : AppColors.surfaceRaised,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor:
                      (_isActive ? AppColors.accent : AppColors.surfaceRaised)
                          .withValues(alpha: AppColors.disabledOpacity),
                  disabledForegroundColor: AppColors.textPrimary.withValues(
                    alpha: AppColors.disabledOpacity,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.smallBorder,
                  ),
                  textStyle: AppTextStyles.labelMedium,
                ),
                child: Text(
                  effectiveActionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _measurementWord(int value) {
    final mod100 = value % 100;
    final mod10 = value % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'замеров';
    if (mod10 == 1) return 'замер';
    if (mod10 >= 2 && mod10 <= 4) return 'замера';
    return 'замеров';
  }

  static String _recordWord(int value) {
    final mod100 = value % 100;
    final mod10 = value % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'записей';
    if (mod10 == 1) return 'запись';
    if (mod10 >= 2 && mod10 <= 4) return 'записи';
    return 'записей';
  }
}
