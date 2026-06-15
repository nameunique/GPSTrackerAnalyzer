import 'package:equatable/equatable.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';

class BluetoothState extends Equatable {
  const BluetoothState({
    this.permissionsGranted = false,
    this.connection = GpsTelemetryConnectionState.idle,
    this.devices = const [],
    this.errorMessage,
  });

  final bool permissionsGranted;
  final GpsTelemetryConnectionState connection;
  final List<BleDeviceInfo> devices;
  final String? errorMessage;

  BluetoothState copyWith({
    bool? permissionsGranted,
    GpsTelemetryConnectionState? connection,
    List<BleDeviceInfo>? devices,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BluetoothState(
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      connection: connection ?? this.connection,
      devices: devices ?? this.devices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    permissionsGranted,
    connection,
    devices,
    errorMessage,
  ];
}
