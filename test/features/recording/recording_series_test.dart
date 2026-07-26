import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';

import '../mobile/support/mobile_test_fakes.dart';

void main() {
  group('RecordedLoop series metadata', () {
    test('legacy JSON remains readable and gets safe defaults', () {
      final loop = RecordedLoop.fromJson(<String, dynamic>{
        'id': 'legacy-loop',
        'title': 'Legacy loop',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'sampleCount': 42,
        'durationSec': 8,
      });

      expect(loop.seriesId, isNull);
      expect(loop.isSeriesCompleted, isFalse);
    });

    test('series metadata survives JSON and copyWith round-trips', () {
      final original = RecordedLoop(
        id: 'loop-1',
        title: 'Measurement 1',
        createdAt: DateTime.utc(2026, 1, 1),
        filePath: '/sessions/loop-1.jsonl',
        sampleCount: 100,
        seriesId: 'series-1',
        isSeriesCompleted: true,
      );

      expect(RecordedLoop.fromJson(original.toJson()), original);

      final detached = original.copyWith(clearSeriesId: true);
      expect(detached.seriesId, isNull);
      expect(detached.isSeriesCompleted, isFalse);
      expect(detached.id, original.id);
    });
  });

  group('RecordingCubit series persistence', () {
    test(
      'addLoop accepts a series and draft assignment stays in memory',
      () async {
        final telemetry = FakeGpsTelemetryRepository(
          initialConnection: GpsTelemetryConnectionState.connected,
        );
        final store = InMemorySessionStore();
        final cubit = RecordingCubit(telemetry, store);

        final draft = cubit.addLoop(seriesId: ' series-a ')!;
        expect(draft.seriesId, 'series-a');

        await cubit.assignLoopToSeries(draft.id, 'series-b');

        expect(cubit.state.loops.single.seriesId, 'series-b');
        expect(cubit.state.loops.single.isSeriesCompleted, isFalse);
        expect(store.loops, isEmpty);

        await cubit.close();
        await telemetry.close();
      },
    );

    test('assigning a saved loop is persisted', () async {
      final saved = _savedLoop(id: 'saved-1');
      final telemetry = FakeGpsTelemetryRepository();
      final store = _TrackingMemoryStore(initialLoops: <RecordedLoop>[saved]);
      final cubit = RecordingCubit(telemetry, store);
      await cubit.loadLoops();

      await cubit.assignLoopToSeries(saved.id, 'series-a');

      expect(cubit.state.loops.single.seriesId, 'series-a');
      expect(store.loops.single.seriesId, 'series-a');
      expect(store.upsertedIds, <String>['saved-1']);

      await cubit.close();
      await telemetry.close();
    });

    test(
      'completing a series updates every loop but persists only saved ones',
      () async {
        final first = _savedLoop(id: 'saved-1', seriesId: 'series-a');
        final second = _savedLoop(
          id: 'saved-2',
          seriesId: 'series-a',
          createdAt: DateTime.utc(2026, 1, 2),
        );
        final unrelated = _savedLoop(
          id: 'saved-other',
          seriesId: 'series-b',
          createdAt: DateTime.utc(2026, 1, 3),
        );
        final telemetry = FakeGpsTelemetryRepository();
        final store = _TrackingMemoryStore(
          initialLoops: <RecordedLoop>[first, second, unrelated],
        );
        final cubit = RecordingCubit(telemetry, store);
        await cubit.loadLoops();
        final draft = cubit.addLoop(seriesId: 'series-a')!;

        await cubit.completeSeries('series-a');

        final seriesLoops = cubit.state.loops.where(
          (loop) => loop.seriesId == 'series-a',
        );
        expect(seriesLoops, hasLength(3));
        expect(seriesLoops.every((loop) => loop.isSeriesCompleted), isTrue);
        expect(
          cubit.state.loops
              .singleWhere((loop) => loop.id == unrelated.id)
              .isSeriesCompleted,
          isFalse,
        );
        expect(
          store.loops
              .where((loop) => loop.seriesId == 'series-a')
              .every((loop) => loop.isSeriesCompleted),
          isTrue,
        );
        expect(store.loops.any((loop) => loop.id == draft.id), isFalse);
        expect(store.upsertedIds, containsAll(<String>['saved-1', 'saved-2']));
        expect(store.upsertedIds, hasLength(2));

        await cubit.close();
        await telemetry.close();
      },
    );

    test('a late persistence failure cannot emit after close', () async {
      final saved = _savedLoop(id: 'saved-1');
      final telemetry = FakeGpsTelemetryRepository();
      final store = _BlockingMemoryStore(initialLoops: <RecordedLoop>[saved]);
      final cubit = RecordingCubit(telemetry, store);
      await cubit.loadLoops();

      final assigning = cubit.assignLoopToSeries(saved.id, 'series-a');
      await _waitUntil(() => store.upsertCalls == 1);
      await cubit.close();
      store.upsertGate.completeError(StateError('late write failure'));

      await expectLater(assigning, completes);
      expect(cubit.isClosed, isTrue);
      await telemetry.close();
    });

    test('series completion is not published when persistence fails', () async {
      final saved = _savedLoop(id: 'saved-1', seriesId: 'series-a');
      final telemetry = FakeGpsTelemetryRepository();
      final store = _FailingMemoryStore(initialLoops: <RecordedLoop>[saved]);
      final cubit = RecordingCubit(telemetry, store);
      await cubit.loadLoops();

      expect(await cubit.completeSeries('series-a'), isFalse);
      expect(cubit.state.loops.single.isSeriesCompleted, isFalse);
      expect(cubit.state.errorMessage, isNotNull);

      store.failWrites = false;
      expect(await cubit.completeSeries('series-a'), isTrue);
      expect(cubit.state.loops.single.isSeriesCompleted, isTrue);
      expect(cubit.state.errorMessage, isNull);

      await cubit.close();
      await telemetry.close();
    });
  });
}

RecordedLoop _savedLoop({
  required String id,
  String? seriesId,
  DateTime? createdAt,
}) {
  return RecordedLoop(
    id: id,
    title: id,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    filePath: '/sessions/$id.jsonl',
    seriesId: seriesId,
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Condition was not reached in time');
}

class _TrackingMemoryStore extends InMemorySessionStore {
  _TrackingMemoryStore({super.initialLoops});

  final List<String> upsertedIds = <String>[];

  @override
  Future<void> upsertLoop(RecordedLoop loop) async {
    upsertedIds.add(loop.id);
    await super.upsertLoop(loop);
  }
}

class _BlockingMemoryStore extends InMemorySessionStore {
  _BlockingMemoryStore({super.initialLoops});

  final Completer<void> upsertGate = Completer<void>();
  int upsertCalls = 0;

  @override
  Future<void> upsertLoop(RecordedLoop loop) async {
    upsertCalls++;
    await upsertGate.future;
    await super.upsertLoop(loop);
  }
}

class _FailingMemoryStore extends InMemorySessionStore {
  _FailingMemoryStore({super.initialLoops});

  bool failWrites = true;

  @override
  Future<void> upsertLoop(RecordedLoop loop) async {
    if (failWrites) throw StateError('index unavailable');
    await super.upsertLoop(loop);
  }
}
