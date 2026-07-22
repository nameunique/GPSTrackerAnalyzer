import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_screens.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';

import 'support/mobile_test_fakes.dart';

void main() {
  testWidgets('system back reuses and then discards a pending draft', (
    tester,
  ) async {
    _configurePhoneViewport(tester);
    final telemetry = FakeGpsTelemetryRepository(
      initialConnection: GpsTelemetryConnectionState.connected,
    );
    final store = InMemorySessionStore();
    addTearDown(telemetry.close);
    await _pumpApp(tester, telemetry, store);

    telemetry.emitSample(mobileTestSample(receivedAt: DateTime.now()));
    await tester.pump();
    final readyHome = tester.widget<M03HomeScreen>(find.byType(M03HomeScreen));
    expect(readyHome.gpsStatus, contains('±'));
    readyHome.onNewMeasurement!();
    await tester.pump();

    final firstPicker = tester.widget<M05RecordLimitScreen>(
      find.byType(M05RecordLimitScreen),
    );
    firstPicker.onContinue!(RecordLimit.records200);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M06')), findsOneWidget);

    final cubit = BlocProvider.of<RecordingCubit>(
      tester.element(find.byKey(const ValueKey('screen-M06'))),
    );
    expect(cubit.state.loops, hasLength(1));

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M05')), findsOneWidget);

    final reusedPicker = tester.widget<M05RecordLimitScreen>(
      find.byType(M05RecordLimitScreen),
    );
    reusedPicker.onContinue!(RecordLimit.records200);
    reusedPicker.onContinue!(RecordLimit.records200);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M06')), findsOneWidget);
    expect(cubit.state.loops, hasLength(1));

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M03')), findsOneWidget);
    expect(cubit.state.loops, isEmpty);
  });

  testWidgets('back during recording confirms stop and reconnect resumes UI', (
    tester,
  ) async {
    _configurePhoneViewport(tester);
    final telemetry = FakeGpsTelemetryRepository(
      initialConnection: GpsTelemetryConnectionState.connected,
    );
    final store = InMemorySessionStore();
    addTearDown(telemetry.close);
    await _pumpApp(tester, telemetry, store);
    await _startReadyRecording(tester, telemetry);

    final cubit = BlocProvider.of<RecordingCubit>(
      tester.element(find.byKey(const ValueKey('screen-M07'))),
    );
    expect(cubit.state.isRecording, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-E05')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M07')), findsOneWidget);

    telemetry.emitConnection(GpsTelemetryConnectionState.idle);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-E04')), findsOneWidget);
    expect(cubit.state.isPaused, isTrue);

    telemetry.emitConnection(GpsTelemetryConnectionState.connected);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M07')), findsOneWidget);
    expect(cubit.state.isPaused, isFalse);

    await tester.runAsync(cubit.stopRecording);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets(
    'GPS readiness requires configured fix, connection and fresh data',
    (tester) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(
        initialConnection: GpsTelemetryConnectionState.connected,
      );
      final store = InMemorySessionStore();
      addTearDown(telemetry.close);
      await _pumpApp(tester, telemetry, store);

      telemetry.emitSample(
        mobileTestSample(receivedAt: DateTime.now(), fixType: 2),
      );
      await tester.pump();
      tester
          .widget<M03HomeScreen>(find.byType(M03HomeScreen))
          .onNewMeasurement!();
      await tester.pump();
      tester
          .widget<M05RecordLimitScreen>(find.byType(M05RecordLimitScreen))
          .onContinue!(RecordLimit.records200);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M06B')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();

      telemetry.emitSample(
        mobileTestSample(receivedAt: DateTime.now(), fixType: 3),
      );
      await tester.pump();
      tester.widget<M03HomeScreen>(find.byType(M03HomeScreen)).onTabSelected!(
        MobileTab.device,
      );
      await tester.pump();

      var device = tester.widget<M16DeviceScreen>(find.byType(M16DeviceScreen));
      expect(device.dataActive, isTrue);
      expect(device.gpsReady, isTrue);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 1));
      device = tester.widget<M16DeviceScreen>(find.byType(M16DeviceScreen));
      expect(device.dataActive, isFalse);
      expect(device.gpsReady, isFalse);

      telemetry.emitSample(mobileTestSample(receivedAt: DateTime.now()));
      telemetry.emitConnection(GpsTelemetryConnectionState.idle);
      await tester.pump();
      device = tester.widget<M16DeviceScreen>(find.byType(M16DeviceScreen));
      expect(device.dataActive, isFalse);
      expect(device.gpsReady, isFalse);
    },
  );

  testWidgets('scan timeout keeps an empty completed state and can retry', (
    tester,
  ) async {
    _configurePhoneViewport(tester);
    final telemetry = FakeGpsTelemetryRepository(devices: const []);
    final store = InMemorySessionStore();
    addTearDown(telemetry.close);
    await _pumpApp(tester, telemetry, store);

    tester
        .widget<M01ConnectScreen>(find.byType(M01ConnectScreen))
        .onFindDevice!();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-empty-state')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-retry')), findsOneWidget);
    expect(telemetry.stopScanCalls, 1);

    await tester.tap(find.byKey(const ValueKey('search-retry')));
    await tester.pump();
    expect(telemetry.startScanCalls, 2);
    expect(
      tester
          .widget<M02DeviceSearchScreen>(find.byType(M02DeviceSearchScreen))
          .isSearching,
      isTrue,
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);
  });

  testWidgets('Bluetooth off and preflight disconnect use recovery screens', (
    tester,
  ) async {
    _configurePhoneViewport(tester);
    final telemetry = FakeGpsTelemetryRepository(
      initialConnection: GpsTelemetryConnectionState.connected,
    );
    final store = InMemorySessionStore();
    addTearDown(telemetry.close);
    await _pumpApp(tester, telemetry, store);

    telemetry.emitConnection(GpsTelemetryConnectionState.bluetoothOff);
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-E02')), findsOneWidget);

    tester
        .widget<E02BluetoothOffScreen>(find.byType(E02BluetoothOffScreen))
        .onEnable!();
    await tester.pumpAndSettle();
    tester
        .widget<M02DeviceSearchScreen>(find.byType(M02DeviceSearchScreen))
        .onConnect!('test-device');
    await tester.pumpAndSettle();
    tester
        .widget<M03HomeScreen>(find.byType(M03HomeScreen))
        .onNewMeasurement!();
    await tester.pump();
    tester
        .widget<M05RecordLimitScreen>(find.byType(M05RecordLimitScreen))
        .onContinue!(RecordLimit.records200);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-M06B')), findsOneWidget);

    telemetry.emitConnection(GpsTelemetryConnectionState.idle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-E04')), findsOneWidget);
    expect(
      tester
          .widget<E04ConnectionLostScreen>(find.byType(E04ConnectionLostScreen))
          .beforeStart,
      isTrue,
    );

    telemetry.emitConnection(GpsTelemetryConnectionState.connected);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-M06B')), findsOneWidget);
  });

  testWidgets('measurement detail returns to the series summary it came from', (
    tester,
  ) async {
    _configurePhoneViewport(tester);
    final telemetry = FakeGpsTelemetryRepository(
      initialConnection: GpsTelemetryConnectionState.connected,
    );
    final loop = RecordedLoop(
      id: 'completed-loop',
      title: 'Замер 1',
      createdAt: DateTime(2026, 7, 22),
      filePath: 'memory://sessions/completed-loop.jsonl',
      sampleCount: 100,
      seriesId: 'completed-series',
      isSeriesCompleted: true,
    );
    final store = InMemorySessionStore(initialLoops: <RecordedLoop>[loop]);
    addTearDown(telemetry.close);
    await _pumpApp(tester, telemetry, store);

    tester.widget<M03HomeScreen>(find.byType(M03HomeScreen)).onTabSelected!(
      MobileTab.series,
    );
    await tester.pump();
    tester
        .widget<M12SeriesListScreen>(find.byType(M12SeriesListScreen))
        .onOpenCompleted!();
    await tester.pumpAndSettle();

    var summary = tester.widget<M11SeriesSummaryScreen>(
      find.byType(M11SeriesSummaryScreen),
    );
    summary.onMeasurement!(0);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-M14')), findsOneWidget);

    tester
        .widget<M14MeasurementDetailScreen>(
          find.byType(M14MeasurementDetailScreen),
        )
        .onBack!();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-M11')), findsOneWidget);

    summary = tester.widget<M11SeriesSummaryScreen>(
      find.byType(M11SeriesSummaryScreen),
    );
    summary.onMeasurement!(0);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-M11')), findsOneWidget);
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

Future<void> _startReadyRecording(
  WidgetTester tester,
  FakeGpsTelemetryRepository telemetry,
) async {
  telemetry.emitSample(mobileTestSample(receivedAt: DateTime.now()));
  await tester.pump();
  tester.widget<M03HomeScreen>(find.byType(M03HomeScreen)).onNewMeasurement!();
  await tester.pump();
  tester
      .widget<M05RecordLimitScreen>(find.byType(M05RecordLimitScreen))
      .onContinue!(RecordLimit.records200);
  await tester.pump();
  await tester.pump();
  tester
      .widget<M06PreflightReadyScreen>(find.byType(M06PreflightReadyScreen))
      .onStart!();
  await tester.pump();
  await tester.pump();
  expect(find.byKey(const ValueKey('screen-M07')), findsOneWidget);
}
