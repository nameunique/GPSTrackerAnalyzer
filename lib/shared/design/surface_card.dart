import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.raised = false,
    this.accented = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool raised;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    final color = accented
        ? AppColors.accentSubtle
        : raised
        ? AppColors.surfaceRaised
        : AppColors.surface;
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.largeBorder,
        side: BorderSide(
          color: accented ? AppColors.borderAccent : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: onTap == null ? 0 : 48),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
