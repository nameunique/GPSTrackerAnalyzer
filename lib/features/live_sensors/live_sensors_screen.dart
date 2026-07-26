import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/live_sensors/live_sensors_cubit.dart';
import 'package:gps_tracker_analyzer/features/live_sensors/live_sensors_state.dart';

class LiveSensorsScreen extends StatelessWidget {
  const LiveSensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveSensorsCubit(sl<GpsTelemetryRepository>()),
      child: const _LiveSensorsView(),
    );
  }
}

class _LiveSensorsView extends StatelessWidget {
  const _LiveSensorsView();

  String _connectionLabel(GpsTelemetryConnectionState s) {
    return switch (s) {
      GpsTelemetryConnectionState.idle => 'Ожидание',
      GpsTelemetryConnectionState.scanning => 'Поиск устройств…',
      GpsTelemetryConnectionState.connecting => 'Подключение…',
      GpsTelemetryConnectionState.connected => 'Подключено',
      GpsTelemetryConnectionState.bluetoothOff => 'Bluetooth выключен',
      GpsTelemetryConnectionState.error => 'Ошибка Bluetooth',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBlue,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('Датчики в реальном времени'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<LiveSensorsCubit, LiveSensorsState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 560 || constraints.maxWidth < 360;
                final outerPadding = compact ? 6.0 : 12.0;
                final availableHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight - outerPadding * 2
                    : 600.0;
                final effectiveHeight = availableHeight > 0
                    ? availableHeight
                    : 0.0;
                final gap = effectiveHeight < 80 ? 0.0 : (compact ? 4.0 : 12.0);
                final targetStatusHeight = state.latestSample == null
                    ? (compact ? 58.0 : 92.0)
                    : (compact ? 44.0 : 72.0);
                final maxStatusHeight = effectiveHeight - gap;
                final statusHeight = maxStatusHeight <= 0
                    ? 0.0
                    : (maxStatusHeight < targetStatusHeight
                          ? maxStatusHeight
                          : targetStatusHeight);

                return Padding(
                  padding: EdgeInsets.all(outerPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: statusHeight,
                        child: _StatusCard(
                          connectionLabel: _connectionLabel(state.connection),
                          totalUpdates: state.totalUpdates,
                          hasSample: state.latestSample != null,
                          compact: compact,
                        ),
                      ),
                      SizedBox(height: gap),
                      Expanded(
                        child: _SensorGrid(
                          sample: state.latestSample,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.connectionLabel,
    required this.totalUpdates,
    required this.hasSample,
    required this.compact,
  });

  final String connectionLabel;
  final int totalUpdates;
  final bool hasSample;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 10,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статус: $connectionLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Обновлений: $totalUpdates',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (!hasSample)
                  Text(
                    compact
                        ? 'Данных пока нет'
                        : 'Данных пока нет — подключитесь к устройству на экране записи',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.sample, required this.compact});

  final GpsSample? sample;
  final bool compact;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  List<({String label, String value, String unit})> get _fields {
    final s = sample;

    return [
      (
        label: 'Широта',
        value: s == null ? '—' : s.latitudeDeg.toStringAsFixed(6),
        unit: '°',
      ),
      (
        label: 'Долгота',
        value: s == null ? '—' : s.longitudeDeg.toStringAsFixed(6),
        unit: '°',
      ),
      (
        label: 'Высота',
        value: s == null ? '—' : s.altitudeM.toStringAsFixed(1),
        unit: 'м',
      ),
      (
        label: 'Скорость',
        value: s == null ? '—' : s.speedKmh.toStringAsFixed(1),
        unit: 'км/ч',
      ),
      (
        label: 'Скорость',
        value: s == null ? '—' : s.speedMps.toStringAsFixed(2),
        unit: 'м/с',
      ),
      (
        label: 'Курс',
        value: s == null ? '—' : s.headingDeg.toStringAsFixed(1),
        unit: '°',
      ),
      (
        label: 'Тип фикса',
        value: s == null ? '—' : '${s.fixType}',
        unit: 'код',
      ),
      (label: 'Спутники', value: s == null ? '—' : '${s.numSv}', unit: 'шт.'),
      (label: 'HDOP', value: s == null ? '—' : '${s.hdop}', unit: 'коэф.'),
      (
        label: 'GPS sync',
        value: s == null ? '—' : '${s.gpsSyncBits}',
        unit: 'биты',
      ),
      (
        label: 'Время (тики)',
        value: s == null ? '—' : '${s.timeTicksSinceHourStart}',
        unit: 'тики',
      ),
      (
        label: 'Получено',
        value: s == null ? '—' : _formatTime(s.receivedAt),
        unit: 'HH:mm:ss.SSS',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
    final rows = <Widget>[];
    const dividerSize = 2.0;

    for (var i = 0; i < fields.length; i += 2) {
      rows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SensorCell(field: fields[i], compact: compact),
              ),
              const SizedBox(width: dividerSize),
              Expanded(
                child: i + 1 < fields.length
                    ? _SensorCell(field: fields[i + 1], compact: compact)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < fields.length) {
        rows.add(const SizedBox(height: dividerSize));
      }
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Column(children: rows),
    );
  }
}

class _SensorCell extends StatelessWidget {
  const _SensorCell({required this.field, required this.compact});

  final ({String label, String value, String unit}) field;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cardWhite,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
          vertical: compact ? 2 : 6,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  field.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
                SizedBox(height: compact ? 1 : 3),
                Text(
                  field.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
                SizedBox(height: compact ? 0 : 1),
                Text(
                  field.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
