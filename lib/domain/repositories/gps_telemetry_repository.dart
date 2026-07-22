import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';

enum GpsTelemetryConnectionState {
  idle,
  scanning,
  connecting,
  connected,
  bluetoothOff,
  error,
}

abstract class GpsTelemetryRepository {
  Stream<GpsSample> get samples;

  /// Synchronous connection snapshot for consumers created after a state event.
  GpsTelemetryConnectionState get currentConnectionState;

  /// Emits the current snapshot first, followed by subsequent state changes.
  Stream<GpsTelemetryConnectionState> get connectionState;

  Stream<List<BleDeviceInfo>> get discoveredDevices;

  /// Requests that the platform enable Bluetooth. Platforms that cannot do
  /// this programmatically may complete without changing adapter state.
  Future<void> requestEnableBluetooth() async {}

  Future<void> startScan({Duration timeout = const Duration(seconds: 15)});

  Future<void> stopScan();

  Future<void> connect(String remoteId);

  Future<void> disconnect();
}
