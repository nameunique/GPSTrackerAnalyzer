import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_cubit.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_state.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  String _connectionLabel(GpsTelemetryConnectionState state) {
    return switch (state) {
      GpsTelemetryConnectionState.idle => 'Ожидание',
      GpsTelemetryConnectionState.scanning => 'Поиск устройств',
      GpsTelemetryConnectionState.connecting => 'Подключение',
      GpsTelemetryConnectionState.connected => 'Подключено',
      GpsTelemetryConnectionState.error => 'Ошибка Bluetooth',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: BlocBuilder<BluetoothCubit, BluetoothState>(
          builder: (context, state) {
            return Text(
              'GPS Tracker • ${_connectionLabel(state.connection)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Настройки Bluetooth',
            icon: const Icon(Icons.settings),
            onPressed: () => _showBluetoothSheet(context),
          ),
        ],
      ),
      body: SafeArea(top: false, child: child),
    );
  }

  void _showBluetoothSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<BluetoothCubit>(),
          child: const _BluetoothSheet(),
        );
      },
    );
  }
}

class _BluetoothSheet extends StatelessWidget {
  const _BluetoothSheet();

  String _connectionLabel(GpsTelemetryConnectionState state) {
    return switch (state) {
      GpsTelemetryConnectionState.idle => 'Ожидание',
      GpsTelemetryConnectionState.scanning => 'Поиск устройств...',
      GpsTelemetryConnectionState.connecting => 'Подключение...',
      GpsTelemetryConnectionState.connected => 'Подключено',
      GpsTelemetryConnectionState.error => 'Ошибка Bluetooth',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<BluetoothCubit, BluetoothState>(
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
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bluetooth устройства',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Статус: ${_connectionLabel(state.connection)}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => context.read<BluetoothCubit>().scan(),
                      child: const Text('Сканировать'),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          context.read<BluetoothCubit>().stopScan(),
                      child: const Text('Стоп'),
                    ),
                    if (state.connection ==
                        GpsTelemetryConnectionState.connected)
                      OutlinedButton(
                        onPressed: () =>
                            context.read<BluetoothCubit>().disconnect(),
                        child: const Text('Отключить'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      state.connection == GpsTelemetryConnectionState.scanning
                          ? 'Идёт поиск устройств...'
                          : 'Устройства пока не найдены',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final device = state.devices[index];
                        return _DeviceTile(device: device);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});

  final BleDeviceInfo device;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(device.name ?? 'Без имени'),
      subtitle: Text(device.remoteId),
      trailing: const Icon(Icons.link),
      onTap: () async {
        await context.read<BluetoothCubit>().connect(device.remoteId);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
    );
  }
}
