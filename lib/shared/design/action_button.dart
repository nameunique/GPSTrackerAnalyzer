import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppActionButtonVariant { primary, secondary, danger }

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppActionButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.semanticsLabel,
  });

  const AppActionButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.semanticsLabel,
  }) : variant = AppActionButtonVariant.secondary;

  const AppActionButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.semanticsLabel,
  }) : variant = AppActionButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppActionButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool expand;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final background = switch (variant) {
      AppActionButtonVariant.primary => AppColors.accent,
      AppActionButtonVariant.secondary => AppColors.surfaceRaised,
      AppActionButtonVariant.danger => AppColors.error,
    };
    final side = switch (variant) {
      AppActionButtonVariant.primary ||
      AppActionButtonVariant.danger => BorderSide.none,
      AppActionButtonVariant.secondary => const BorderSide(
        color: AppColors.borderAccent,
      ),
    };

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      ),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: const WidgetStatePropertyAll(AppColors.textOnAccent),
      side: WidgetStatePropertyAll(side),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: AppRadii.mediumBorder),
      ),
      textStyle: const WidgetStatePropertyAll(AppTextStyles.labelMedium),
    );

    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textOnAccent,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon case final icon?) ...[
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.textOnAccent,
                    size: 20,
                  ),
                  child: icon,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    final button = FilledButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: child,
    );

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : AppColors.disabledOpacity,
        duration: const Duration(milliseconds: 160),
        child: expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
