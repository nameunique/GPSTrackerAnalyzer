import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';

enum GpsTelemetryConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  error,
}

abstract class GpsTelemetryRepository {
  Stream<GpsSample> get samples;

  Stream<GpsTelemetryConnectionState> get connectionState;

  Stream<List<BleDeviceInfo>> get discoveredDevices;

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)});

  Future<void> stopScan();

  Future<void> connect(String remoteId);

  Future<void> disconnect();
}
