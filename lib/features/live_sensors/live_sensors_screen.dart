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
      GpsTelemetryConnectionState.error => 'Ошибка Bluetooth',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBlue,
      appBar: AppBar(
        title: const Text('Датчики в реальном времени'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<LiveSensorsCubit, LiveSensorsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppColors.cardWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Статус: ${_connectionLabel(state.connection)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Обновлений: ${state.totalUpdates}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.latestSample == null)
                Card(
                  color: AppColors.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Нет данных — подключитесь к устройству на экране записи',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                _SensorGrid(sample: state.latestSample!),
            ],
          );
        },
      ),
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.sample});

  final GpsSample sample;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    final ms = dt.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  List<({String label, String value})> get _fields => [
        (label: 'Широта', value: '${sample.latitudeDeg.toStringAsFixed(6)}°'),
        (label: 'Долгота', value: '${sample.longitudeDeg.toStringAsFixed(6)}°'),
        (label: 'Высота', value: '${sample.altitudeM.toStringAsFixed(1)} м'),
        (label: 'Скорость', value: '${sample.speedKmh.toStringAsFixed(1)} км/ч'),
        (label: 'Скорость', value: '${sample.speedMps.toStringAsFixed(2)} м/с'),
        (label: 'Курс', value: '${sample.headingDeg.toStringAsFixed(1)}°'),
        (label: 'Тип фикса', value: '${sample.fixType}'),
        (label: 'Спутники', value: '${sample.numSv}'),
        (label: 'HDOP', value: '${sample.hdop}'),
        (label: 'GPS sync', value: '${sample.gpsSyncBits}'),
        (label: 'Время (тики)', value: '${sample.timeTicksSinceHourStart}'),
        (label: 'Получено', value: _formatTime(sample.receivedAt)),
      ];

  @override
  Widget build(BuildContext context) {
    final fields = _fields;
    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i += 2) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SensorCell(field: fields[i])),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < fields.length
                  ? _SensorCell(field: fields[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < fields.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }
}

class _SensorCell extends StatelessWidget {
  const _SensorCell({required this.field});

  final ({String label, String value}) field;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              field.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              field.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
