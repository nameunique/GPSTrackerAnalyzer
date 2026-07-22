import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppStatusKind { connected, gps, warning, error, neutral }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.kind, this.label});

  final AppStatusKind kind;
  final String? label;

  Color get _statusColor => switch (kind) {
    AppStatusKind.connected => AppColors.success,
    AppStatusKind.gps => AppColors.gps,
    AppStatusKind.warning => AppColors.warning,
    AppStatusKind.error => AppColors.error,
    AppStatusKind.neutral => AppColors.textMuted,
  };

  String get _defaultLabel => switch (kind) {
    AppStatusKind.connected => 'Подключён',
    AppStatusKind.gps => 'GPS ±3 м',
    AppStatusKind.warning => 'Слабый сигнал',
    AppStatusKind.error => 'Связь потеряна',
    AppStatusKind.neutral => '200 записей',
  };

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? _defaultLabel;
    return Semantics(
      label: effectiveLabel,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadii.fullBorder,
          border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 8),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                effectiveLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: kind == AppStatusKind.neutral
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
