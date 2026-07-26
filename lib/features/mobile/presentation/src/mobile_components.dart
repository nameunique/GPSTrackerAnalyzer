import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_models.dart';

abstract final class MobileDesign {
  static const double side = 20;
  static const double maxWidth = 390;
  static const double control = 56;
  static const double tapTarget = 48;
  static const double radius = 16;
  static const double largeRadius = 24;

  static const TextStyle display = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
  static const TextStyle metric = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );
  static const TextStyle h1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle h2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle h3 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle label = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 20 / 14,
  );
  static const TextStyle bodyLarge = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    height: 24 / 16,
  );
  static const TextStyle small = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 18 / 12,
  );
  static const TextStyle tiny = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
}

class MobileScreenShell extends StatelessWidget {
  const MobileScreenShell({
    super.key,
    required this.child,
    this.bottom,
    this.bottomNavigation,
    this.scrollable = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      MobileDesign.side,
      12,
      MobileDesign.side,
      12,
    ),
  });

  final Widget child;
  final Widget? bottom;
  final Widget? bottomNavigation;
  final bool scrollable;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    Widget body = Padding(padding: bodyPadding, child: child);
    if (scrollable) {
      body = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: bodyPadding,
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MobileDesign.maxWidth),
            child: Column(
              children: <Widget>[
                Expanded(child: body),
                if (bottom != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: bottom!,
                  ),
                if (bottomNavigation != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: bottomNavigation!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileTopBar extends StatelessWidget {
  const MobileTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.step,
    this.endLabel,
    this.onEnd,
    this.onMore,
  });

  final String title;
  final VoidCallback? onBack;
  final String? step;
  final String? endLabel;
  final VoidCallback? onEnd;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: <Widget>[
          if (onBack != null) ...<Widget>[
            MobileSquareButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Назад',
              onPressed: onBack,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MobileDesign.h1,
            ),
          ),
          if (step != null || endLabel != null)
            InkWell(
              onTap: endLabel == null ? null : onEnd,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      step ?? endLabel!,
                      style: MobileDesign.small.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (onMore != null)
            MobileSquareButton(
              icon: Icons.more_horiz_rounded,
              tooltip: 'Ещё',
              onPressed: onMore,
            ),
        ],
      ),
    );
  }
}

class MobileSquareButton extends StatelessWidget {
  const MobileSquareButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 24),
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        maximumSize: const Size.square(48),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MobileDesign.radius),
        ),
      ),
    );
  }
}

enum MobileButtonStyle { primary, secondary, danger }

class MobileActionButton extends StatelessWidget {
  const MobileActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = MobileButtonStyle.primary,
    this.height = MobileDesign.control,
  });

  final String label;
  final VoidCallback? onPressed;
  final MobileButtonStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Color background = switch (style) {
      MobileButtonStyle.primary => AppColors.accent,
      MobileButtonStyle.secondary => AppColors.surfaceRaised,
      MobileButtonStyle.danger => AppColors.error,
    };
    final BorderSide side = style == MobileButtonStyle.secondary
        ? const BorderSide(color: AppColors.borderAccent)
        : BorderSide.none;

    return SizedBox(
      width: double.infinity,
      height: math.max(height, MobileDesign.tapTarget),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(
            alpha: AppColors.disabledOpacity,
          ),
          foregroundColor: AppColors.textOnAccent,
          disabledForegroundColor: AppColors.textMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MobileDesign.radius),
            side: side,
          ),
        ),
        child: Text(label, style: MobileDesign.label),
      ),
    );
  }
}

/// Deterministic Bluetooth mark used by the mobile device cards.
///
/// This is intentionally painted instead of sourced from an icon font so its
/// geometry stays identical across Android versions and font configurations.
class MobileBluetoothGlyph extends StatelessWidget {
  const MobileBluetoothGlyph({
    super.key,
    this.size = 28,
    this.color = AppColors.gps,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MobileBluetoothGlyphPainter(color)),
    );
  }
}

class _MobileBluetoothGlyphPainter extends CustomPainter {
  const _MobileBluetoothGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(7, 7)
      ..lineTo(17, 17)
      ..lineTo(12, 22)
      ..lineTo(12, 2)
      ..lineTo(17, 7)
      ..lineTo(7, 17);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MobileBluetoothGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class MobileDeviceBanner extends StatelessWidget {
  const MobileDeviceBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.color = AppColors.success,
    this.onTap,
    this.showChevron = false,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MobileDesign.radius),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 12,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MobileDesign.label,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MobileDesign.small,
                      ),
                    ],
                  ),
                ),
                if (onTap != null || showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileStatusChip extends StatelessWidget {
  const MobileStatusChip({
    super.key,
    required this.label,
    this.color = AppColors.gps,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: MobileDesign.small.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

class MobileBottomNavigation extends StatelessWidget {
  const MobileBottomNavigation({
    super.key,
    required this.active,
    this.onSelected,
  });

  final MobileTab active;
  final ValueChanged<MobileTab>? onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = <(MobileTab, IconData, String)>[
      (MobileTab.home, Icons.home_rounded, 'Главная'),
      (MobileTab.series, Icons.view_list_rounded, 'Серии'),
      (MobileTab.history, Icons.history_rounded, 'История'),
      (MobileTab.device, Icons.smartphone_rounded, 'Устройство'),
    ];
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: tabs
            .map(((MobileTab, IconData, String) item) {
              final selected = item.$1 == active;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.$3,
                  child: InkWell(
                    onTap: onSelected == null
                        ? null
                        : () => onSelected!(item.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accentSubtle
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            item.$2,
                            size: 20,
                            color: selected
                                ? AppColors.gps
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              item.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MobileDesign.tiny.copyWith(
                                color: selected
                                    ? AppColors.gps
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class MobileRecordLimitOption extends StatelessWidget {
  const MobileRecordLimitOption({
    super.key,
    required this.limit,
    required this.selected,
    required this.onTap,
  });

  final RecordLimit limit;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSubtle : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MobileDesign.radius),
        side: BorderSide(
          width: selected ? 2 : 1,
          color: selected ? AppColors.borderAccent : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 2,
                      color: selected ? AppColors.accent : AppColors.textMuted,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppColors.textOnAccent,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(limit.label, style: MobileDesign.label),
                      const SizedBox(height: 2),
                      Text(limit.description, style: MobileDesign.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileFeedbackBanner extends StatelessWidget {
  const MobileFeedbackBanner({
    super.key,
    required this.title,
    required this.message,
    this.color = AppColors.gps,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(MobileDesign.radius),
        border: Border.all(
          color: color == AppColors.gps ? AppColors.border : color,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: MobileDesign.label),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MobileDesign.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileMetricTile extends StatelessWidget {
  const MobileMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color = AppColors.textPrimary,
    this.compact = false,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 80 : 96),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(MobileDesign.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, maxLines: 2, style: MobileDesign.small),
          SizedBox(height: compact ? 2 : 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style:
                          (compact ? MobileDesign.label : MobileDesign.metric)
                              .copyWith(color: color),
                    ),
                  ),
                ),
              ),
              if (unit != null) ...<Widget>[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit!, style: MobileDesign.small),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class MobileRecordingCounter extends StatelessWidget {
  const MobileRecordingCounter.fixed({
    super.key,
    required this.recorded,
    required this.total,
    this.paused = false,
  }) : manual = false;

  const MobileRecordingCounter.manual({super.key, required this.recorded})
    : manual = true,
      total = null,
      paused = false;

  final int recorded;
  final int? total;
  final bool manual;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final progress = total == null ? null : (recorded / total!).clamp(0.0, 1.0);
    final statusColor = paused ? AppColors.error : AppColors.success;
    return Container(
      height: 224,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
        border: Border.all(color: paused ? AppColors.error : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            paused ? 'ПАУЗА' : 'Идёт замер',
            style: MobileDesign.small.copyWith(color: statusColor),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              manual ? 'Записано $recorded' : '$recorded из $total',
              maxLines: 1,
              style: MobileDesign.display,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manual
                ? 'Без лимита'
                : paused
                ? 'записей сохранено'
                : 'записей',
            style: MobileDesign.body.copyWith(
              color: manual ? AppColors.gps : AppColors.textSecondary,
            ),
          ),
          if (progress != null && !paused) ...<Widget>[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
              ),
            ),
          ] else if (manual) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Остановите, когда данных достаточно',
              style: MobileDesign.small.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class MobileMeasurementRow extends StatelessWidget {
  const MobileMeasurementRow({super.key, required this.data, this.onTap});

  final MeasurementListData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resultColor = data.isPending
        ? AppColors.warning
        : data.isBest
        ? AppColors.success
        : AppColors.textPrimary;
    return Material(
      color: data.isBest ? AppColors.accentSubtle : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MobileDesign.radius),
        side: BorderSide(
          color: data.isBest ? AppColors.borderAccent : AppColors.border,
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
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(data.title, style: MobileDesign.label),
                      const SizedBox(height: 4),
                      Text(data.subtitle, style: MobileDesign.small),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          data.result,
                          maxLines: 1,
                          style: MobileDesign.label.copyWith(
                            color: resultColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(data.resultCaption, style: MobileDesign.tiny),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileSessionCard extends StatelessWidget {
  const MobileSessionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.buttonLabel,
    required this.onPressed,
    this.active = false,
  });

  final String title;
  final String subtitle;
  final String stats;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? AppColors.accentSubtle : AppColors.surface,
        borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
        border: Border.all(
          color: active ? AppColors.borderAccent : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: MobileDesign.h3)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  active ? 'В работе' : 'Готово',
                  style: MobileDesign.tiny.copyWith(
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: MobileDesign.small),
          const SizedBox(height: 12),
          Text(stats, style: MobileDesign.small.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          MobileActionButton(
            label: buttonLabel,
            onPressed: onPressed,
            height: 48,
            style: active
                ? MobileButtonStyle.primary
                : MobileButtonStyle.secondary,
          ),
        ],
      ),
    );
  }
}

class MobileDiagnosticRow extends StatelessWidget {
  const MobileDiagnosticRow({super.key, required this.data});

  final DiagnosticData data;

  @override
  Widget build(BuildContext context) {
    final color = switch (data.kind) {
      DiagnosticKind.success => AppColors.success,
      DiagnosticKind.gps => AppColors.gps,
      DiagnosticKind.warning => AppColors.warning,
      DiagnosticKind.error => AppColors.error,
    };
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(data.label, style: MobileDesign.label)),
          Text(data.value, style: MobileDesign.small.copyWith(color: color)),
        ],
      ),
    );
  }
}

class MobileSpeedChart extends StatelessWidget {
  const MobileSpeedChart({
    super.key,
    this.title = 'Скорость',
    this.series,
    this.emptyLabel = 'Недостаточно данных для графика',
  });

  final String title;

  /// `null` keeps the preview data used by standalone design screens.
  /// An empty list intentionally renders an empty state.
  final List<ChartSeriesPoint>? series;
  final String emptyLabel;

  static const _previewSeries = <ChartSeriesPoint>[
    ChartSeriesPoint(timeSec: 0, speedKmh: 4, altitudeM: 0, accelerationG: 0),
    ChartSeriesPoint(timeSec: .8, speedKmh: 10, altitudeM: 0, accelerationG: 0),
    ChartSeriesPoint(
      timeSec: 1.6,
      speedKmh: 20,
      altitudeM: 0,
      accelerationG: 0,
    ),
    ChartSeriesPoint(
      timeSec: 2.6,
      speedKmh: 22,
      altitudeM: 0,
      accelerationG: 0,
    ),
    ChartSeriesPoint(
      timeSec: 3.4,
      speedKmh: 46,
      altitudeM: 0,
      accelerationG: 0,
    ),
    ChartSeriesPoint(
      timeSec: 4.2,
      speedKmh: 41,
      altitudeM: 0,
      accelerationG: 0,
    ),
    ChartSeriesPoint(
      timeSec: 5.1,
      speedKmh: 64,
      altitudeM: 0,
      accelerationG: 0,
    ),
    ChartSeriesPoint(timeSec: 6, speedKmh: 60, altitudeM: 0, accelerationG: 0),
    ChartSeriesPoint(timeSec: 7, speedKmh: 79, altitudeM: 0, accelerationG: 0),
    ChartSeriesPoint(timeSec: 8, speedKmh: 90, altitudeM: 0, accelerationG: 0),
  ];

  @override
  Widget build(BuildContext context) {
    final chartData = MobileSpeedChartData.fromSeries(series ?? _previewSeries);
    return Container(
      height: 196,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(MobileDesign.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: MobileDesign.label),
          const SizedBox(height: 12),
          Expanded(
            child: chartData.isEmpty
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.show_chart_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            emptyLabel,
                            textAlign: TextAlign.center,
                            style: MobileDesign.small,
                          ),
                        ),
                      ],
                    ),
                  )
                : Semantics(
                    key: const ValueKey('mobile-speed-chart-semantics'),
                    label:
                        'График скорости, точек: ${chartData.pointCount}, '
                        'до ${_formatChartValue(chartData.durationSec)} секунд, '
                        'максимум ${_formatChartValue(chartData.maxSpeedKmh)} километров в час',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(
                          width: 34,
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      _formatChartValue(
                                        chartData.speedAxisMaxKmh,
                                      ),
                                      style: MobileDesign.tiny,
                                    ),
                                    Text(
                                      _formatChartValue(
                                        chartData.speedAxisMaxKmh / 2,
                                      ),
                                      style: MobileDesign.tiny,
                                    ),
                                    const Text('0', style: MobileDesign.tiny),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: CustomPaint(
                                  key: const ValueKey('mobile-speed-chart'),
                                  painter: MobileSpeedChartPainter(
                                    chartData.normalizedPoints,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  const Text('0 с', style: MobileDesign.tiny),
                                  Text(
                                    '${_formatChartValue(chartData.durationSec / 2)} с',
                                    style: MobileDesign.tiny,
                                  ),
                                  Text(
                                    '${_formatChartValue(chartData.durationSec)} с',
                                    style: MobileDesign.tiny,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Geometry prepared for [MobileSpeedChartPainter].
///
/// It is public so normalization can be covered independently from rendering.
class MobileSpeedChartData {
  const MobileSpeedChartData._({
    required this.normalizedPoints,
    required this.durationSec,
    required this.maxSpeedKmh,
    required this.speedAxisMaxKmh,
    required this.pointCount,
  });

  factory MobileSpeedChartData.fromSeries(List<ChartSeriesPoint> series) {
    final valid =
        series
            .where((point) => point.timeSec.isFinite && point.speedKmh.isFinite)
            .toList(growable: false)
          ..sort((a, b) => a.timeSec.compareTo(b.timeSec));

    if (valid.isEmpty) {
      return const MobileSpeedChartData._(
        normalizedPoints: <Offset>[],
        durationSec: 0,
        maxSpeedKmh: 0,
        speedAxisMaxKmh: 0,
        pointCount: 0,
      );
    }

    final startTimeSec = valid.first.timeSec;
    final durationSec = math.max(0.0, valid.last.timeSec - startTimeSec);
    final maxSpeedKmh = valid.fold<double>(
      0,
      (current, point) => math.max(current, math.max(0.0, point.speedKmh)),
    );
    final speedAxisMaxKmh = _niceChartMaximum(maxSpeedKmh);
    final timeDivisor = durationSec > 0 ? durationSec : 1.0;

    return MobileSpeedChartData._(
      normalizedPoints: valid
          .map(
            (point) => Offset(
              ((point.timeSec - startTimeSec) / timeDivisor)
                  .clamp(0.0, 1.0)
                  .toDouble(),
              (math.max(0.0, point.speedKmh) / speedAxisMaxKmh)
                  .clamp(0.0, 1.0)
                  .toDouble(),
            ),
          )
          .toList(growable: false),
      durationSec: durationSec,
      maxSpeedKmh: maxSpeedKmh,
      speedAxisMaxKmh: speedAxisMaxKmh,
      pointCount: valid.length,
    );
  }

  final List<Offset> normalizedPoints;
  final double durationSec;
  final double maxSpeedKmh;
  final double speedAxisMaxKmh;
  final int pointCount;

  bool get isEmpty => normalizedPoints.isEmpty;
}

double _niceChartMaximum(double value) {
  if (!value.isFinite || value <= 0) return 1;
  final magnitude = math
      .pow(10, (math.log(value) / math.ln10).floor())
      .toDouble();
  final normalized = value / magnitude;
  final nice = normalized <= 1
      ? 1
      : normalized <= 2
      ? 2
      : normalized <= 5
      ? 5
      : 10;
  return nice * magnitude;
}

String _formatChartValue(double value) {
  if (!value.isFinite) return '0';
  final rounded = value.roundToDouble();
  final text = (value - rounded).abs() < .05
      ? rounded.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return text.replaceAll('.', ',');
}

class MobileSpeedChartPainter extends CustomPainter {
  const MobileSpeedChartPainter(this.normalizedPoints);

  final List<Offset> normalizedPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < 3; i++) {
      final x = size.width * i / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    if (normalizedPoints.isEmpty || size.isEmpty) return;

    final points = normalizedPoints
        .map(
          (point) => Offset(
            point.dx.clamp(0.0, 1.0).toDouble() * size.width,
            (1.0 - point.dy.clamp(0.0, 1.0).toDouble()) * size.height,
          ),
        )
        .toList(growable: false);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (points.length > 1) {
      final fillPath = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0x334C82FF), Color(0x004C82FF)],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.borderAccent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 4, Paint()..color = AppColors.success);
  }

  @override
  bool shouldRepaint(MobileSpeedChartPainter oldDelegate) {
    if (identical(normalizedPoints, oldDelegate.normalizedPoints)) return false;
    if (normalizedPoints.length != oldDelegate.normalizedPoints.length) {
      return true;
    }
    for (var i = 0; i < normalizedPoints.length; i++) {
      if (normalizedPoints[i] != oldDelegate.normalizedPoints[i]) return true;
    }
    return false;
  }
}
