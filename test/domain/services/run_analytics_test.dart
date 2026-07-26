import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';

void main() {
  group('RunAnalytics acceleration splits', () {
    test('computes splits when the run starts at standstill', () {
      final report = RunAnalytics().compute([
        _sample(second: 0, speedKmh: 0),
        _sample(second: 5, speedKmh: 50),
        _sample(second: 10, speedKmh: 100),
      ]);

      expect(report.splitTimesSec[10], closeTo(1, 0.0001));
      expect(report.splitTimesSec[50], closeTo(5, 0.0001));
      expect(report.splitTimesSec[100], closeTo(10, 0.0001));
      expect(report.time0to100Sec, closeTo(10, 0.0001));
    });

    test('accepts the one km/h standing-start boundary', () {
      final report = RunAnalytics().compute([
        _sample(second: 0, speedKmh: 1),
        _sample(second: 10, speedKmh: 101),
      ]);

      expect(report.splitTimesSec[10], closeTo(0.9, 0.0001));
      expect(report.splitTimesSec[100], closeTo(9.9, 0.0001));
      expect(report.time0to100Sec, closeTo(9.9, 0.0001));
    });

    test('returns null splits when recording starts above one km/h', () {
      final report = RunAnalytics().compute([
        _sample(second: 0, speedKmh: 20),
        _sample(second: 4, speedKmh: 60),
        _sample(second: 8, speedKmh: 110),
      ]);

      expect(report.splitTimesSec.values, everyElement(isNull));
      expect(report.time0to100Sec, isNull);
      expect(report.maxSpeedKmh, 110);
      expect(report.series, hasLength(3));
    });

    test('uses chronological first sample for start validation', () {
      final report = RunAnalytics().compute([
        _sample(second: 8, speedKmh: 110),
        _sample(second: 0, speedKmh: 2),
        _sample(second: 4, speedKmh: 60),
      ]);

      expect(report.splitTimesSec.values, everyElement(isNull));
      expect(report.time0to100Sec, isNull);
    });
  });
}

GpsSample _sample({required int second, required double speedKmh}) {
  return GpsSample(
    receivedAt: DateTime(2026, 1, 1).add(Duration(seconds: second)),
    gpsSyncBits: 0,
    timeTicksSinceHourStart: second * 1000,
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
