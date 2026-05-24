import 'package:equatable/equatable.dart';

class ChartSeriesPoint extends Equatable {
  const ChartSeriesPoint({
    required this.timeSec,
    required this.speedKmh,
    required this.altitudeM,
    required this.accelerationG,
  });

  final double timeSec;
  final double speedKmh;
  final double altitudeM;
  final double accelerationG;

  @override
  List<Object?> get props => [timeSec, speedKmh, altitudeM, accelerationG];
}

class PerformanceReportData extends Equatable {
  const PerformanceReportData({
    required this.series,
    required this.distanceM,
    required this.time0to100Sec,
    required this.slopePercent,
    required this.splitTimesSec,
    required this.isValid,
    required this.maxSpeedKmh,
    required this.altitudeRangeM,
    required this.maxAbsAccelG,
  });

  final List<ChartSeriesPoint> series;
  final double distanceM;
  final double? time0to100Sec;
  final double slopePercent;
  final Map<int, double?> splitTimesSec;
  final bool isValid;
  final double maxSpeedKmh;
  final double altitudeRangeM;
  final double maxAbsAccelG;

  @override
  List<Object?> get props => [
        series,
        distanceM,
        time0to100Sec,
        slopePercent,
        splitTimesSec,
        isValid,
        maxSpeedKmh,
        altitudeRangeM,
        maxAbsAccelG,
      ];
}
