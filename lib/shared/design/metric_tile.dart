import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';

enum AppMetricKind { speed, time, distance, accuracy }

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.kind,
    required this.value,
    this.label,
    this.unit,
  });

  final AppMetricKind kind;
  final String value;
  final String? label;
  final String? unit;

  String get _defaultLabel => switch (kind) {
    AppMetricKind.speed => 'Скорость',
    AppMetricKind.time => 'Время',
    AppMetricKind.distance => 'Дистанция',
    AppMetricKind.accuracy => 'Точность',
  };

  String? get _defaultUnit => switch (kind) {
    AppMetricKind.speed => 'км/ч',
    AppMetricKind.time => null,
    AppMetricKind.distance || AppMetricKind.accuracy => 'м',
  };

  Color get _valueColor => switch (kind) {
    AppMetricKind.speed => AppColors.borderAccent,
    AppMetricKind.time || AppMetricKind.accuracy => AppColors.gps,
    AppMetricKind.distance => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? _defaultLabel;
    final effectiveUnit = unit ?? _defaultUnit;
    final semanticsValue = effectiveUnit == null
        ? value
        : '$value $effectiveUnit';

    return Semantics(
      label: effectiveLabel,
      value: semanticsValue,
      container: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96, minWidth: 132),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadii.mediumBorder,
          border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              effectiveLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: _valueColor,
                        height: 32 / 28,
                      ),
                    ),
                  ),
                  if (effectiveUnit case final unit?) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(unit, style: AppTextStyles.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
