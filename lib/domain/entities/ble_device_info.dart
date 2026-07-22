import 'package:equatable/equatable.dart';

class BleDeviceInfo extends Equatable {
  const BleDeviceInfo({required this.remoteId, this.name, this.rssi});

  final String remoteId;
  final String? name;
  final int? rssi;

  @override
  List<Object?> get props => [remoteId, name, rssi];
}
