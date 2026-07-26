import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onMore,
    this.endLabel,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final String? endLabel;
  final Widget? trailing;

  static const double height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    assert(
      <Object?>[
            onMore,
            endLabel,
            trailing,
          ].where((value) => value != null).length <=
          1,
      'Use only one of onMore, endLabel, or trailing.',
    );

    return SizedBox(
      height: height,
      child: Row(
        children: [
          if (onBack case final callback?) ...[
            _TopBarIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Назад',
              onPressed: callback,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleLarge,
            ),
          ),
          if (trailing case final trailing?) trailing,
          if (endLabel case final label?)
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minimumTapTarget,
                minHeight: AppSpacing.minimumTapTarget,
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          if (onMore case final callback?)
            _TopBarIconButton(
              icon: Icons.more_horiz_rounded,
              tooltip: 'Ещё',
              onPressed: callback,
            ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppSpacing.minimumTapTarget),
        maximumSize: const Size.square(AppSpacing.minimumTapTarget),
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.textPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.mediumBorder,
        ),
      ),
    );
  }
}
