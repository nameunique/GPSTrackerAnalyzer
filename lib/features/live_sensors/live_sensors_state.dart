import 'package:equatable/equatable.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';

class LiveSensorsState extends Equatable {
  const LiveSensorsState({
    this.latestSample,
    this.connection = GpsTelemetryConnectionState.idle,
    this.totalUpdates = 0,
  });

  final GpsSample? latestSample;
  final GpsTelemetryConnectionState connection;
  final int totalUpdates;

  LiveSensorsState copyWith({
    GpsSample? latestSample,
    GpsTelemetryConnectionState? connection,
    int? totalUpdates,
  }) {
    return LiveSensorsState(
      latestSample: latestSample ?? this.latestSample,
      connection: connection ?? this.connection,
      totalUpdates: totalUpdates ?? this.totalUpdates,
    );
  }

  @override
  List<Object?> get props => [latestSample, connection, totalUpdates];
}
