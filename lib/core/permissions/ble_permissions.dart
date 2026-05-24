import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureBlePermissions() async {
  if (!Platform.isAndroid) {
    return true;
  }

  final bluetoothScan = await Permission.bluetoothScan.request();
  final bluetoothConnect = await Permission.bluetoothConnect.request();
  if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted) {
    return false;
  }

  final location = await Permission.locationWhenInUse.request();
  if (!location.isGranted) {
    return false;
  }

  // For Android <= 28 some devices still require storage permission to write into Downloads.
  // On Android 29+ export uses MediaStore and this is typically ignored.
  await Permission.storage.request();

  return true;
}
