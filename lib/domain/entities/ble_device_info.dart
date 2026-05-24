import 'package:equatable/equatable.dart';

class BleDeviceInfo extends Equatable {
  const BleDeviceInfo({required this.remoteId, this.name});

  final String remoteId;
  final String? name;

  @override
  List<Object?> get props => [remoteId, name];
}
