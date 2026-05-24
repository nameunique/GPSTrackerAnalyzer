import 'package:equatable/equatable.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';

class PerformanceReportState extends Equatable {
  const PerformanceReportState({
    this.loading = true,
    this.data,
    this.errorMessage,
  });

  final bool loading;
  final PerformanceReportData? data;
  final String? errorMessage;

  PerformanceReportState copyWith({
    bool? loading,
    PerformanceReportData? data,
    String? errorMessage,
  }) {
    return PerformanceReportState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [loading, data, errorMessage];
}
