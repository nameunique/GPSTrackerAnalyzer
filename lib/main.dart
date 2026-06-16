import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  await configureDependencies();
  runApp(const GpsTrackerApp());
}
