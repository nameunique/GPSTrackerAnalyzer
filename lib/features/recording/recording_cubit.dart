import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_state.dart';

class RecordingCubit extends Cubit<RecordingState> {
  RecordingCubit(
    GpsTelemetryRepository telemetry,
    SessionStore sessionStore, {
    DateTime Function()? now,
  }) : _telemetry = telemetry,
       _sessionStore = sessionStore,
       _now = now ?? DateTime.now,
       super(RecordingState(connection: telemetry.currentConnectionState)) {
    _connSub = _telemetry.connectionState.listen(_onConnectionChanged);
  }

  final GpsTelemetryRepository _telemetry;
  final SessionStore _sessionStore;
  final DateTime Function() _now;

  StreamSubscription<GpsTelemetryConnectionState>? _connSub;
  StreamSubscription<GpsSample>? _recordSub;
  Timer? _elapsedTimer;

  ActiveSession? _activeSession;
  DateTime? _recordStartedAt;
  Duration _elapsedBeforePause = Duration.zero;
  GpsSample? _previousSample;
  int _recordingSamples = 0;
  double _recordingDistanceMeters = 0;
  Future<void>? _startFuture;
  Future<RecordedLoop?>? _stopFuture;
  Future<void>? _loadFuture;
  int _loopsRevision = 0;
  String? _recordingFailureMessage;
  bool _isClosing = false;

  /// Kept for callers compiled against the original 100-sample flow.
  static const int nextSamplesLimit = 100;
  static const List<int> supportedSampleLimits = [100, 200, 300];
  static const Duration _maxDistanceIntegrationGap = Duration(seconds: 30);

  void _onConnectionChanged(GpsTelemetryConnectionState connection) {
    if (isClosed) return;

    emit(state.copyWith(connection: connection));

    if (!state.isRecording) return;
    if (connection == GpsTelemetryConnectionState.connected && state.isPaused) {
      unawaited(resumeRecording());
    } else if (connection != GpsTelemetryConnectionState.connected &&
        !state.isPaused) {
      unawaited(pauseRecording());
    }
  }

  Future<void> loadLoops() {
    final pending = _loadFuture;
    if (pending != null) return pending;
    if (_isClosing || isClosed) return Future<void>.value();

    final operation = _loadLoopsInternal();
    _loadFuture = operation;
    return operation.whenComplete(() {
      if (identical(_loadFuture, operation)) {
        _loadFuture = null;
      }
    });
  }

  Future<void> _loadLoopsInternal() async {
    final revisionAtStart = _loopsRevision;
    try {
      final loops = await _sessionStore.listLoops();
      if (_isClosing || isClosed) return;

      final nextLoops = revisionAtStart == _loopsRevision
          ? loops
          : _mergeLoadedLoops(state.loops, loops);
      emit(state.copyWith(loops: nextLoops, clearError: true));
    } catch (e) {
      if (_isClosing || isClosed) return;
      emit(state.copyWith(errorMessage: 'Загрузка треков: $e'));
    }
  }

  RecordedLoop? addLoop({String? seriesId}) {
    if (_isClosing || isClosed || state.isRecording) return null;
    final now = _now();
    final baseId = now.microsecondsSinceEpoch.toString();
    var id = baseId;
    var suffix = 1;
    while (_findLoop(id) != null) {
      id = '$baseId-${suffix++}';
    }
    final loop = RecordedLoop(
      id: id,
      title: 'Замер ${state.loops.length + 1}',
      createdAt: now,
      seriesId: _normalizeSeriesId(seriesId),
    );
    _loopsRevision++;
    emit(
      state.copyWith(
        loops: [loop, ...state.loops],
        recordingMode: loop.recordingMode,
        clearError: true,
      ),
    );
    return loop;
  }

  /// Associates either a draft or an already saved loop with a series.
  /// Drafts remain in memory; saved loops are also updated in the index.
  Future<void> assignLoopToSeries(String loopId, String seriesId) async {
    if (_isClosing || isClosed) return;

    final normalizedSeriesId = _normalizeSeriesId(seriesId);
    final loop = _findLoop(loopId);
    if (normalizedSeriesId == null ||
        loop == null ||
        state.activeLoopId == loopId) {
      return;
    }

    final updated = loop.copyWith(
      seriesId: normalizedSeriesId,
      isSeriesCompleted: false,
    );
    if (updated != loop) {
      _loopsRevision++;
      emit(
        state.copyWith(
          loops: _replaceLoop(loopId, updated),
          lastCompletedLoop: state.lastCompletedLoop?.id == loopId
              ? updated
              : null,
          clearError: true,
        ),
      );
    }

    if (!updated.isSaved) return;
    try {
      await _sessionStore.upsertLoop(updated);
    } catch (e) {
      if (_isClosing || isClosed) return;
      emit(state.copyWith(errorMessage: 'Сохранение серии замеров: $e'));
    }
  }

  /// Marks every loop in [seriesId] as completed and persists saved loops.
  /// An actively recording loop is never finalized behind the user's back.
  Future<bool> completeSeries(String seriesId) async {
    if (_isClosing || isClosed) return false;

    final normalizedSeriesId = _normalizeSeriesId(seriesId);
    if (normalizedSeriesId == null) return false;

    final matchingLoops = state.loops
        .where((loop) => loop.seriesId == normalizedSeriesId)
        .toList(growable: false);
    if (matchingLoops.isEmpty ||
        matchingLoops.any((loop) => loop.id == state.activeLoopId)) {
      return false;
    }

    final updatedById = <String, RecordedLoop>{
      for (final loop in matchingLoops)
        loop.id: loop.copyWith(isSeriesCompleted: true),
    };
    Object? firstPersistenceError;
    for (final updated in updatedById.values.where((loop) => loop.isSaved)) {
      try {
        // FileSessionStore performs a read/modify/write, so keep these writes
        // sequential to avoid one loop overwriting another in the index.
        await _sessionStore.upsertLoop(updated);
      } catch (e) {
        firstPersistenceError ??= e;
      }
    }

    if (_isClosing || isClosed) return false;
    if (firstPersistenceError != null) {
      emit(
        state.copyWith(
          errorMessage:
              'Не удалось завершить серию замеров: $firstPersistenceError',
        ),
      );
      return false;
    }

    final updatedLoops = state.loops
        .map((loop) => updatedById[loop.id] ?? loop)
        .toList(growable: false);
    final hasStateChanges =
        updatedLoops != state.loops &&
        updatedLoops.asMap().entries.any(
          (entry) => entry.value != state.loops[entry.key],
        );
    final lastCompletedLoop = state.lastCompletedLoop;
    if (hasStateChanges) _loopsRevision++;
    emit(
      state.copyWith(
        loops: hasStateChanges ? updatedLoops : state.loops,
        lastCompletedLoop: lastCompletedLoop == null
            ? null
            : updatedById[lastCompletedLoop.id],
        clearError: true,
      ),
    );
    return true;
  }

  /// Removes an in-memory placeholder that has never started recording.
  /// Saved or active loops are deliberately protected from accidental loss.
  bool discardDraftLoop(String loopId) {
    final loop = _findLoop(loopId);
    if (loop == null) return true;
    if (state.isRecording ||
        state.activeLoopId == loopId ||
        loop.isSaved ||
        loop.sampleCount != 0) {
      return false;
    }

    _loopsRevision++;
    emit(
      state.copyWith(
        loops: state.loops
            .where((candidate) => candidate.id != loopId)
            .toList(growable: false),
        clearError: true,
      ),
    );
    return true;
  }

  Future<void> updateRecordingMode(
    String loopId,
    TrackRecordingMode recordingMode,
  ) async {
    if (_isClosing || isClosed) return;
    final loop = _findLoop(loopId);
    if (loop == null || state.activeLoopId == loopId) return;

    final updated = loop.copyWith(recordingMode: recordingMode);
    _loopsRevision++;
    emit(
      state.copyWith(
        loops: _replaceLoop(loopId, updated),
        recordingMode: recordingMode,
        clearError: true,
      ),
    );
    if (updated.isSaved) {
      try {
        await _sessionStore.upsertLoop(updated);
      } catch (e) {
        if (_isClosing || isClosed) return;
        emit(state.copyWith(errorMessage: 'Сохранение режима записи: $e'));
      }
    }
  }

  Future<void> startRecording(String loopId) {
    final pending = _startFuture;
    if (pending != null) return pending;
    if (_isClosing) return Future<void>.value();

    final operation = _startRecordingInternal(loopId);
    _startFuture = operation;
    return operation.whenComplete(() {
      if (identical(_startFuture, operation)) {
        _startFuture = null;
      }
    });
  }

  Future<void> _startRecordingInternal(String loopId) async {
    if (state.connection != GpsTelemetryConnectionState.connected) {
      emit(
        state.copyWith(
          errorMessage: 'Сначала подключитесь к устройству через Bluetooth',
        ),
      );
      return;
    }
    if (state.isRecording || _stopFuture != null) return;

    final loop = _findLoop(loopId);
    if (loop == null) return;

    await _recordSub?.cancel();
    _recordSub = null;
    if (_isClosing) return;

    try {
      _activeSession = await _sessionStore.startSession(loop.id);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Не удалось начать запись: $e'));
      return;
    }

    if (_isClosing) {
      try {
        await _sessionStore.endSession();
      } catch (_) {
        // close() must still be able to release the cubit resources.
      } finally {
        _activeSession = null;
      }
      return;
    }

    // The connection may have disappeared while storage was being prepared.
    if (state.connection != GpsTelemetryConnectionState.connected) {
      await _sessionStore.endSession();
      _activeSession = null;
      emit(
        state.copyWith(errorMessage: 'Соединение потеряно до начала записи'),
      );
      return;
    }

    _recordStartedAt = _now();
    _elapsedBeforePause = Duration.zero;
    _recordingSamples = 0;
    _recordingDistanceMeters = 0;
    _previousSample = null;
    _recordingFailureMessage = null;
    emit(
      state.copyWith(
        isRecording: true,
        isPaused: false,
        activeLoopId: loop.id,
        sampleCount: 0,
        elapsed: Duration.zero,
        distanceMeters: 0,
        recordingMode: loop.recordingMode,
        clearLatestSample: true,
        clearLastCompletedLoop: true,
        clearError: true,
      ),
    );

    _startElapsedTimer();
    _listenForSamples();
  }

  void _listenForSamples() {
    _recordSub = _telemetry.samples.listen(
      _onSample,
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) {
          _recordingFailureMessage = 'Ошибка потока GPS: $error';
          emit(state.copyWith(errorMessage: _recordingFailureMessage));
          unawaited(stopRecording());
        }
      },
    );
  }

  Future<void> pauseRecording() async {
    if (!state.isRecording || state.isPaused) return;

    final elapsed = _elapsedSinceStart();
    _elapsedBeforePause = elapsed;
    _recordStartedAt = null;
    _previousSample = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    final recordSub = _recordSub;
    _recordSub = null;
    emit(state.copyWith(isPaused: true, elapsed: elapsed));
    await recordSub?.cancel();
  }

  Future<void> resumeRecording() async {
    if (!state.isRecording ||
        !state.isPaused ||
        state.connection != GpsTelemetryConnectionState.connected ||
        _stopFuture != null) {
      return;
    }

    final staleRecordSub = _recordSub;
    _recordSub = null;
    await staleRecordSub?.cancel();
    if (!state.isRecording ||
        !state.isPaused ||
        state.connection != GpsTelemetryConnectionState.connected ||
        _stopFuture != null) {
      return;
    }
    _recordStartedAt = _now();
    emit(state.copyWith(isPaused: false, clearError: true));
    _startElapsedTimer();
    _listenForSamples();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed && state.isRecording && !state.isPaused) {
        emit(state.copyWith(elapsed: _elapsedSinceStart()));
      }
    });
  }

  void _onSample(GpsSample sample) {
    if (isClosed ||
        !state.isRecording ||
        state.isPaused ||
        _stopFuture != null) {
      return;
    }

    try {
      _sessionStore.appendSample(sample);
    } catch (e) {
      _recordingFailureMessage = 'Не удалось записать GPS-данные: $e';
      emit(state.copyWith(errorMessage: _recordingFailureMessage));
      unawaited(stopRecording());
      return;
    }

    final previous = _previousSample;
    if (previous != null) {
      final gap = sample.receivedAt.difference(previous.receivedAt);
      if (!gap.isNegative &&
          gap > Duration.zero &&
          gap <= _maxDistanceIntegrationGap) {
        final seconds = gap.inMicroseconds / Duration.microsecondsPerSecond;
        final meanSpeedMps = (previous.speedMps + sample.speedMps) / 2;
        _recordingDistanceMeters += meanSpeedMps * seconds;
      }
    }
    _previousSample = sample;
    _recordingSamples++;

    final elapsed = _elapsedSinceStart();
    final activeLoop = _findLoop(state.activeLoopId ?? '');
    final loops = activeLoop == null
        ? state.loops
        : _replaceLoop(
            activeLoop.id,
            activeLoop.copyWith(
              sampleCount: _recordingSamples,
              durationSec: elapsed.inMilliseconds / 1000,
              distanceMeters: _recordingDistanceMeters,
            ),
          );

    if (!identical(loops, state.loops)) {
      _loopsRevision++;
    }
    emit(
      state.copyWith(
        sampleCount: _recordingSamples,
        latestSample: sample,
        elapsed: elapsed,
        distanceMeters: _recordingDistanceMeters,
        loops: loops,
      ),
    );

    final limit = state.recordingLimit;
    if (limit != null && _recordingSamples >= limit) {
      unawaited(stopRecording());
    }
  }

  Duration _elapsedSinceStart() {
    final startedAt = _recordStartedAt;
    if (startedAt == null) return _elapsedBeforePause;
    final currentSegment = _now().difference(startedAt);
    if (currentSegment.isNegative) return _elapsedBeforePause;
    return _elapsedBeforePause + currentSegment;
  }

  Future<RecordedLoop?> stopRecording() {
    final pending = _stopFuture;
    if (pending != null) return pending;
    if (!state.isRecording && _activeSession == null) {
      return Future<RecordedLoop?>.value();
    }

    // Deferring the actual cancellation avoids cancelling the GPS stream from
    // inside its own synchronous sample callback. `_stopFuture` is assigned
    // immediately, so any following samples are still rejected at the limit.
    final operation = Future<RecordedLoop?>.microtask(_stopRecordingInternal);
    _stopFuture = operation;
    return operation.whenComplete(() {
      if (identical(_stopFuture, operation)) {
        _stopFuture = null;
      }
    });
  }

  Future<RecordedLoop?> _stopRecordingInternal() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;

    await _recordSub?.cancel();
    _recordSub = null;

    final activeId = state.activeLoopId;
    final sessionPath = _activeSession?.filePath;
    final elapsed = _elapsedSinceStart();
    final sampleCount = _recordingSamples;
    final distanceMeters = _recordingDistanceMeters;
    String? saveError = _recordingFailureMessage;
    String? savedPath;

    try {
      savedPath = await _sessionStore.endSession();
    } catch (e) {
      saveError = 'Не удалось завершить файл записи: $e';
    }

    _activeSession = null;
    _recordStartedAt = null;
    _elapsedBeforePause = Duration.zero;
    _previousSample = null;

    final path = savedPath ?? sessionPath;
    final currentLoop = activeId == null ? null : _findLoop(activeId);
    if (currentLoop == null || path == null) {
      final finalError = saveError ?? 'Не удалось сохранить запись';
      _recordingFailureMessage = null;
      emit(
        state.copyWith(
          isRecording: false,
          isPaused: false,
          elapsed: elapsed,
          distanceMeters: distanceMeters,
          errorMessage: finalError,
          clearActiveLoop: true,
        ),
      );
      return null;
    }

    final savedLoop = currentLoop.copyWith(
      filePath: path,
      sampleCount: sampleCount,
      durationSec: elapsed.inMilliseconds / 1000,
      distanceMeters: distanceMeters,
    );
    try {
      await _sessionStore.upsertLoop(savedLoop);
    } catch (e) {
      saveError = 'Не удалось сохранить трек: $e';
    }

    _recordingFailureMessage = null;
    _loopsRevision++;
    emit(
      state.copyWith(
        isRecording: false,
        isPaused: false,
        loops: _replaceLoop(savedLoop.id, savedLoop),
        sampleCount: sampleCount,
        elapsed: elapsed,
        distanceMeters: distanceMeters,
        lastCompletedLoop: savedLoop,
        errorMessage: saveError,
        clearError: saveError == null,
        clearActiveLoop: true,
      ),
    );
    return savedLoop;
  }

  Future<void> exportLoop(RecordedLoop loop) async {
    if (_isClosing || isClosed) return;

    String? exported;
    try {
      exported = await _sessionStore.exportLoop(loop);
    } catch (e) {
      if (_isClosing || isClosed) return;
      emit(state.copyWith(errorMessage: 'Ошибка экспорта трека: $e'));
      return;
    }
    if (_isClosing || isClosed) return;
    if (exported == null) {
      emit(state.copyWith(errorMessage: 'Не удалось экспортировать трек'));
      return;
    }
    emit(state.copyWith(errorMessage: 'Трек экспортирован', clearError: false));
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

  String? _normalizeSeriesId(String? seriesId) {
    final normalized = seriesId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  List<RecordedLoop> _mergeLoadedLoops(
    List<RecordedLoop> current,
    List<RecordedLoop> loaded,
  ) {
    final currentIds = current.map((loop) => loop.id).toSet();
    return [
      ...current,
      ...loaded.where((loop) => !currentIds.contains(loop.id)),
    ];
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    await _connSub?.cancel();
    _connSub = null;
    await _loadFuture;
    await _startFuture;
    await stopRecording();
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    await _recordSub?.cancel();
    _recordSub = null;
    return super.close();
  }
}
