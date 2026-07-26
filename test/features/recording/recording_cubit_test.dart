import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';

void main() {
  group('TrackRecordingMode', () {
    test('maps the supported limits and keeps manual mode unlimited', () {
      expect(TrackRecordingMode.manual.sampleLimit, isNull);
      expect(TrackRecordingMode.next100Samples.sampleLimit, 100);
      expect(TrackRecordingMode.next200Samples.sampleLimit, 200);
      expect(TrackRecordingMode.next300Samples.sampleLimit, 300);
      expect(
        TrackRecordingMode.fromSampleLimit(null),
        TrackRecordingMode.manual,
      );
      expect(
        TrackRecordingMode.fromSampleLimit(100),
        TrackRecordingMode.next100Samples,
      );
      expect(
        TrackRecordingMode.fromSampleLimit(200),
        TrackRecordingMode.next200Samples,
      );
      expect(
        TrackRecordingMode.fromSampleLimit(300),
        TrackRecordingMode.next300Samples,
      );
    });

    test('reads legacy saved loops without distance or a known mode', () {
      final loop = RecordedLoop.fromJson({
        'id': 'legacy',
        'title': 'Трек 1',
        'createdAt': DateTime(2026).toIso8601String(),
        'sampleCount': 12,
        'durationSec': 4,
        'recordingMode': 'removed-mode',
      });

      expect(loop.recordingMode, TrackRecordingMode.manual);
      expect(loop.distanceMeters, 0);
    });
  });

  group('RecordingCubit', () {
    test('starts from the repository connection snapshot', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final cubit = RecordingCubit(telemetry, _FakeSessionStore());

      expect(cubit.state.connection, GpsTelemetryConnectionState.connected);

      await cubit.close();
      await telemetry.close();
    });

    for (final entry in <TrackRecordingMode, int>{
      TrackRecordingMode.next100Samples: 100,
      TrackRecordingMode.next200Samples: 200,
      TrackRecordingMode.next300Samples: 300,
    }.entries) {
      test('automatically saves at the ${entry.value}-sample limit', () async {
        final telemetry = _FakeTelemetryRepository(
          GpsTelemetryConnectionState.connected,
        );
        final store = _FakeSessionStore();
        final cubit = RecordingCubit(telemetry, store);
        cubit.addLoop();
        final loopId = cubit.state.loops.single.id;
        await cubit.updateRecordingMode(loopId, entry.key);
        await cubit.startRecording(loopId);

        final startedAt = DateTime(2026, 1, 1);
        for (var index = 0; index < entry.value; index++) {
          telemetry.emitSample(
            _sample(
              receivedAt: startedAt.add(Duration(seconds: index)),
              speedKmh: 36,
            ),
          );
        }

        await _waitUntil(() => !cubit.state.isRecording);
        expect(cubit.state.sampleCount, entry.value);
        expect(cubit.state.lastCompletedLoop?.sampleCount, entry.value);
        expect(
          cubit.state.lastCompletedLoop?.distanceMeters,
          closeTo((entry.value - 1) * 10, 0.0001),
        );
        expect(store.endCalls, 1);
        expect(store.upserted.single.sampleCount, entry.value);

        await cubit.close();
        await telemetry.close();
      });
    }

    test('manual mode records past 300 samples and close saves it', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore();
      final cubit = RecordingCubit(telemetry, store);
      cubit.addLoop();
      await cubit.startRecording(cubit.state.loops.single.id);

      final startedAt = DateTime(2026, 1, 1);
      for (var index = 0; index < 301; index++) {
        telemetry.emitSample(
          _sample(receivedAt: startedAt.add(Duration(seconds: index))),
        );
      }

      expect(cubit.state.isRecording, isTrue);
      expect(cubit.state.recordingLimit, isNull);
      await cubit.close();

      expect(store.endCalls, 1);
      expect(store.upserted.single.sampleCount, 301);
      await telemetry.close();
    });

    test(
      'disconnect pauses and reconnect resumes without losing data',
      () async {
        var now = DateTime(2026, 1, 1, 12);
        final telemetry = _FakeTelemetryRepository(
          GpsTelemetryConnectionState.connected,
        );
        final store = _FakeSessionStore();
        final cubit = RecordingCubit(telemetry, store, now: () => now);
        cubit.addLoop();
        await cubit.startRecording(cubit.state.loops.single.id);

        telemetry.emitSample(_sample(receivedAt: now, speedKmh: 36));
        now = now.add(const Duration(seconds: 6));
        telemetry.emitSample(_sample(receivedAt: now, speedKmh: 36));
        telemetry.emitConnection(GpsTelemetryConnectionState.idle);
        await _waitUntil(() => cubit.state.isPaused);

        expect(cubit.state.isRecording, isTrue);
        expect(cubit.state.sampleCount, 2);
        expect(cubit.state.elapsed, const Duration(seconds: 6));
        expect(store.endCalls, 0);

        telemetry.emitSample(
          _sample(receivedAt: now.add(const Duration(seconds: 1))),
        );
        expect(cubit.state.sampleCount, 2);

        now = now.add(const Duration(minutes: 2));
        telemetry.emitConnection(GpsTelemetryConnectionState.connected);
        await _waitUntil(() => !cubit.state.isPaused);
        now = now.add(const Duration(seconds: 4));
        telemetry.emitSample(_sample(receivedAt: now, speedKmh: 36));

        expect(cubit.state.sampleCount, 3);
        expect(cubit.state.elapsed, const Duration(seconds: 10));
        final saved = await cubit.stopRecording();
        expect(saved?.sampleCount, 3);
        expect(store.endCalls, 1);

        await cubit.close();
        await telemetry.close();
      },
    );

    test(
      'close finalizes a recording that is paused after disconnect',
      () async {
        final telemetry = _FakeTelemetryRepository(
          GpsTelemetryConnectionState.connected,
        );
        final store = _FakeSessionStore();
        final cubit = RecordingCubit(telemetry, store);
        cubit.addLoop();
        await cubit.startRecording(cubit.state.loops.single.id);
        telemetry.emitSample(_sample(receivedAt: DateTime(2026)));
        telemetry.emitConnection(GpsTelemetryConnectionState.error);
        await _waitUntil(() => cubit.state.isPaused);

        await cubit.close();

        expect(store.endCalls, 1);
        expect(store.upserted.single.sampleCount, 1);
        await telemetry.close();
      },
    );

    test('close also drains a session that is still starting', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore()
        ..startCompleter = Completer<ActiveSession>();
      final cubit = RecordingCubit(telemetry, store);
      cubit.addLoop();
      final starting = cubit.startRecording(cubit.state.loops.single.id);
      await _waitUntil(() => store.startCalls == 1);

      final closing = cubit.close();
      store.startCompleter!.complete(
        const ActiveSession(filePath: '/sessions/pending.jsonl'),
      );
      await starting;
      await closing;

      expect(store.endCalls, 1);
      expect(store.upserted, isEmpty);
      await telemetry.close();
    });

    test(
      'a startup load keeps loops created while storage is pending',
      () async {
        final telemetry = _FakeTelemetryRepository(
          GpsTelemetryConnectionState.connected,
        );
        final store = _FakeSessionStore()
          ..listCompleter = Completer<List<RecordedLoop>>();
        final cubit = RecordingCubit(telemetry, store);
        final loading = cubit.loadLoops();
        await _waitUntil(() => store.listCalls == 1);

        final draft = cubit.addLoop()!;
        final persisted = RecordedLoop(
          id: 'persisted',
          title: 'Сохранённый трек',
          createdAt: DateTime(2025),
          filePath: '/sessions/persisted.jsonl',
        );
        store.listCompleter!.complete([persisted]);
        await loading;

        expect(cubit.state.loops.map((loop) => loop.id), [
          draft.id,
          persisted.id,
        ]);

        await cubit.close();
        await telemetry.close();
      },
    );

    test('close waits for a pending startup load', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore()
        ..listCompleter = Completer<List<RecordedLoop>>();
      final cubit = RecordingCubit(telemetry, store);
      unawaited(cubit.loadLoops());
      await _waitUntil(() => store.listCalls == 1);

      var didClose = false;
      final closing = cubit.close().then((_) => didClose = true);
      await Future<void>.delayed(Duration.zero);
      expect(didClose, isFalse);

      store.listCompleter!.complete(const []);
      await closing;
      expect(cubit.isClosed, isTrue);
      await telemetry.close();
    });

    test('pending update does not emit after close', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final saved = RecordedLoop(
        id: 'saved',
        title: 'Сохранённый трек',
        createdAt: DateTime(2025),
        filePath: '/sessions/saved.jsonl',
      );
      final store = _FakeSessionStore()..upserted.add(saved);
      final cubit = RecordingCubit(telemetry, store);
      await cubit.loadLoops();
      store.upsertCompleter = Completer<void>();

      final updating = cubit.updateRecordingMode(
        saved.id,
        TrackRecordingMode.next100Samples,
      );
      await _waitUntil(() => store.upsertCalls == 1);
      await cubit.close();
      store.upsertCompleter!.completeError(StateError('late update'));

      await expectLater(updating, completes);
      await telemetry.close();
    });

    test('pending export does not emit after close', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore()..exportCompleter = Completer<String?>();
      final cubit = RecordingCubit(telemetry, store);
      final loop = RecordedLoop(
        id: 'saved',
        title: 'Сохранённый трек',
        createdAt: DateTime(2025),
        filePath: '/sessions/saved.jsonl',
      );

      final exporting = cubit.exportLoop(loop);
      await _waitUntil(() => store.exportCalls == 1);
      await cubit.close();
      store.exportCompleter!.completeError(StateError('late export'));

      await expectLater(exporting, completes);
      await telemetry.close();
    });

    test('append failure survives successful finalization', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore()..appendError = StateError('disk full');
      final cubit = RecordingCubit(telemetry, store);
      final loop = cubit.addLoop()!;
      await cubit.startRecording(loop.id);

      telemetry.emitSample(_sample(receivedAt: DateTime(2026)));
      await _waitUntil(() => !cubit.state.isRecording);

      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.lastCompletedLoop, isNotNull);
      expect(cubit.state.lastCompletedLoop!.sampleCount, 0);

      await cubit.close();
      await telemetry.close();
    });

    test('GPS stream failure survives successful finalization', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore();
      final cubit = RecordingCubit(telemetry, store);
      final loop = cubit.addLoop()!;
      await cubit.startRecording(loop.id);

      telemetry.emitSampleError(StateError('BLE stream stopped'));
      await _waitUntil(() => !cubit.state.isRecording);

      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.lastCompletedLoop, isNotNull);

      await cubit.close();
      await telemetry.close();
    });

    test('end-session failure remains visible after loop upsert', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore()..endError = StateError('flush failed');
      final cubit = RecordingCubit(telemetry, store);
      final loop = cubit.addLoop()!;
      await cubit.startRecording(loop.id);
      telemetry.emitSample(_sample(receivedAt: DateTime(2026)));

      final saved = await cubit.stopRecording();

      expect(saved, isNotNull);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.lastCompletedLoop, saved);

      await cubit.close();
      await telemetry.close();
    });

    test('loop upsert failure remains visible in the final state', () async {
      final telemetry = _FakeTelemetryRepository(
        GpsTelemetryConnectionState.connected,
      );
      final store = _FakeSessionStore()
        ..upsertError = StateError('index unavailable');
      final cubit = RecordingCubit(telemetry, store);
      final loop = cubit.addLoop()!;
      await cubit.startRecording(loop.id);
      telemetry.emitSample(_sample(receivedAt: DateTime(2026)));

      final saved = await cubit.stopRecording();

      expect(saved, isNotNull);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.lastCompletedLoop, saved);

      await cubit.close();
      await telemetry.close();
    });
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Condition was not reached in time');
}

GpsSample _sample({required DateTime receivedAt, double speedKmh = 0}) {
  return GpsSample(
    receivedAt: receivedAt,
    gpsSyncBits: 0,
    timeTicksSinceHourStart: 0,
    fixType: 3,
    numSv: 12,
    latitudeDeg: 55.75,
    longitudeDeg: 37.62,
    altitudeM: 150,
    speedKmh: speedKmh,
    headingDeg: 90,
    hdop: 1,
  );
}

class _FakeTelemetryRepository implements GpsTelemetryRepository {
  _FakeTelemetryRepository(this._currentConnectionState);

  final _samples = StreamController<GpsSample>.broadcast(sync: true);
  final _connections = StreamController<GpsTelemetryConnectionState>.broadcast(
    sync: true,
  );
  GpsTelemetryConnectionState _currentConnectionState;

  @override
  GpsTelemetryConnectionState get currentConnectionState =>
      _currentConnectionState;

  @override
  Stream<GpsTelemetryConnectionState> get connectionState async* {
    yield _currentConnectionState;
    yield* _connections.stream;
  }

  @override
  Stream<List<BleDeviceInfo>> get discoveredDevices => const Stream.empty();

  @override
  Stream<GpsSample> get samples => _samples.stream;

  @override
  Future<void> requestEnableBluetooth() async {}

  void emitConnection(GpsTelemetryConnectionState state) {
    _currentConnectionState = state;
    _connections.add(state);
  }

  void emitSample(GpsSample sample) => _samples.add(sample);

  void emitSampleError(Object error) =>
      _samples.addError(error, StackTrace.current);

  @override
  Future<void> connect(String remoteId) async {
    emitConnection(GpsTelemetryConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    emitConnection(GpsTelemetryConnectionState.idle);
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    emitConnection(GpsTelemetryConnectionState.scanning);
  }

  @override
  Future<void> stopScan() async {
    emitConnection(GpsTelemetryConnectionState.idle);
  }

  Future<void> close() async {
    await _samples.close();
    await _connections.close();
  }
}

class _FakeSessionStore implements SessionStore {
  final List<GpsSample> samples = [];
  final List<RecordedLoop> upserted = [];
  Completer<ActiveSession>? startCompleter;
  Completer<List<RecordedLoop>>? listCompleter;
  Completer<void>? upsertCompleter;
  Completer<String?>? exportCompleter;
  Object? appendError;
  Object? endError;
  Object? upsertError;
  int startCalls = 0;
  int endCalls = 0;
  int listCalls = 0;
  int upsertCalls = 0;
  int exportCalls = 0;
  String? _activePath;

  @override
  void appendSample(GpsSample sample) {
    final error = appendError;
    if (error != null) throw error;
    samples.add(sample);
  }

  @override
  Future<String?> endSession() async {
    endCalls++;
    final error = endError;
    if (error != null) throw error;
    final path = _activePath;
    _activePath = null;
    return path;
  }

  @override
  Future<String?> exportLoop(RecordedLoop loop) async {
    exportCalls++;
    final completer = exportCompleter;
    if (completer != null) return completer.future;
    return loop.filePath;
  }

  @override
  Future<List<GpsSample>> loadSession(String filePath) async => samples;

  @override
  Future<List<RecordedLoop>> listLoops() async {
    listCalls++;
    final completer = listCompleter;
    if (completer != null) return completer.future;
    return List<RecordedLoop>.from(upserted);
  }

  @override
  Future<ActiveSession> startSession(String loopId) async {
    startCalls++;
    _activePath = '/sessions/$loopId.jsonl';
    final completer = startCompleter;
    if (completer != null) return completer.future;
    return ActiveSession(filePath: _activePath!);
  }

  @override
  Future<void> upsertLoop(RecordedLoop loop) async {
    upsertCalls++;
    final completer = upsertCompleter;
    if (completer != null) await completer.future;
    final error = upsertError;
    if (error != null) throw error;
    upserted
      ..removeWhere((item) => item.id == loop.id)
      ..add(loop);
  }
}
