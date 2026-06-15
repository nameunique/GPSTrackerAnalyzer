import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_cubit.dart';
import 'package:gps_tracker_analyzer/features/live_sensors/live_sensors_screen.dart';
import 'package:gps_tracker_analyzer/features/performance_report/performance_report_screen.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_screen.dart';
import 'package:gps_tracker_analyzer/features/welcome/welcome_screen.dart';
import 'package:gps_tracker_analyzer/shared/widgets/app_shell.dart';

class GpsTrackerApp extends StatelessWidget {
  const GpsTrackerApp({super.key});

  static const String routeWelcome = '/';
  static const String routeRecording = '/recording';
  static const String routeReport = '/report';
  static const String routeLiveSensors = '/live-sensors';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BluetoothCubit(sl<GpsTelemetryRepository>()),
      child: MaterialApp(
        title: 'GPS Tracker Analyzer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.scaffoldBlue,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.scaffoldBlue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        initialRoute: routeWelcome,
        routes: {
          routeWelcome: (_) => const AppShell(child: WelcomeScreen()),
          routeRecording: (_) => const AppShell(child: RecordingScreen()),
          routeLiveSensors: (_) => const AppShell(child: LiveSensorsScreen()),
        },
        onGenerateRoute: (settings) {
          if (settings.name == routeReport) {
            final path = settings.arguments as String?;
            if (path == null || path.isEmpty) {
              return MaterialPageRoute<void>(
                builder: (_) => const AppShell(
                  child: Scaffold(
                    body: Center(child: Text('Нет пути к сессии')),
                  ),
                ),
              );
            }
            return MaterialPageRoute<void>(
              builder: (_) => AppShell(
                child: PerformanceReportScreen(sessionFilePath: path),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
