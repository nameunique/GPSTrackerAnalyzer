import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';

import 'support/mobile_test_fakes.dart';

void main() {
  testWidgets('connects, selects a limit, becomes ready, records and saves', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final telemetry = FakeGpsTelemetryRepository();
    final store = InMemorySessionStore();
    addTearDown(telemetry.close);

    await tester.pumpWidget(
      GpsTrackerApp(
        telemetryRepository: telemetry,
        sessionStore: store,
        analytics: RunAnalytics(),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);

    await tester.tap(find.text('Найти устройство'));
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
    expect(find.text('GPS Tracker Test'), findsOneWidget);

    await tester.tap(find.text('Подключить'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-M03')), findsOneWidget);

    telemetry.emitSample(mobileTestSample(receivedAt: DateTime.now()));
    await tester.pump();
    await tester.tap(find.text('Новый замер'));
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M05')), findsOneWidget);

    await tester.tap(find.text('100 записей'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Продолжить'));
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M06')), findsOneWidget);

    await tester.tap(find.text('Начать замер'));
    await tester.pump();
    expect(find.byKey(const ValueKey('screen-M07')), findsOneWidget);
    final recordingCubit = BlocProvider.of<RecordingCubit>(
      tester.element(find.byKey(const ValueKey('screen-M07'))),
    );

    final startedAt = DateTime.now();
    for (var index = 0; index < 99; index++) {
      telemetry.emitSample(
        mobileTestSample(
          receivedAt: startedAt.add(Duration(milliseconds: index * 100)),
          speedKmh: index * 1.1,
        ),
      );
    }
    expect(recordingCubit.state.recordingLimit, 100);
    expect(recordingCubit.state.sampleCount, 99);
    await tester.runAsync(recordingCubit.stopRecording);
    await tester.pump();

    expect(find.byKey(const ValueKey('screen-M08')), findsOneWidget);
    expect(store.loops, hasLength(1));
    final savedLoop = store.loops.single;
    expect(savedLoop.recordingMode, TrackRecordingMode.next100Samples);
    expect(savedLoop.sampleCount, 99);
    expect(savedLoop.filePath, isNotNull);
    expect(await store.loadSession(savedLoop.filePath!), hasLength(99));

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('screen-M09')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
