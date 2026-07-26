import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_screens.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';

import 'support/mobile_test_fakes.dart';

void main() {
  testWidgets(
    'manual mode stays active beyond 300 samples and saves from confirmation',
    (tester) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(
        initialConnection: GpsTelemetryConnectionState.connected,
      );
      final store = InMemorySessionStore();
      addTearDown(telemetry.close);
      await _pumpApp(tester, telemetry, store);

      await _openManualPreflight(tester, telemetry);
      expect(find.byKey(const ValueKey('screen-M05B')), findsNothing);
      expect(find.byKey(const ValueKey('screen-M06')), findsOneWidget);

      final cubit = BlocProvider.of<RecordingCubit>(
        tester.element(find.byKey(const ValueKey('screen-M06'))),
      );
      expect(cubit.state.loops.single.recordingMode, TrackRecordingMode.manual);

      tester
          .widget<M06PreflightReadyScreen>(find.byType(M06PreflightReadyScreen))
          .onStart!();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M07B')), findsOneWidget);

      final receivedAt = DateTime.now();
      for (var index = 0; index < 301; index++) {
        telemetry.emitSample(
          mobileTestSample(receivedAt: receivedAt, speedKmh: 20 + (index % 80)),
        );
      }
      await tester.pump();

      expect(cubit.state.isRecording, isTrue);
      expect(cubit.state.recordingLimit, isNull);
      expect(cubit.state.sampleCount, 301);
      expect(find.byKey(const ValueKey('screen-M07B')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-E05')), findsOneWidget);
      final confirmation = tester.widget<E05EarlyStopScreen>(
        find.byType(E05EarlyStopScreen),
      );
      expect(confirmation.manual, isTrue);
      expect(confirmation.recorded, 301);

      expect(confirmation.onFinishAndSave, isNotNull);
      await tester.runAsync(cubit.stopRecording);
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M08')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('screen-M09')), findsOneWidget);

      expect(store.loops, hasLength(1));
      expect(store.loops.single.recordingMode, TrackRecordingMode.manual);
      expect(store.loops.single.sampleCount, 301);
      expect(
        await store.loadSession(store.loops.single.filePath!),
        hasLength(301),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'two measurements share a persisted series and completed counts reach M12',
    (tester) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(
        initialConnection: GpsTelemetryConnectionState.connected,
      );
      final store = InMemorySessionStore();
      addTearDown(telemetry.close);
      await _pumpApp(tester, telemetry, store);

      await _openManualPreflight(tester, telemetry);
      await _startAndSaveManualMeasurement(tester, telemetry, sampleCount: 3);

      final firstResult = tester.widget<M09MeasurementResultScreen>(
        find.byType(M09MeasurementResultScreen),
      );
      firstResult.onAddMeasurement!();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M10')), findsOneWidget);
      final addMeasurement = tester.widget<M10AddMeasurementScreen>(
        find.byType(M10AddMeasurementScreen),
      );
      expect(addMeasurement.savedMeasurements, 1);
      addMeasurement.onContinue!(RecordLimit.manual);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M06')), findsOneWidget);

      await _startAndSaveManualMeasurement(tester, telemetry, sampleCount: 4);
      expect(store.loops, hasLength(2));
      expect(store.loops.map((loop) => loop.sampleCount), containsAll([3, 4]));

      final secondResult = tester.widget<M09MeasurementResultScreen>(
        find.byType(M09MeasurementResultScreen),
      );
      secondResult.onFinishSeries!();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M11')), findsOneWidget);

      final summary = tester.widget<M11SeriesSummaryScreen>(
        find.byType(M11SeriesSummaryScreen),
      );
      expect(summary.measurementCount, 2);
      expect(summary.recordCount, 7);
      expect(summary.completed, isTrue);

      final seriesIds = store.loops.map((loop) => loop.seriesId).toSet();
      expect(seriesIds, hasLength(1));
      expect(seriesIds.single, isNotNull);
      expect(store.loops.every((loop) => loop.isSeriesCompleted), isTrue);

      summary.onDone!();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M12')), findsOneWidget);
      final seriesList = tester.widget<M12SeriesListScreen>(
        find.byType(M12SeriesListScreen),
      );
      expect(seriesList.hasActiveSeries, isFalse);
      expect(seriesList.hasCompletedSeries, isTrue);
      expect(seriesList.completedMeasurementCount, 2);
      expect(seriesList.completedRecordCount, 7);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history filters rows and a series row opens its summary', (
    tester,
  ) async {
    _configurePhoneViewport(tester);
    final telemetry = FakeGpsTelemetryRepository(
      initialConnection: GpsTelemetryConnectionState.connected,
    );
    final now = DateTime(2026, 7, 22, 12);
    final store = InMemorySessionStore(
      initialLoops: <RecordedLoop>[
        RecordedLoop(
          id: 'series-measurement-2',
          title: 'Series measurement 2',
          createdAt: now.add(const Duration(minutes: 2)),
          filePath: 'memory://sessions/series-measurement-2.jsonl',
          sampleCount: 7,
          recordingMode: TrackRecordingMode.manual,
          seriesId: 'completed-series',
          isSeriesCompleted: true,
        ),
        RecordedLoop(
          id: 'series-measurement-1',
          title: 'Series measurement 1',
          createdAt: now.add(const Duration(minutes: 1)),
          filePath: 'memory://sessions/series-measurement-1.jsonl',
          sampleCount: 5,
          recordingMode: TrackRecordingMode.manual,
          seriesId: 'completed-series',
          isSeriesCompleted: true,
        ),
        RecordedLoop(
          id: 'standalone-measurement',
          title: 'Standalone measurement',
          createdAt: now,
          filePath: 'memory://sessions/standalone-measurement.jsonl',
          sampleCount: 3,
          recordingMode: TrackRecordingMode.manual,
        ),
      ],
    );
    addTearDown(telemetry.close);
    await _pumpApp(tester, telemetry, store);
    await tester.pump();

    tester.widget<M03HomeScreen>(find.byType(M03HomeScreen)).onTabSelected!(
      MobileTab.history,
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('screen-M13')), findsOneWidget);
    var history = tester.widget<M13HistoryScreen>(
      find.byType(M13HistoryScreen),
    );
    expect(history.measurements, hasLength(3));
    expect(history.series, hasLength(1));
    expect(find.byType(MobileMeasurementRow), findsNWidgets(4));

    _selectHistoryFilter(tester, 'Замеры');
    await tester.pump();
    expect(find.byType(MobileMeasurementRow), findsNWidgets(3));

    _selectHistoryFilter(tester, 'Серии');
    await tester.pump();
    expect(find.byType(MobileMeasurementRow), findsOneWidget);

    tester
        .widget<MobileMeasurementRow>(find.byType(MobileMeasurementRow))
        .onTap!();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M11')), findsOneWidget);
    final summary = tester.widget<M11SeriesSummaryScreen>(
      find.byType(M11SeriesSummaryScreen),
    );
    expect(summary.measurementCount, 2);
    expect(summary.recordCount, 12);
    expect(summary.completed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

void _configurePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeGpsTelemetryRepository telemetry,
  InMemorySessionStore store,
) async {
  await tester.pumpWidget(
    GpsTrackerApp(
      telemetryRepository: telemetry,
      sessionStore: store,
      analytics: RunAnalytics(),
    ),
  );
  await tester.pump();
}

Future<void> _openManualPreflight(
  WidgetTester tester,
  FakeGpsTelemetryRepository telemetry,
) async {
  telemetry.emitSample(mobileTestSample(receivedAt: DateTime.now()));
  await tester.pump();
  tester.widget<M03HomeScreen>(find.byType(M03HomeScreen)).onNewMeasurement!();
  await tester.pump();
  expect(find.byKey(const ValueKey('screen-M05')), findsOneWidget);

  tester
      .widget<M05RecordLimitScreen>(find.byType(M05RecordLimitScreen))
      .onSelectionChanged!(RecordLimit.manual);
  await tester.pump();
  expect(find.byKey(const ValueKey('screen-M05B')), findsOneWidget);

  tester
      .widget<M05BManualRecordLimitScreen>(
        find.byType(M05BManualRecordLimitScreen),
      )
      .onContinue!(RecordLimit.manual);
  await tester.pump();
  await tester.pump();
}

Future<void> _startAndSaveManualMeasurement(
  WidgetTester tester,
  FakeGpsTelemetryRepository telemetry, {
  required int sampleCount,
}) async {
  tester
      .widget<M06PreflightReadyScreen>(find.byType(M06PreflightReadyScreen))
      .onStart!();
  await tester.pump();
  await tester.pump();
  expect(find.byKey(const ValueKey('screen-M07B')), findsOneWidget);

  final receivedAt = DateTime.now();
  for (var index = 0; index < sampleCount; index++) {
    telemetry.emitSample(
      mobileTestSample(receivedAt: receivedAt, speedKmh: 30 + index.toDouble()),
    );
  }
  await tester.pump();

  await tester.binding.handlePopRoute();
  await tester.pump();
  final confirmation = tester.widget<E05EarlyStopScreen>(
    find.byType(E05EarlyStopScreen),
  );
  expect(confirmation.manual, isTrue);
  expect(confirmation.recorded, sampleCount);
  final cubit = BlocProvider.of<RecordingCubit>(
    tester.element(find.byType(E05EarlyStopScreen)),
  );
  expect(confirmation.onFinishAndSave, isNotNull);
  await tester.runAsync(cubit.stopRecording);
  await tester.pump();
  expect(find.byKey(const ValueKey('screen-M08')), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 700));
  expect(find.byKey(const ValueKey('screen-M09')), findsOneWidget);
}

void _selectHistoryFilter(WidgetTester tester, String label) {
  final filter = find
      .ancestor(of: find.text(label).first, matching: find.byType(InkWell))
      .first;
  tester.widget<InkWell>(filter).onTap!();
}
