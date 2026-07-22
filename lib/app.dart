import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_cubit.dart';
import 'package:gps_tracker_analyzer/features/mobile/mobile_flow_screen.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';

class GpsTrackerApp extends StatelessWidget {
  const GpsTrackerApp({
    super.key,
    this.telemetryRepository,
    this.sessionStore,
    this.analytics,
  });

  /// Optional overrides keep the production app wired through GetIt while
  /// allowing deterministic widget and device-flow tests with in-memory fakes.
  final GpsTelemetryRepository? telemetryRepository;
  final SessionStore? sessionStore;
  final RunAnalytics? analytics;

  // Kept while the legacy prototype screens remain in the source tree.
  static const String routeWelcome = '/';
  static const String routeRecording = '/recording';
  static const String routeReport = '/report';
  static const String routeLiveSensors = '/live-sensors';

  @override
  Widget build(BuildContext context) {
    final telemetry = telemetryRepository ?? sl<GpsTelemetryRepository>();
    final store = sessionStore ?? sl<SessionStore>();
    final runAnalytics = analytics ?? sl<RunAnalytics>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => BluetoothCubit(telemetry)),
        BlocProvider(
          create: (_) => RecordingCubit(telemetry, store)..loadLoops(),
        ),
      ],
      child: MaterialApp(
        title: 'GPS Tracker Analyzer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: MobileFlowScreen(
          telemetryRepository: telemetry,
          sessionStore: store,
          analytics: runAnalytics,
        ),
      ),
    );
  }
}
