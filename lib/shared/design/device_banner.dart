import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppDeviceBannerState { connected, searching, weak, lost }

class AppDeviceBanner extends StatelessWidget {
  const AppDeviceBanner({
    super.key,
    required this.state,
    this.title,
    this.subtitle,
    this.onTap,
  });

  final AppDeviceBannerState state;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;

  Color get _statusColor => switch (state) {
    AppDeviceBannerState.connected => AppColors.success,
    AppDeviceBannerState.searching => AppColors.gps,
    AppDeviceBannerState.weak => AppColors.warning,
    AppDeviceBannerState.lost => AppColors.error,
  };

  String get _defaultTitle => switch (state) {
    AppDeviceBannerState.connected => 'Трекер подключён',
    AppDeviceBannerState.searching => 'Ищем трекер…',
    AppDeviceBannerState.weak => 'Слабый сигнал',
    AppDeviceBannerState.lost => 'Связь потеряна',
  };

  String get _defaultSubtitle => switch (state) {
    AppDeviceBannerState.connected => 'Сигнал отличный',
    AppDeviceBannerState.searching => 'Держите устройство рядом',
    AppDeviceBannerState.weak => 'Подойдите ближе к трекеру',
    AppDeviceBannerState.lost => 'Нажмите, чтобы подключиться снова',
  };

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? _defaultTitle;
    final effectiveSubtitle = subtitle ?? _defaultSubtitle;
    final borderColor = switch (state) {
      AppDeviceBannerState.weak || AppDeviceBannerState.lost => _statusColor,
      _ => AppColors.border,
    };

    return Semantics(
      button: onTap != null,
      label: '$effectiveTitle. $effectiveSubtitle',
      child: Material(
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 12,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: AppRadii.fullBorder,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          effectiveSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: state == AppDeviceBannerState.lost
                        ? AppColors.error
                        : AppColors.textMuted,
                    size: 24,
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
