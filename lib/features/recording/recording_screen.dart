import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_state.dart';

class RecordingScreen extends StatelessWidget {
  const RecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          RecordingCubit(sl<GpsTelemetryRepository>(), sl<SessionStore>())
            ..loadLoops(),
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
        title: const Text('Запись трека'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<RecordingCubit, RecordingState>(
        listenWhen: (p, c) =>
            c.errorMessage != null && c.errorMessage != p.errorMessage,
        listener: (context, state) {
          final msg = state.errorMessage;
          if (msg != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
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
                      const SizedBox(height: 8),
                      Text(
                        state.connection ==
                                GpsTelemetryConnectionState.connected
                            ? 'Можно создавать и записывать треки.'
                            : 'Подключитесь к Bluetooth-устройству через шторку сверху.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Треки (${state.loops.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.read<RecordingCubit>().addLoop(),
                    icon: const Icon(Icons.add),
                    label: const Text('Новый'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.loops.isEmpty)
                Card(
                  color: AppColors.cardWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Нажмите "Новый", чтобы создать первый трек для записи.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...state.loops.map((loop) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LoopTile(loop: loop, state: state),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _LoopTile extends StatelessWidget {
  const _LoopTile({required this.loop, required this.state});

  final RecordedLoop loop;
  final RecordingState state;

  String _formatDuration(double seconds) {
    final total = seconds.round();
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Настройки записи',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...TrackRecordingMode.values.map((mode) {
                  return RadioListTile<TrackRecordingMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text(mode.label),
                    value: mode,
                    groupValue: loop.recordingMode,
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<RecordingCubit>().updateRecordingMode(
                        loop.id,
                        value,
                      );
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = state.activeLoopId == loop.id && state.isRecording;
    final canStart =
        !state.isRecording &&
        !loop.isSaved &&
        state.connection == GpsTelemetryConnectionState.connected;

    return Card(
      color: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loop.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isActive
                        ? 'Запись'
                        : loop.isSaved
                        ? 'Сохранён'
                        : 'Новый',
                  ),
                  backgroundColor: isActive
                      ? AppColors.primaryBlue.withValues(alpha: 0.15)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Точек: ${isActive ? state.sampleCount : loop.sampleCount} • '
              'Длительность: ${_formatDuration(loop.durationSec)}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              'Режим: ${loop.recordingMode.label}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: canStart
                      ? () => context.read<RecordingCubit>().startRecording(
                          loop.id,
                        )
                      : null,
                  child: const Text('Старт записи'),
                ),
                FilledButton.tonal(
                  onPressed: isActive
                      ? () => context.read<RecordingCubit>().stopRecording()
                      : null,
                  child: const Text('Стоп записи'),
                ),
                OutlinedButton.icon(
                  onPressed: loop.isSaved
                      ? () {
                          Navigator.pushNamed(
                            context,
                            GpsTrackerApp.routeReport,
                            arguments: loop.filePath,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Анализ'),
                ),
                OutlinedButton.icon(
                  onPressed: loop.isSaved
                      ? () => context.read<RecordingCubit>().exportLoop(loop)
                      : null,
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Экспорт'),
                ),
                OutlinedButton.icon(
                  onPressed: isActive ? null : () => _showSettings(context),
                  icon: const Icon(Icons.settings),
                  label: const Text('Настройки'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
