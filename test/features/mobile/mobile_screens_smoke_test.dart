import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_screens.dart';

typedef _ScreenCase = ({String name, Widget Function() build});
typedef _ViewportCase = ({
  String name,
  Size size,
  double textScale,
  EdgeInsets safeInsets,
});

void main() {
  final screens = <_ScreenCase>[
    (name: 'M01 connect', build: () => const M01ConnectScreen()),
    (
      name: 'M02 device search empty',
      build: () => const M02DeviceSearchScreen(),
    ),
    (
      name: 'M02 device search found',
      build: () => const M02DeviceSearchScreen(
        devices: <SearchDeviceData>[
          SearchDeviceData(
            remoteId: 'smoke-gps',
            name: 'GPS Tracker',
            signalLabel: 'Сигнал отличный',
          ),
        ],
      ),
    ),
    (name: 'M03 home', build: () => const M03HomeScreen()),
    (
      name: 'M04 active series home',
      build: () => const M04ActiveSeriesHomeScreen(),
    ),
    (name: 'M05 fixed record limit', build: () => const M05RecordLimitScreen()),
    (
      name: 'M05B manual record limit',
      build: () => const M05BManualRecordLimitScreen(),
    ),
    (name: 'M06 preflight ready', build: () => const M06PreflightReadyScreen()),
    (
      name: 'M06B preflight weak GPS',
      build: () => const M06BPreflightWeakGpsScreen(),
    ),
    (name: 'M07 fixed recording', build: () => const M07FixedRecordingScreen()),
    (
      name: 'M07B manual recording',
      build: () => const M07BManualRecordingScreen(),
    ),
    (name: 'M08 saving', build: () => const M08SavingScreen()),
    (
      name: 'M09 measurement result',
      build: () => const M09MeasurementResultScreen(),
    ),
    (name: 'M10 add measurement', build: () => const M10AddMeasurementScreen()),
    (name: 'M11 series summary', build: () => const M11SeriesSummaryScreen()),
    (name: 'M12 series list', build: () => const M12SeriesListScreen()),
    (name: 'M13 history', build: () => const M13HistoryScreen()),
    (
      name: 'M14 measurement detail',
      build: () => const M14MeasurementDetailScreen(),
    ),
    (name: 'M15 analysis', build: () => const M15AnalysisScreen()),
    (name: 'M16 device', build: () => const M16DeviceScreen()),
    (
      name: 'E01 Bluetooth permission',
      build: () => const E01BluetoothPermissionScreen(),
    ),
    (name: 'E02 Bluetooth off', build: () => const E02BluetoothOffScreen()),
    (
      name: 'E03 weak GPS recording',
      build: () => const E03WeakGpsRecordingScreen(),
    ),
    (name: 'E04 connection lost', build: () => const E04ConnectionLostScreen()),
    (name: 'E05 early stop', build: () => const E05EarlyStopScreen()),
    (name: 'E06 save error', build: () => const E06SaveErrorScreen()),
  ];
  const viewports = <_ViewportCase>[
    (
      name: 'figma',
      size: Size(390, 844),
      textScale: 1,
      safeInsets: EdgeInsets.zero,
    ),
    (
      name: 'narrow',
      size: Size(360, 800),
      textScale: 1,
      safeInsets: EdgeInsets.zero,
    ),
    (
      name: 'narrow accessible',
      size: Size(360, 800),
      textScale: 1.2,
      safeInsets: EdgeInsets.zero,
    ),
    (
      name: 'android safe',
      size: Size(393, 873),
      textScale: 1,
      safeInsets: EdgeInsets.only(top: 24, bottom: 48),
    ),
    (
      name: 'android safe accessible',
      size: Size(393, 873),
      textScale: 1.2,
      safeInsets: EdgeInsets.only(top: 24, bottom: 48),
    ),
  ];

  test('the public mobile screen catalog contains all 26 states', () {
    expect(screens, hasLength(26));
  });

  for (final viewport in viewports) {
    for (final screen in screens) {
      testWidgets('${screen.name} renders on ${viewport.name}', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport.size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        final widget = screen.build();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  padding: viewport.safeInsets,
                  viewPadding: viewport.safeInsets,
                  textScaler: TextScaler.linear(viewport.textScale),
                ),
                child: child!,
              );
            },
            home: widget,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(widget.runtimeType), findsOneWidget);
        final renderingException = tester.takeException();
        expect(
          renderingException,
          isNull,
          reason: '${screen.name} overflowed or threw on ${viewport.name}',
        );
      });
    }
  }
}
