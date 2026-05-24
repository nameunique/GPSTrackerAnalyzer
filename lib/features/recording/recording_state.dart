import 'package:equatable/equatable.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';

class RecordingState extends Equatable {
  const RecordingState({
    this.permissionsGranted = false,
    this.connection = GpsTelemetryConnectionState.idle,
    this.devices = const [],
    this.isRecording = false,
    this.sampleCount = 0,
    this.errorMessage,
  });

  final bool permissionsGranted;
  final GpsTelemetryConnectionState connection;
  final List<BleDeviceInfo> devices;
  final bool isRecording;
  final int sampleCount;
  final String? errorMessage;

  RecordingState copyWith({
    bool? permissionsGranted,
    GpsTelemetryConnectionState? connection,
    List<BleDeviceInfo>? devices,
    bool? isRecording,
    int? sampleCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecordingState(
      permissionsGranted: permissionsGranted ?? this.permissionsGranted,
      connection: connection ?? this.connection,
      devices: devices ?? this.devices,
      isRecording: isRecording ?? this.isRecording,
      sampleCount: sampleCount ?? this.sampleCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        permissionsGranted,
        connection,
        devices,
        isRecording,
        sampleCount,
        errorMessage,
      ];
}
