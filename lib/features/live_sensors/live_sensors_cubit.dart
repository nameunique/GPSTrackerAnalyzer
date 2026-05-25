import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/live_sensors/live_sensors_state.dart';

class LiveSensorsCubit extends Cubit<LiveSensorsState> {
  LiveSensorsCubit(this._telemetry) : super(const LiveSensorsState()) {
    _connSub = _telemetry.connectionState.listen((connection) {
      emit(state.copyWith(connection: connection));
    });
    _samplesSub = _telemetry.samples.listen((sample) {
      emit(state.copyWith(
        latestSample: sample,
        totalUpdates: state.totalUpdates + 1,
      ));
    });
  }

  final GpsTelemetryRepository _telemetry;

  StreamSubscription<GpsTelemetryConnectionState>? _connSub;
  StreamSubscription<GpsSample>? _samplesSub;

  @override
  Future<void> close() async {
    await _connSub?.cancel();
    await _samplesSub?.cancel();
    return super.close();
  }
}
