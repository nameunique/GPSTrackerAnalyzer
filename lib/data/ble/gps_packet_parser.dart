import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';

/// Parses the 20-byte MAIN notify payload from the device firmware.
class GpsPacketParser {
  static const int mainPacketLength = 20;

  GpsSample? parseMainPacket(List<int> bytes, DateTime receivedAt) {
    if (bytes.length < mainPacketLength) return null;

    final gpsSyncBits = (bytes[0] >> 5) & 0x07;
    final timeTicksSinceHourStart =
        ((bytes[0] & 0x1F) << 16) | (bytes[1] << 8) | bytes[2];
    final fixType = (bytes[3] >> 6) & 0x03;
    final numSv = bytes[3] & 0x3F;

    final lat = _readInt32BigEndian(bytes, 4);
    final lon = _readInt32BigEndian(bytes, 8);
    final altitudeDm = _readInt16BigEndian(bytes, 12);
    final speedCmS = _readUint16BigEndian(bytes, 14);
    final headingCdeg = _readUint16BigEndian(bytes, 16);
    final hdop = bytes[18];

    return GpsSample(
      receivedAt: receivedAt,
      gpsSyncBits: gpsSyncBits,
      timeTicksSinceHourStart: timeTicksSinceHourStart,
      fixType: fixType,
      numSv: numSv,
      latitudeDeg: lat / 1e7,
      longitudeDeg: lon / 1e7,
      altitudeM: altitudeDm / 10.0,
      speedKmh: speedCmS * 0.036,
      headingDeg: headingCdeg / 100.0,
      hdop: hdop,
    );
  }

  int _readInt32BigEndian(List<int> bytes, int offset) {
    final b0 = bytes[offset];
    final b1 = bytes[offset + 1];
    final b2 = bytes[offset + 2];
    final b3 = bytes[offset + 3];
    var value = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
    if (value & 0x80000000 != 0) {
      value = value - 0x100000000;
    }
    return value;
  }

  int _readInt16BigEndian(List<int> bytes, int offset) {
    final hi = bytes[offset];
    final lo = bytes[offset + 1];
    var value = (hi << 8) | lo;
    if (value & 0x8000 != 0) {
      value = value - 0x10000;
    }
    return value;
  }

  int _readUint16BigEndian(List<int> bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }
}
