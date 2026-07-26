import 'package:equatable/equatable.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';

class RecordingState extends Equatable {
  const RecordingState({
    this.connection = GpsTelemetryConnectionState.idle,
    this.loops = const [],
    this.isRecording = false,
    this.isPaused = false,
    this.activeLoopId,
    this.sampleCount = 0,
    this.latestSample,
    this.elapsed = Duration.zero,
    this.distanceMeters = 0,
    this.recordingMode = TrackRecordingMode.manual,
    this.lastCompletedLoop,
    this.errorMessage,
  });

  final GpsTelemetryConnectionState connection;
  final List<RecordedLoop> loops;
  final bool isRecording;
  final bool isPaused;
  final String? activeLoopId;
  final int sampleCount;
  final GpsSample? latestSample;
  final Duration elapsed;
  final double distanceMeters;
  final TrackRecordingMode recordingMode;
  final RecordedLoop? lastCompletedLoop;
  final String? errorMessage;

  int? get recordingLimit => recordingMode.sampleLimit;

  int? get remainingSamples {
    final limit = recordingLimit;
    if (limit == null) return null;
    final remaining = limit - sampleCount;
    return remaining < 0 ? 0 : remaining;
  }

  double? get recordingProgress {
    final limit = recordingLimit;
    if (limit == null) return null;
    final progress = sampleCount / limit;
    return progress > 1 ? 1 : progress;
  }

  double get distanceKm => distanceMeters / 1000;

  RecordingState copyWith({
    GpsTelemetryConnectionState? connection,
    List<RecordedLoop>? loops,
    bool? isRecording,
    bool? isPaused,
    String? activeLoopId,
    int? sampleCount,
    GpsSample? latestSample,
    Duration? elapsed,
    double? distanceMeters,
    TrackRecordingMode? recordingMode,
    RecordedLoop? lastCompletedLoop,
    String? errorMessage,
    bool clearError = false,
    bool clearActiveLoop = false,
    bool clearLatestSample = false,
    bool clearLastCompletedLoop = false,
  }) {
    return RecordingState(
      connection: connection ?? this.connection,
      loops: loops ?? this.loops,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      activeLoopId: clearActiveLoop
          ? null
          : (activeLoopId ?? this.activeLoopId),
      sampleCount: sampleCount ?? this.sampleCount,
      latestSample: clearLatestSample
          ? null
          : (latestSample ?? this.latestSample),
      elapsed: elapsed ?? this.elapsed,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      recordingMode: recordingMode ?? this.recordingMode,
      lastCompletedLoop: clearLastCompletedLoop
          ? null
          : (lastCompletedLoop ?? this.lastCompletedLoop),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    connection,
    loops,
    isRecording,
    isPaused,
    activeLoopId,
    sampleCount,
    latestSample,
    elapsed,
    distanceMeters,
    recordingMode,
    lastCompletedLoop,
    errorMessage,
  ];
}
