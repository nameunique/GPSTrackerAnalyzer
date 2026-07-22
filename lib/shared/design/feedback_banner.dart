import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppFeedbackKind { info, success, warning, error }

class AppFeedbackBanner extends StatelessWidget {
  const AppFeedbackBanner({
    super.key,
    required this.kind,
    required this.title,
    required this.message,
  });

  final AppFeedbackKind kind;
  final String title;
  final String message;

  Color get _color => switch (kind) {
    AppFeedbackKind.info => AppColors.gps,
    AppFeedbackKind.success => AppColors.success,
    AppFeedbackKind.warning => AppColors.warning,
    AppFeedbackKind.error => AppColors.error,
  };

  IconData get _icon => switch (kind) {
    AppFeedbackKind.info => Icons.info_outline_rounded,
    AppFeedbackKind.success => Icons.check_rounded,
    AppFeedbackKind.warning => Icons.priority_high_rounded,
    AppFeedbackKind.error => Icons.close_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final hasStatusBorder = kind != AppFeedbackKind.info;
    return Semantics(
      liveRegion: kind == AppFeedbackKind.error,
      label: '$title. $message',
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadii.mediumBorder,
          border: Border.all(
            color: hasStatusBorder ? _color : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_icon, size: 18, color: AppColors.textOnAccent),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
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
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
