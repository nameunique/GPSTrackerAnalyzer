import 'package:get_it/get_it.dart';
import 'package:gps_tracker_analyzer/data/ble/ble_gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/data/ble/gps_packet_parser.dart';
import 'package:gps_tracker_analyzer/data/session/file_session_store.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:logger/logger.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 80),
    ),
  );

  sl.registerLazySingleton<GpsPacketParser>(GpsPacketParser.new);

  sl.registerLazySingleton<RunAnalytics>(RunAnalytics.new);

  sl.registerLazySingleton<SessionStore>(FileSessionStore.new);

  sl.registerLazySingleton<GpsTelemetryRepository>(
    () => BleGpsTelemetryRepository(
      parser: sl<GpsPacketParser>(),
      logger: sl<Logger>(),
    ),
  );
}
