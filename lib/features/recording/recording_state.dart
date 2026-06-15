import 'package:equatable/equatable.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';

class RecordingState extends Equatable {
  const RecordingState({
    this.connection = GpsTelemetryConnectionState.idle,
    this.loops = const [],
    this.isRecording = false,
    this.activeLoopId,
    this.sampleCount = 0,
    this.errorMessage,
  });

  final GpsTelemetryConnectionState connection;
  final List<RecordedLoop> loops;
  final bool isRecording;
  final String? activeLoopId;
  final int sampleCount;
  final String? errorMessage;

  RecordingState copyWith({
    GpsTelemetryConnectionState? connection,
    List<RecordedLoop>? loops,
    bool? isRecording,
    String? activeLoopId,
    int? sampleCount,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveLoop = false,
  }) {
    return RecordingState(
      connection: connection ?? this.connection,
      loops: loops ?? this.loops,
      isRecording: isRecording ?? this.isRecording,
      activeLoopId: clearActiveLoop
          ? null
          : (activeLoopId ?? this.activeLoopId),
      sampleCount: sampleCount ?? this.sampleCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    connection,
    loops,
    isRecording,
    activeLoopId,
    sampleCount,
    errorMessage,
  ];
}
