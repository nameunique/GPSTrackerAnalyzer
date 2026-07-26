import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppRecordLimit {
  records100(100, '100 записей', 'Быстрый замер'),
  records200(200, '200 записей', 'Оптимальный баланс'),
  records300(300, '300 записей', 'Больше данных для анализа'),
  manual(null, 'До остановки', 'Остановите замер вручную');

  const AppRecordLimit(this.recordCount, this.title, this.subtitle);

  final int? recordCount;
  final String title;
  final String subtitle;

  bool get isManual => recordCount == null;
}

class AppRecordLimitOption extends StatelessWidget {
  const AppRecordLimitOption({
    super.key,
    required this.limit,
    required this.selected,
    required this.onTap,
    this.title,
    this.subtitle,
  });

  final AppRecordLimit limit;
  final bool selected;
  final VoidCallback? onTap;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? limit.title;
    final effectiveSubtitle = subtitle ?? limit.subtitle;
    return Semantics(
      button: true,
      checked: selected,
      enabled: onTap != null,
      label: '$effectiveTitle. $effectiveSubtitle',
      child: Material(
        color: selected ? AppColors.accentSubtle : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
          side: BorderSide(
            color: selected ? AppColors.borderAccent : AppColors.border,
            width: selected ? 2 : 1,
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.textOnAccent,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(effectiveTitle, style: AppTextStyles.labelMedium),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
