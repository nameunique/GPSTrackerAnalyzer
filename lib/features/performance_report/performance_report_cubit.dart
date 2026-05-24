import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/di/injection.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/performance_report/performance_report_state.dart';

class PerformanceReportCubit extends Cubit<PerformanceReportState> {
  PerformanceReportCubit({
    required SessionStore sessionStore,
    required RunAnalytics analytics,
  })  : _sessionStore = sessionStore,
        _analytics = analytics,
        super(const PerformanceReportState());

  final SessionStore _sessionStore;
  final RunAnalytics _analytics;

  factory PerformanceReportCubit.create() {
    return PerformanceReportCubit(
      sessionStore: sl<SessionStore>(),
      analytics: sl<RunAnalytics>(),
    );
  }

  Future<void> load(String filePath) async {
    emit(const PerformanceReportState(loading: true));
    try {
      final samples = await _sessionStore.loadSession(filePath);
      final data = _analytics.compute(samples);
      emit(PerformanceReportState(loading: false, data: data));
    } catch (e) {
      emit(PerformanceReportState(
        loading: false,
        errorMessage: 'Не удалось загрузить сессию: $e',
      ));
    }
  }
}
