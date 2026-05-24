import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/permissions/ble_permissions.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  RecordingCubit(this._telemetry, this._sessionStore)
      : super(const RecordingState()) {
    _devicesSub = _telemetry.discoveredDevices.listen((devices) {
      emit(state.copyWith(devices: devices));
    });
    _connSub = _telemetry.connectionState.listen((connection) {
      emit(state.copyWith(connection: connection, clearError: true));
    });
  }

  final GpsTelemetryRepository _telemetry;
  final SessionStore _sessionStore;

  StreamSubscription<List<BleDeviceInfo>>? _devicesSub;
  StreamSubscription<GpsTelemetryConnectionState>? _connSub;
  StreamSubscription<GpsSample>? _recordSub;

  ActiveSession? _activeSession;
  int _recordingSamples = 0;

  Future<void> ensurePermissions() async {
    final ok = await ensureBlePermissions();
    emit(state.copyWith(permissionsGranted: ok));
    if (!ok) {
      emit(state.copyWith(
        errorMessage: 'Нужны разрешения Bluetooth и геолокации',
      ));
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
    if (state.isRecording) {
      await stopRecording();
    }
    emit(state.copyWith(clearError: true));
    try {
      await _telemetry.disconnect();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Отключение: $e'));
    }
  }

  Future<void> startRecording() async {
    if (state.connection != GpsTelemetryConnectionState.connected) {
      emit(state.copyWith(
        errorMessage: 'Сначала подключитесь к устройству',
      ));
      return;
    }
    if (state.isRecording) return;

    await _recordSub?.cancel();
    _activeSession = await _sessionStore.startSession();
    _recordingSamples = 0;
    emit(state.copyWith(isRecording: true, sampleCount: 0, clearError: true));

    _recordSub = _telemetry.samples.listen((sample) {
      _sessionStore.appendSample(sample);
      _recordingSamples++;
      emit(state.copyWith(sampleCount: _recordingSamples));
    });
  }

  Future<String?> stopRecording() async {
    if (!state.isRecording) return null;

    await _recordSub?.cancel();
    _recordSub = null;

    final sessionPath = _activeSession?.filePath;
    _activeSession = null;

    final savedPath = await _sessionStore.endSession();

    emit(state.copyWith(isRecording: false, clearError: true));
    return savedPath ?? sessionPath;
  }

  @override
  Future<void> close() async {
    await _devicesSub?.cancel();
    await _connSub?.cancel();
    await _recordSub?.cancel();
    return super.close();
  }
}
