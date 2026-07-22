import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/permissions/ble_permissions.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_state.dart';

class BluetoothCubit extends Cubit<BluetoothState> {
  BluetoothCubit(GpsTelemetryRepository telemetry)
    : _telemetry = telemetry,
      super(BluetoothState(connection: telemetry.currentConnectionState)) {
    _devicesSub = _telemetry.discoveredDevices.listen((devices) {
      _emitIfOpen(state.copyWith(devices: devices));
    });
    _connSub = _telemetry.connectionState.listen((connection) {
      _emitIfOpen(
        state.copyWith(
          connection: connection,
          clearError: connection != GpsTelemetryConnectionState.error,
        ),
      );
    });
  }

  final GpsTelemetryRepository _telemetry;

  StreamSubscription<List<BleDeviceInfo>>? _devicesSub;
  StreamSubscription<GpsTelemetryConnectionState>? _connSub;

  void _emitIfOpen(BluetoothState next) {
    if (!isClosed) emit(next);
  }

  Future<void> ensurePermissions() async {
    final ok = await ensureBlePermissions();
    if (isClosed) return;
    _emitIfOpen(state.copyWith(permissionsGranted: ok));
    if (!ok) {
      _emitIfOpen(
        state.copyWith(errorMessage: 'Нужны разрешения Bluetooth и геолокации'),
      );
    }
  }

  Future<void> scan() async {
    // A new scan is a new result set. Clearing here also prevents a device
    // from the previous scan being connected while the platform scan starts.
    _emitIfOpen(
      state.copyWith(devices: const <BleDeviceInfo>[], clearError: true),
    );
    if (!state.permissionsGranted) {
      await ensurePermissions();
      if (isClosed) return;
      if (!state.permissionsGranted) return;
    }
    try {
      await _telemetry.startScan();
    } catch (e) {
      _emitIfOpen(state.copyWith(errorMessage: 'Сканирование: $e'));
    }
  }

  Future<void> stopScan() async {
    try {
      await _telemetry.stopScan();
    } catch (e) {
      _emitIfOpen(state.copyWith(errorMessage: 'Остановка сканирования: $e'));
    }
  }

  Future<bool> enableBluetooth() async {
    _emitIfOpen(state.copyWith(clearError: true));
    try {
      await _telemetry.requestEnableBluetooth();
      return true;
    } catch (e) {
      if (!isClosed) {
        _emitIfOpen(
          state.copyWith(errorMessage: 'Не удалось включить Bluetooth: $e'),
        );
      }
      return false;
    }
  }

  Future<void> connect(String remoteId) async {
    _emitIfOpen(state.copyWith(clearError: true));
    try {
      await _telemetry.connect(remoteId);
      if (isClosed) return;
      // The repository snapshot is authoritative when its state stream uses
      // asynchronous delivery. Expose it before this Future completes.
      _emitIfOpen(
        state.copyWith(
          connection: _telemetry.currentConnectionState,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitIfOpen(
        state.copyWith(
          connection: _telemetry.currentConnectionState,
          errorMessage: 'Подключение: $e',
        ),
      );
    }
  }

  Future<void> disconnect() async {
    _emitIfOpen(state.copyWith(clearError: true));
    try {
      await _telemetry.disconnect();
    } catch (e) {
      _emitIfOpen(state.copyWith(errorMessage: 'Отключение: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _devicesSub?.cancel();
    await _connSub?.cancel();
    return super.close();
  }
}
