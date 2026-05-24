import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_state.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecordingCubit(
        sl<GpsTelemetryRepository>(),
        sl<SessionStore>(),
      )..ensurePermissions(),
      child: const _RecordingView(),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView();

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
        title: const Text('Работа с устройством'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<RecordingCubit, RecordingState>(
        listenWhen: (p, c) => c.errorMessage != null && c.errorMessage != p.errorMessage,
        listener: (context, state) {
          final msg = state.errorMessage;
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
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
                      if (!state.permissionsGranted) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Разрешения не выданы — нажмите «Запросить разрешения».',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () =>
                                context.read<RecordingCubit>().ensurePermissions(),
                            child: const Text('Запросить разрешения'),
                          ),
                          FilledButton.tonal(
                            onPressed: state.connection ==
                                    GpsTelemetryConnectionState.scanning
                                ? null
                                : () => context.read<RecordingCubit>().scan(),
                            child: const Text('Сканировать'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                context.read<RecordingCubit>().stopScan(),
                            child: const Text('Стоп скан'),
                          ),
                          if (state.connection ==
                              GpsTelemetryConnectionState.connected)
                            OutlinedButton(
                              onPressed: () =>
                                  context.read<RecordingCubit>().disconnect(),
                              child: const Text('Отключить'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Устройства (${state.devices.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ...state.devices.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      title: Text(d.name ?? 'Без имени'),
                      subtitle: Text(d.remoteId),
                      trailing: state.connection ==
                              GpsTelemetryConnectionState.connected
                          ? null
                          : const Icon(Icons.link),
                      onTap: state.connection ==
                              GpsTelemetryConnectionState.connected
                          ? null
                          : () => context.read<RecordingCubit>().connect(d.remoteId),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
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
                        state.isRecording
                            ? 'Запись: ${state.sampleCount} точек'
                            : 'Запись остановлена',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: !state.isRecording &&
                                state.connection ==
                                    GpsTelemetryConnectionState.connected
                            ? () =>
                                context.read<RecordingCubit>().startRecording()
                            : null,
                        child: const Text('Начать запись прогона'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.validRed,
                        ),
                        onPressed: state.isRecording
                            ? () async {
                                final path = await context
                                    .read<RecordingCubit>()
                                    .stopRecording();
                                if (!context.mounted) return;
                                if (path != null) {
                                  await Navigator.pushNamed(
                                    context,
                                    GpsTrackerApp.routeReport,
                                    arguments: path,
                                  );
                                }
                              }
                            : null,
                        child: const Text('Остановить и отчёт'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
