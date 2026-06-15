import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/permissions/ble_permissions.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_state.dart';

class BluetoothCubit extends Cubit<BluetoothState> {
  BluetoothCubit(this._telemetry) : super(const BluetoothState()) {
    _devicesSub = _telemetry.discoveredDevices.listen((devices) {
      emit(state.copyWith(devices: devices));
    });
    _connSub = _telemetry.connectionState.listen((connection) {
      emit(state.copyWith(connection: connection, clearError: true));
    });
  }

  final GpsTelemetryRepository _telemetry;

  StreamSubscription<List<BleDeviceInfo>>? _devicesSub;
  StreamSubscription<GpsTelemetryConnectionState>? _connSub;

  Future<void> ensurePermissions() async {
    final ok = await ensureBlePermissions();
    emit(state.copyWith(permissionsGranted: ok));
    if (!ok) {
      emit(
        state.copyWith(errorMessage: 'Нужны разрешения Bluetooth и геолокации'),
      );
    }
  }

  Future<void> scan() async {
    emit(state.copyWith(clearError: true));
    if (!state.permissionsGranted) {
      await ensurePermissions();
      if (!state.permissionsGranted) return;
    }
    try {
      await _telemetry.startScan();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Сканирование: $e'));
    }
  }

  Future<void> stopScan() async {
    try {
      await _telemetry.stopScan();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Остановка сканирования: $e'));
    }
  }

  Future<void> connect(String remoteId) async {
    emit(state.copyWith(clearError: true));
    try {
      await _telemetry.connect(remoteId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Подключение: $e'));
    }
  }

  Future<void> disconnect() async {
    emit(state.copyWith(clearError: true));
    try {
      await _telemetry.disconnect();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Отключение: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _devicesSub?.cancel();
    await _connSub?.cancel();
    return super.close();
  }
}
