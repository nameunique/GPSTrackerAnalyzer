import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  RecordingCubit(this._telemetry, this._sessionStore)
    : super(const RecordingState()) {
    _connSub = _telemetry.connectionState.listen((connection) {
      emit(state.copyWith(connection: connection, clearError: true));
    });
  }

  final GpsTelemetryRepository _telemetry;
  final SessionStore _sessionStore;

  StreamSubscription<GpsTelemetryConnectionState>? _connSub;
  StreamSubscription<GpsSample>? _recordSub;

  ActiveSession? _activeSession;
  DateTime? _recordStartedAt;
  int _recordingSamples = 0;

  Future<void> loadLoops() async {
    try {
      final loops = await _sessionStore.listLoops();
      emit(state.copyWith(loops: loops, clearError: true));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Загрузка лупов: $e'));
    }
  }

  void addLoop() {
    if (state.isRecording) return;
    final now = DateTime.now();
    final loop = RecordedLoop(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Луп ${state.loops.length + 1}',
      createdAt: now,
    );
    emit(state.copyWith(loops: [loop, ...state.loops], clearError: true));
  }

  Future<void> startRecording(String loopId) async {
    if (state.connection != GpsTelemetryConnectionState.connected) {
      emit(
        state.copyWith(
          errorMessage: 'Сначала подключитесь к устройству через шторку',
        ),
      );
      return;
    }
    if (state.isRecording) return;

    final loop = _findLoop(loopId);
    if (loop == null) return;

    await _recordSub?.cancel();
    _activeSession = await _sessionStore.startSession(loop.id);
    _recordStartedAt = DateTime.now();
    _recordingSamples = 0;
    emit(
      state.copyWith(
        isRecording: true,
        activeLoopId: loop.id,
        sampleCount: 0,
        clearError: true,
      ),
    );

    _recordSub = _telemetry.samples.listen((sample) {
      _sessionStore.appendSample(sample);
      _recordingSamples++;
      emit(
        state.copyWith(
          sampleCount: _recordingSamples,
          loops: _replaceLoop(
            loop.id,
            loop.copyWith(sampleCount: _recordingSamples),
          ),
        ),
      );
    });
  }

  Future<RecordedLoop?> stopRecording() async {
    if (!state.isRecording) return null;

    await _recordSub?.cancel();
    _recordSub = null;

    final activeId = state.activeLoopId;
    final sessionPath = _activeSession?.filePath;
    _activeSession = null;

    final savedPath = await _sessionStore.endSession();
    final path = savedPath ?? sessionPath;
    final currentLoop = activeId == null ? null : _findLoop(activeId);
    if (currentLoop == null || path == null) {
      emit(
        state.copyWith(
          isRecording: false,
          clearError: true,
          clearActiveLoop: true,
        ),
      );
      return null;
    }

    final startedAt = _recordStartedAt;
    _recordStartedAt = null;
    final duration = startedAt == null
        ? 0.0
        : DateTime.now().difference(startedAt).inMilliseconds / 1000;
    final savedLoop = currentLoop.copyWith(
      filePath: path,
      sampleCount: _recordingSamples,
      durationSec: duration,
    );
    await _sessionStore.upsertLoop(savedLoop);

    emit(
      state.copyWith(
        isRecording: false,
        loops: _replaceLoop(savedLoop.id, savedLoop),
        clearError: true,
        clearActiveLoop: true,
      ),
    );
    return savedLoop;
  }

  Future<void> exportLoop(RecordedLoop loop) async {
    final exported = await _sessionStore.exportLoop(loop);
    if (exported == null) {
      emit(state.copyWith(errorMessage: 'Не удалось экспортировать луп'));
      return;
    }
    emit(state.copyWith(errorMessage: 'Луп экспортирован', clearError: false));
  }

  RecordedLoop? _findLoop(String id) {
    for (final loop in state.loops) {
      if (loop.id == id) return loop;
    }
    return null;
  }

  List<RecordedLoop> _replaceLoop(String id, RecordedLoop updated) {
    return state.loops.map((loop) => loop.id == id ? updated : loop).toList();
  }

  @override
  Future<void> close() async {
    await _connSub?.cancel();
    await _recordSub?.cancel();
    return super.close();
  }
}
