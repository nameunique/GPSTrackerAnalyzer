import 'package:equatable/equatable.dart';

class GpsSample extends Equatable {
  const GpsSample({
    required this.receivedAt,
    required this.gpsSyncBits,
    required this.timeTicksSinceHourStart,
    required this.fixType,
    required this.numSv,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.altitudeM,
    required this.speedKmh,
    required this.headingDeg,
    required this.hdop,
  });

  final DateTime receivedAt;
  final int gpsSyncBits;
  final int timeTicksSinceHourStart;
  final int fixType;
  final int numSv;
  final double latitudeDeg;
  final double longitudeDeg;
  final double altitudeM;
  final double speedKmh;
  final double headingDeg;
  final int hdop;

  double get speedMps => speedKmh / 3.6;

  Map<String, dynamic> toJson() => {
        'receivedAt': receivedAt.toIso8601String(),
        'gpsSyncBits': gpsSyncBits,
        'timeTicksSinceHourStart': timeTicksSinceHourStart,
        'fixType': fixType,
        'numSv': numSv,
        'latitudeDeg': latitudeDeg,
        'longitudeDeg': longitudeDeg,
        'altitudeM': altitudeM,
        'speedKmh': speedKmh,
        'headingDeg': headingDeg,
        'hdop': hdop,
      };

  factory GpsSample.fromJson(Map<String, dynamic> json) {
    return GpsSample(
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      gpsSyncBits: json['gpsSyncBits'] as int,
      timeTicksSinceHourStart: json['timeTicksSinceHourStart'] as int,
      fixType: json['fixType'] as int,
      numSv: json['numSv'] as int,
      latitudeDeg: (json['latitudeDeg'] as num).toDouble(),
      longitudeDeg: (json['longitudeDeg'] as num).toDouble(),
      altitudeM: (json['altitudeM'] as num).toDouble(),
      speedKmh: (json['speedKmh'] as num).toDouble(),
      headingDeg: (json['headingDeg'] as num).toDouble(),
      hdop: json['hdop'] as int,
    );
  }

  @override
  List<Object?> get props => [
        receivedAt,
        gpsSyncBits,
        timeTicksSinceHourStart,
        fixType,
        numSv,
        latitudeDeg,
        longitudeDeg,
        altitudeM,
        speedKmh,
        headingDeg,
        hdop,
      ];
}
