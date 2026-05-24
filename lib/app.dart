import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/features/performance_report/performance_report_screen.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_screen.dart';
import 'package:gps_tracker_analyzer/features/welcome/welcome_screen.dart';

class GpsTrackerApp extends StatelessWidget {
  const GpsTrackerApp({super.key});

  static const String routeWelcome = '/';
  static const String routeRecording = '/recording';
  static const String routeReport = '/report';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        routeWelcome: (_) => const WelcomeScreen(),
        routeRecording: (_) => const RecordingScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == routeReport) {
          final path = settings.arguments as String?;
          if (path == null || path.isEmpty) {
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Нет пути к сессии')),
              ),
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => PerformanceReportScreen(sessionFilePath: path),
          );
        }
        return null;
      },
    );
  }
}
