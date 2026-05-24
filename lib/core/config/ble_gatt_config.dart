/// RaceChrono BLE DIY API (see RaceChrono README): service 0x1FF8, GPS 0x0003 / 0x0004.
abstract final class BleGattConfig {
  static const String serviceUuid = '00001ff8-0000-1000-8000-00805f9b34fb';
  static const String mainNotifyCharacteristicUuid =
      '00000003-0000-1000-8000-00805f9b34fb';
  static const String timeNotifyCharacteristicUuid =
      '00000004-0000-1000-8000-00805f9b34fb';
}
