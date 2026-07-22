import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_models.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

class M11SeriesSummaryScreen extends StatelessWidget {
  const M11SeriesSummaryScreen({
    super.key,
    this.measurements,
    this.bestResult = '7,8 с',
    this.measurementCount = 3,
    this.recordCount = 642,
    this.completed = true,
    this.onBack,
    this.onDone,
    this.onMeasurement,
    this.onCompare,
    this.onExport,
  });

  final List<MeasurementListData>? measurements;
  final String bestResult;
  final int measurementCount;
  final int recordCount;
  final bool completed;
  final VoidCallback? onBack;
  final VoidCallback? onDone;
  final ValueChanged<int>? onMeasurement;
  final VoidCallback? onCompare;
  final VoidCallback? onExport;

  static const _fallback = <MeasurementListData>[
    MeasurementListData(
      title: 'Замер 2',
      subtitle: '200 записей • 01:42',
      result: '8,4 с',
    ),
    MeasurementListData(
      title: 'Замер 3 • лучший',
      subtitle: '242 записи • 01:58',
      result: '7,8 с',
      isBest: true,
    ),
    MeasurementListData(
      title: 'Замер 1',
      subtitle: '84 записи • 00:38',
      result: 'Не рассчитан',
      resultCaption: '0–100',
      isPending: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = measurements ?? _fallback;
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(label: 'Сравнить замеры', onPressed: onCompare),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Экспортировать',
            onPressed: onExport,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(
            title: 'Итог серии',
            onBack: onBack,
            endLabel: 'Готово',
            onEnd: onDone,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 102),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
              border: Border.all(color: AppColors.borderAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  completed ? 'Серия завершена' : 'Сравнение серии',
                  style: MobileDesign.h3,
                ),
                const SizedBox(height: 8),
                Text(
                  '$measurementCount ${_measurementWord(measurementCount)}'
                  ' • $recordCount ${_recordWord(recordCount)}',
                  style: MobileDesign.body.copyWith(color: AppColors.gps),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(MobileDesign.radius),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Лучший результат 0–100',
                    style: MobileDesign.small,
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      bestResult,
                      maxLines: 1,
                      style: MobileDesign.metric.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++) ...<Widget>[
            MobileMeasurementRow(
              data: items[i],
              onTap: onMeasurement == null ? null : () => onMeasurement!(i),
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
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

class M12SeriesListScreen extends StatelessWidget {
  const M12SeriesListScreen({
    super.key,
    this.hasActiveSeries = true,
    this.hasCompletedSeries = true,
    this.activeSubtitle = 'Сегодня, 14:32',
    this.activeMeasurementCount = 2,
    this.activeRecordCount = 400,
    this.completedMeasurementCount = 3,
    this.completedRecordCount = 642,
    this.onContinueActive,
    this.onOpenCompleted,
    this.onNewSeries,
    this.onMore,
    this.onTabSelected,
  });

  final bool hasActiveSeries;
  final bool hasCompletedSeries;
  final String activeSubtitle;
  final int activeMeasurementCount;
  final int activeRecordCount;
  final int completedMeasurementCount;
  final int completedRecordCount;
  final VoidCallback? onContinueActive;
  final VoidCallback? onOpenCompleted;
  final VoidCallback? onNewSeries;
  final VoidCallback? onMore;
  final ValueChanged<MobileTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottomNavigation: MobileBottomNavigation(
        active: MobileTab.series,
        onSelected: onTabSelected,
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'Серии', onMore: onMore),
          const SizedBox(height: 16),
          if (hasActiveSeries) ...[
            const Text('Активная серия', style: MobileDesign.h3),
            const SizedBox(height: 12),
            MobileSessionCard(
              title: 'Активная серия',
              subtitle: activeSubtitle,
              stats:
                  '$activeMeasurementCount ${_measurementWord(activeMeasurementCount)}'
                  '   •   $activeRecordCount ${_recordWord(activeRecordCount)}',
              buttonLabel: 'Продолжить серию',
              onPressed: onContinueActive,
              active: true,
            ),
            const SizedBox(height: 12),
          ],
          if (hasCompletedSeries) ...[
            const Text('Завершённые серии', style: MobileDesign.h3),
            const SizedBox(height: 12),
            MobileSessionCard(
              title: 'Последняя серия',
              subtitle: 'Завершена',
              stats:
                  '$completedMeasurementCount ${_measurementWord(completedMeasurementCount)}'
                  '   •   $completedRecordCount ${_recordWord(completedRecordCount)}',
              buttonLabel: 'Открыть результаты',
              onPressed: onOpenCompleted,
            ),
            const SizedBox(height: 12),
          ],
          if (!hasActiveSeries && !hasCompletedSeries) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Серий пока нет', style: MobileDesign.h3),
                  SizedBox(height: 8),
                  Text(
                    'Объединяйте замеры, чтобы сравнивать результаты.',
                    style: MobileDesign.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          MobileActionButton(
            label: 'Новая серия',
            onPressed: onNewSeries,
            height: 56,
            style: MobileButtonStyle.secondary,
          ),
        ],
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

class M13HistoryScreen extends StatefulWidget {
  const M13HistoryScreen({
    super.key,
    this.initialFilter = HistoryFilter.all,
    this.measurements,
    this.series,
    this.onFilterChanged,
    this.onMeasurement,
    this.onSeries,
    this.onStartFirstMeasurement,
    this.onMore,
    this.onTabSelected,
  });

  final HistoryFilter initialFilter;
  final List<MeasurementListData>? measurements;
  final List<MeasurementListData>? series;
  final ValueChanged<HistoryFilter>? onFilterChanged;
  final ValueChanged<int>? onMeasurement;
  final ValueChanged<int>? onSeries;
  final VoidCallback? onStartFirstMeasurement;
  final VoidCallback? onMore;
  final ValueChanged<MobileTab>? onTabSelected;

  @override
  State<M13HistoryScreen> createState() => _M13HistoryScreenState();
}

class _M13HistoryScreenState extends State<M13HistoryScreen> {
  late HistoryFilter _filter = widget.initialFilter;

  static const _fallback = <MeasurementListData>[
    MeasurementListData(
      title: 'Сегодня, 14:32',
      subtitle: '200 записей • 01:42',
      result: '8,4 с',
    ),
    MeasurementListData(
      title: 'Сегодня, 12:08',
      subtitle: '242 записи • 01:58',
      result: '7,8 с',
      isBest: true,
    ),
    MeasurementListData(
      title: '22 июля, 18:45',
      subtitle: '84 записи • 00:38',
      result: 'Не рассчитан',
      resultCaption: '0–100',
      isPending: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final measurements = widget.measurements ?? _fallback;
    final series = widget.series ?? const <MeasurementListData>[];
    final items = switch (_filter) {
      HistoryFilter.all => <MeasurementListData>[...measurements, ...series],
      HistoryFilter.measurements => measurements,
      HistoryFilter.series => series,
    };
    return MobileScreenShell(
      bottomNavigation: MobileBottomNavigation(
        active: MobileTab.history,
        onSelected: widget.onTabSelected,
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'История', onMore: widget.onMore),
          const SizedBox(height: 12),
          Container(
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(MobileDesign.radius),
            ),
            child: Row(
              children: HistoryFilter.values
                  .map((filter) {
                    final selected = filter == _filter;
                    final label = switch (filter) {
                      HistoryFilter.all => 'Все',
                      HistoryFilter.measurements => 'Замеры',
                      HistoryFilter.series => 'Серии',
                    };
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _filter = filter);
                          widget.onFilterChanged?.call(filter);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.accentSubtle
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            label,
                            style: MobileDesign.small.copyWith(
                              color: selected
                                  ? AppColors.gps
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('История пуста', style: MobileDesign.h3),
                  const SizedBox(height: 8),
                  const Text(
                    'Здесь появятся сохранённые замеры и серии.',
                    style: MobileDesign.body,
                  ),
                  const SizedBox(height: 16),
                  MobileActionButton(
                    label: 'Начать первый замер',
                    onPressed: widget.onStartFirstMeasurement,
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(switch (_filter) {
              HistoryFilter.all => 'Все записи',
              HistoryFilter.measurements => 'Замеры',
              HistoryFilter.series => 'Серии',
            }, style: MobileDesign.small),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < items.length; i++) ...<Widget>[
            MobileMeasurementRow(
              data: items[i],
              onTap: switch (_filter) {
                HistoryFilter.series =>
                  widget.onSeries == null ? null : () => widget.onSeries!(i),
                HistoryFilter.measurements =>
                  widget.onMeasurement == null
                      ? null
                      : () => widget.onMeasurement!(i),
                HistoryFilter.all =>
                  i < measurements.length
                      ? (widget.onMeasurement == null
                            ? null
                            : () => widget.onMeasurement!(i))
                      : (widget.onSeries == null
                            ? null
                            : () => widget.onSeries!(i - measurements.length)),
              },
            ),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class M14MeasurementDetailScreen extends StatelessWidget {
  const M14MeasurementDetailScreen({
    super.key,
    this.title = 'Замер 2',
    this.subtitle = 'Сегодня, 14:32 • 200 записей',
    this.duration = '01:42',
    this.distance = '1,27 км',
    this.maxSpeed = '87,4',
    this.acceleration = '8,4 с',
    this.chartSeries,
    this.onBack,
    this.onMore,
    this.onOpenAnalysis,
    this.onAddToSeries,
  });

  final String title;
  final String subtitle;
  final String duration;
  final String distance;
  final String maxSpeed;
  final String acceleration;
  final List<ChartSeriesPoint>? chartSeries;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onOpenAnalysis;
  final VoidCallback? onAddToSeries;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(
            label: 'Открыть анализ',
            onPressed: onOpenAnalysis,
          ),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Добавить в серию',
            onPressed: onAddToSeries,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: title, onBack: onBack, onMore: onMore),
          const SizedBox(height: 12),
          Text(subtitle, style: MobileDesign.body),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: MobileMetricTile(
                  label: 'Время',
                  value: duration,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MobileMetricTile(
                  label: 'Дистанция',
                  value: distance,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MobileMetricTile(
                  label: 'Макс.',
                  value: maxSpeed,
                  compact: true,
                  color: AppColors.borderAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MobileSpeedChart(series: chartSeries),
          const SizedBox(height: 12),
          Material(
            color: AppColors.accentSubtle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MobileDesign.radius),
              side: const BorderSide(color: AppColors.borderAccent),
            ),
            child: InkWell(
              onTap: onOpenAnalysis,
              borderRadius: BorderRadius.circular(MobileDesign.radius),
              child: SizedBox(
                height: 86,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Разгон 0–100 км/ч',
                              style: MobileDesign.small,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                acceleration,
                                maxLines: 1,
                                style: MobileDesign.metric,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.gps,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class M15AnalysisScreen extends StatelessWidget {
  const M15AnalysisScreen({
    super.key,
    this.result = '8,4 с',
    this.chartSeries,
    this.targetSpeedKmh = 100,
    this.targetTimeSec,
    this.analysisValid = true,
    this.onBack,
    this.onMore,
    this.onCompare,
    this.onShare,
  });

  final String result;
  final List<ChartSeriesPoint>? chartSeries;
  final double targetSpeedKmh;
  final double? targetTimeSec;
  final bool analysisValid;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(label: 'Сравнить с другими', onPressed: onCompare),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Поделиться',
            onPressed: onShare,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'Разгон 0–100', onBack: onBack, onMore: onMore),
          const SizedBox(height: 16),
          Container(
            height: 142,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
              border: Border.all(color: AppColors.borderAccent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Результат', style: MobileDesign.small),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      result,
                      maxLines: 1,
                      style: MobileDesign.display,
                    ),
                  ),
                ),
                const Text('по данным этого замера', style: MobileDesign.small),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MobileSpeedChart(title: 'Скорость, км/ч', series: chartSeries),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Старт • 0,0 с',
                  maxLines: 2,
                  style: MobileDesign.small,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${_formatTargetSpeed(targetSpeedKmh)} км/ч • '
                  '${_targetResultLabel()}',
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: MobileDesign.small.copyWith(
                    color: analysisValid
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _targetResultLabel() {
    final seconds = targetTimeSec;
    if (seconds == null || !seconds.isFinite || seconds < 0) return result;
    return '${seconds.toStringAsFixed(1).replaceAll('.', ',')} с';
  }

  static String _formatTargetSpeed(double value) {
    if (!value.isFinite) return '0';
    if ((value - value.round()).abs() < .05) return value.round().toString();
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class M16DeviceScreen extends StatelessWidget {
  const M16DeviceScreen({
    super.key,
    this.deviceName = 'GPS Tracker',
    this.signalLabel = 'Сигнал отличный',
    this.connected = true,
    this.gpsReady = true,
    this.dataActive = true,
    this.lastSyncLabel = 'сейчас',
    this.onDisconnect,
    this.onMore,
    this.onTabSelected,
  });

  final String deviceName;
  final String signalLabel;
  final bool connected;
  final bool gpsReady;
  final bool dataActive;
  final String lastSyncLabel;
  final VoidCallback? onDisconnect;
  final VoidCallback? onMore;
  final ValueChanged<MobileTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottomNavigation: MobileBottomNavigation(
        active: MobileTab.device,
        onSelected: onTabSelected,
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'Устройство', onMore: onMore),
          const SizedBox(height: 12),
          MobileDeviceBanner(
            title: connected ? 'Трекер подключён' : 'Трекер отключён',
            subtitle: connected ? signalLabel : 'Нет соединения',
            color: connected ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 130),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(deviceName, style: MobileDesign.h2),
                const SizedBox(height: 6),
                Text(
                  connected ? signalLabel : 'Нет соединения',
                  style: MobileDesign.body.copyWith(
                    color: connected ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Последняя синхронизация: $lastSyncLabel',
                  style: MobileDesign.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Диагностика', style: MobileDesign.h3),
          const SizedBox(height: 12),
          MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'Bluetooth',
              value: connected ? 'Подключён' : 'Отключён',
              kind: connected ? DiagnosticKind.success : DiagnosticKind.error,
            ),
          ),
          const SizedBox(height: 12),
          MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'GPS',
              value: gpsReady ? 'Точный сигнал' : 'Нет сигнала',
              kind: gpsReady ? DiagnosticKind.gps : DiagnosticKind.warning,
            ),
          ),
          const SizedBox(height: 12),
          MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'Поток данных',
              value: dataActive ? 'Активен' : 'Нет данных',
              kind: dataActive
                  ? DiagnosticKind.success
                  : DiagnosticKind.warning,
            ),
          ),
          const SizedBox(height: 12),
          MobileActionButton(
            label: 'Отключить трекер',
            onPressed: onDisconnect,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
    );
  }
}
