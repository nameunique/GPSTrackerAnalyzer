import 'dart:math';

import 'package:gps_tracker_analyzer/core/config/validation_config.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';

const double _g = 9.80665;
const double _standingStartMaxKmh = 1;

class RunAnalytics {
  PerformanceReportData compute(List<GpsSample> rawSamples) {
    if (rawSamples.isEmpty) {
      return PerformanceReportData(
        series: const [],
        distanceM: 0,
        time0to100Sec: null,
        slopePercent: 0,
        splitTimesSec: <int, double?>{},
        isValid: false,
        maxSpeedKmh: 0,
        altitudeRangeM: 0,
        maxAbsAccelG: 1,
      );
    }

    final samples = List<GpsSample>.from(rawSamples)
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));

    final t0 = samples.first.receivedAt;
    final timesSec = samples
        .map((s) => s.receivedAt.difference(t0).inMicroseconds / 1e6)
        .toList();

    final distanceM = _integrateDistanceM(samples, timesSec);
    final splitTargets = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
    final splitTimesSec = <int, double?>{};
    final hasStandingStart = samples.first.speedKmh <= _standingStartMaxKmh;
    for (final kmh in splitTargets) {
      splitTimesSec[kmh] = hasStandingStart
          ? _timeToReachSpeedKmh(samples, timesSec, kmh.toDouble())
          : null;
    }

    final rawAccelG = _rawAccelerationG(samples, timesSec);
    final smoothedAccelG = _movingAverage(rawAccelG, 3);

    final series = <ChartSeriesPoint>[];
    for (var i = 0; i < samples.length; i++) {
      series.add(
        ChartSeriesPoint(
          timeSec: timesSec[i],
          speedKmh: samples[i].speedKmh,
          altitudeM: samples[i].altitudeM,
          accelerationG: smoothedAccelG[i],
        ),
      );
    }

    final maxSpeedKmh = samples.map((s) => s.speedKmh).reduce(max);
    final alts = samples.map((s) => s.altitudeM).toList();
    final minAlt = alts.reduce(min);
    final maxAlt = alts.reduce(max);
    final altitudeRangeM = maxAlt - minAlt;

    final maxAbsAccelG = smoothedAccelG
        .map((a) => a.abs())
        .fold<double>(0.1, (p, e) => max(p, e));

    final horizontalM = _haversineM(
      samples.first.latitudeDeg,
      samples.first.longitudeDeg,
      samples.last.latitudeDeg,
      samples.last.longitudeDeg,
    );
    final slopePercent = horizontalM > 1
        ? ((samples.last.altitudeM - samples.first.altitudeM) / horizontalM) *
              100
        : 0.0;

    final validCount = samples
        .where(
          (s) =>
              s.fixType >= ValidationConfig.minFixTypeForValid &&
              s.numSv >= ValidationConfig.minSatellitesForValid,
        )
        .length;
    final isValid =
        samples.isNotEmpty &&
        validCount / samples.length >= ValidationConfig.minValidSampleRatio;

    return PerformanceReportData(
      series: series,
      distanceM: distanceM,
      time0to100Sec: splitTimesSec[100],
      slopePercent: slopePercent,
      splitTimesSec: splitTimesSec,
      isValid: isValid,
      maxSpeedKmh: maxSpeedKmh,
      altitudeRangeM: altitudeRangeM,
      maxAbsAccelG: maxAbsAccelG,
    );
  }

  static double _integrateDistanceM(List<GpsSample> samples, List<double> t) {
    if (samples.length < 2) return 0;
    var sum = 0.0;
    for (var i = 0; i < samples.length - 1; i++) {
      final v0 = samples[i].speedMps;
      final v1 = samples[i + 1].speedMps;
      final dt = t[i + 1] - t[i];
      if (dt <= 0) continue;
      sum += 0.5 * (v0 + v1) * dt;
    }
    return sum;
  }

  static double? _timeToReachSpeedKmh(
    List<GpsSample> samples,
    List<double> t,
    double targetKmh,
  ) {
    for (var i = 0; i < samples.length - 1; i++) {
      final v0 = samples[i].speedKmh;
      final v1 = samples[i + 1].speedKmh;
      if (v1 >= targetKmh) {
        if (v0 >= targetKmh) {
          return t[i];
        }
        final span = v1 - v0;
        if (span.abs() < 1e-9) return t[i + 1];
        final f = (targetKmh - v0) / span;
        return t[i] + f * (t[i + 1] - t[i]);
      }
    }
    return null;
  }

  static List<double> _rawAccelerationG(
    List<GpsSample> samples,
    List<double> t,
  ) {
    final out = List<double>.filled(samples.length, 0);
    for (var i = 0; i < samples.length; i++) {
      if (i == 0 && samples.length > 1) {
        final dt = t[1] - t[0];
        if (dt > 0) {
          final a = (samples[1].speedMps - samples[0].speedMps) / dt;
          out[i] = a / _g;
        }
      } else if (i > 0) {
        final dt = t[i] - t[i - 1];
        if (dt > 0) {
          final a = (samples[i].speedMps - samples[i - 1].speedMps) / dt;
          out[i] = a / _g;
        }
      }
    }
    return out;
  }

  static List<double> _movingAverage(List<double> values, int window) {
    if (window <= 1 || values.isEmpty) return List<double>.from(values);
    final out = <double>[];
    final half = window ~/ 2;
    for (var i = 0; i < values.length; i++) {
      var sum = 0.0;
      var count = 0;
      for (var j = i - half; j <= i + half; j++) {
        if (j >= 0 && j < values.length) {
          sum += values[j];
          count++;
        }
      }
      out.add(sum / count);
    }
    return out;
  }

  static double _haversineM(
    double lat1Deg,
    double lon1Deg,
    double lat2Deg,
    double lon2Deg,
  ) {
    const earthRadiusM = 6371000.0;
    final lat1 = lat1Deg * pi / 180;
    final lat2 = lat2Deg * pi / 180;
    final dLat = (lat2Deg - lat1Deg) * pi / 180;
    final dLon = (lon2Deg - lon1Deg) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusM * c;
  }
}
