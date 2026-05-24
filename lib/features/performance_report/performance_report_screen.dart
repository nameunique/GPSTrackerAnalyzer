import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';
import 'package:gps_tracker_analyzer/features/performance_report/performance_report_cubit.dart';
import 'package:gps_tracker_analyzer/features/performance_report/performance_report_state.dart';
import 'package:gps_tracker_analyzer/shared/widgets/interval_grid.dart';
import 'package:gps_tracker_analyzer/shared/widgets/metric_tile.dart';
import 'package:gps_tracker_analyzer/shared/widgets/valid_stamp.dart';

class PerformanceReportScreen extends StatelessWidget {
  const PerformanceReportScreen({super.key, required this.sessionFilePath});

  final String sessionFilePath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PerformanceReportCubit.create()..load(sessionFilePath),
      child: const _PerformanceReportView(),
    );
  }
}

class _PerformanceReportView extends StatelessWidget {
  const _PerformanceReportView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBlue,
      appBar: AppBar(
        title: const Text('Отчёт'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PerformanceReportCubit, PerformanceReportState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (state.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          final data = state.data;
          if (data == null) {
            return const Center(
              child: Text('Нет данных', style: TextStyle(color: Colors.white)),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _ReportCard(data: data),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.data});

  final PerformanceReportData data;

  int _nearestIndex(List<ChartSeriesPoint> series, double t) {
    if (series.isEmpty) return -1;
    var best = 0;
    var bestD = (series[0].timeSec - t).abs();
    for (var i = 1; i < series.length; i++) {
      final d = (series[i].timeSec - t).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final series = data.series;
    final maxT = series.isEmpty ? 1.0 : series.last.timeSec;
    final maxSpeedPlotted = math.max(120.0, data.maxSpeedKmh);
    var minAlt = 0.0;
    var maxAlt = 0.0;
    if (series.isNotEmpty) {
      minAlt = series.map((e) => e.altitudeM).reduce(math.min);
      maxAlt = series.map((e) => e.altitudeM).reduce(math.max);
    }
    final altSpan = (maxAlt - minAlt).abs() < 1e-3 ? 1.0 : (maxAlt - minAlt);
    final maxG = math.max(data.maxAbsAccelG, 0.1);

    final speedSpots = <FlSpot>[];
    final altSpots = <FlSpot>[];
    final accelSpots = <FlSpot>[];
    for (final p in series) {
      final x = p.timeSec;
      speedSpots.add(FlSpot(x, p.speedKmh / maxSpeedPlotted * 100));
      altSpots.add(FlSpot(x, (p.altitudeM - minAlt) / altSpan * 100));
      accelSpots.add(
        FlSpot(
          x,
          (p.accelerationG / maxG) * 50 + 50,
        ),
      );
    }

    final time0to100 = data.time0to100Sec;

    return Material(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Performance Report',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                _LegendRow(),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: series.length < 2
                      ? Center(
                          child: Text(
                            'Недостаточно точек для графика',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: maxT,
                            minY: 0,
                            maxY: 100,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: 25,
                              verticalInterval: maxT > 0 ? maxT / 5 : 1,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: AppColors.grid.withValues(alpha: 0.9),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (v) => FlLine(
                                color: AppColors.grid.withValues(alpha: 0.9),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: AppColors.grid),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 25,
                                  getTitlesWidget: (v, m) => Text(
                                    '${v.toInt()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  interval: maxT > 0 ? maxT / 4 : 1,
                                  getTitlesWidget: (v, m) => Text(
                                    v.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => Colors.white,
                                tooltipRoundedRadius: 8,
                                getTooltipItems: (spots) {
                                  return spots.map((spot) {
                                    final idx = _nearestIndex(series, spot.x);
                                    if (idx < 0) {
                                      return LineTooltipItem(
                                        '',
                                        const TextStyle(fontSize: 1),
                                      );
                                    }
                                    final p = series[idx];
                                    final text = switch (spot.barIndex) {
                                      0 =>
                                        'Скорость: ${p.speedKmh.toStringAsFixed(1)} км/ч',
                                      1 =>
                                        'Высота: ${p.altitudeM.toStringAsFixed(1)} м',
                                      _ =>
                                        'Ускорение: ${p.accelerationG.toStringAsFixed(2)} g',
                                    };
                                    return LineTooltipItem(
                                      text,
                                      const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: speedSpots,
                                color: AppColors.speedLine,
                                barWidth: 2,
                                isCurved: true,
                                curveSmoothness: 0.15,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: altSpots,
                                color: AppColors.heightLine,
                                barWidth: 2,
                                isCurved: true,
                                curveSmoothness: 0.15,
                                dotData: const FlDotData(show: false),
                              ),
                              LineChartBarData(
                                spots: accelSpots,
                                color: AppColors.accelLine,
                                barWidth: 2,
                                isCurved: true,
                                curveSmoothness: 0.15,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetricTile(
                      icon: Icons.straighten,
                      value: '${data.distanceM.toStringAsFixed(2)}m',
                      label: 'Distance(m)',
                    ),
                    MetricTile(
                      icon: Icons.speed,
                      value: time0to100 != null
                          ? '${time0to100.toStringAsFixed(2)}s'
                          : '—',
                      label: '0-100 km/h',
                    ),
                    MetricTile(
                      icon: Icons.terrain,
                      value: '${data.slopePercent.toStringAsFixed(2)}%',
                      label: 'Slope',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                IntervalGrid(splitTimesSec: data.splitTimesSec),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ValidStamp(isValid: data.isValid),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        item(AppColors.speedLine, 'Speed(km/h)'),
        item(AppColors.heightLine, 'Height(m)'),
        item(AppColors.accelLine, 'Acceleration(g)'),
      ],
    );
  }
}
