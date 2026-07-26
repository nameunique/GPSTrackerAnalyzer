import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/screens/library_screens.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

void main() {
  const realSeries = <ChartSeriesPoint>[
    ChartSeriesPoint(
      timeSec: 14,
      speedKmh: 80,
      altitudeM: 120,
      accelerationG: .2,
    ),
    ChartSeriesPoint(
      timeSec: 10,
      speedKmh: -5,
      altitudeM: 119,
      accelerationG: 0,
    ),
    ChartSeriesPoint(
      timeSec: 12,
      speedKmh: 40,
      altitudeM: 120,
      accelerationG: .3,
    ),
  ];

  group('MobileSpeedChartData', () {
    test('sorts and normalizes real timestamps and speeds', () {
      final data = MobileSpeedChartData.fromSeries(realSeries);

      expect(data.pointCount, 3);
      expect(data.durationSec, 4);
      expect(data.maxSpeedKmh, 80);
      expect(data.speedAxisMaxKmh, 100);
      expect(data.normalizedPoints, const <Offset>[
        Offset(0, 0),
        Offset(.5, .4),
        Offset(1, .8),
      ]);
    });

    test('ignores non-finite chart coordinates', () {
      const invalid = <ChartSeriesPoint>[
        ChartSeriesPoint(
          timeSec: double.nan,
          speedKmh: 10,
          altitudeM: 0,
          accelerationG: 0,
        ),
        ChartSeriesPoint(
          timeSec: 1,
          speedKmh: double.infinity,
          altitudeM: 0,
          accelerationG: 0,
        ),
      ];

      expect(MobileSpeedChartData.fromSeries(invalid).isEmpty, isTrue);
    });
  });

  testWidgets('renders real data with labels derived from its range', (
    tester,
  ) async {
    await _pump(tester, const MobileSpeedChart(series: realSeries));

    expect(find.byKey(const ValueKey('mobile-speed-chart')), findsOneWidget);
    expect(find.text('2 с'), findsOneWidget);
    expect(find.text('4 с'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    final semantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('mobile-speed-chart-semantics')),
    );
    expect(
      semantics.properties.label,
      'График скорости, точек: 3, до 4 секунд, максимум 80 километров в час',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses an honest empty state for an explicit empty series', (
    tester,
  ) async {
    await _pump(tester, const MobileSpeedChart(series: <ChartSeriesPoint>[]));

    expect(find.text('Недостаточно данных для графика'), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-speed-chart')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps preview data only when the series is omitted', (
    tester,
  ) async {
    await _pump(tester, const MobileSpeedChart());

    expect(find.byKey(const ValueKey('mobile-speed-chart')), findsOneWidget);
    expect(find.text('Недостаточно данных для графика'), findsNothing);
  });

  testWidgets('M14 and M15 expose analytics data without text overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pump(
      tester,
      const M14MeasurementDetailScreen(
        chartSeries: realSeries,
        acceleration: 'Не рассчитан',
      ),
      textScale: 1.2,
    );
    expect(find.byKey(const ValueKey('mobile-speed-chart')), findsOneWidget);
    expect(find.text('Не рассчитан'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pump(
      tester,
      const M15AnalysisScreen(
        result: 'Не рассчитан',
        chartSeries: <ChartSeriesPoint>[],
        analysisValid: false,
      ),
      textScale: 1.2,
    );
    expect(find.text('Недостаточно данных для графика'), findsOneWidget);
    expect(find.text('Не рассчитан'), findsOneWidget);
    expect(find.text('100 км/ч • Не рассчитан'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('chart painter repaints only when normalized points change', () {
    const first = MobileSpeedChartPainter(<Offset>[Offset.zero, Offset(1, 1)]);
    const same = MobileSpeedChartPainter(<Offset>[Offset.zero, Offset(1, 1)]);
    const changed = MobileSpeedChartPainter(<Offset>[
      Offset.zero,
      Offset(1, .5),
    ]);

    expect(same.shouldRepaint(first), isFalse);
    expect(changed.shouldRepaint(first), isTrue);
  });
}

Future<void> _pump(WidgetTester tester, Widget child, {double textScale = 1}) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, content) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(textScale)),
          child: content!,
        );
      },
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
