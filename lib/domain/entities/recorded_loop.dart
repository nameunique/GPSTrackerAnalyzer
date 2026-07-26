import 'package:equatable/equatable.dart';

enum TrackRecordingMode {
  manual,
  next100Samples,
  next200Samples,
  next300Samples;

  /// Maximum number of samples to capture, or `null` for manual stop.
  int? get sampleLimit {
    return switch (this) {
      TrackRecordingMode.manual => null,
      TrackRecordingMode.next100Samples => 100,
      TrackRecordingMode.next200Samples => 200,
      TrackRecordingMode.next300Samples => 300,
    };
  }

  bool get isUnlimited => sampleLimit == null;

  String get label {
    return switch (this) {
      TrackRecordingMode.manual => 'До ручной остановки',
      TrackRecordingMode.next100Samples => 'Следующие 100 значений',
      TrackRecordingMode.next200Samples => 'Следующие 200 значений',
      TrackRecordingMode.next300Samples => 'Следующие 300 значений',
    };
  }

  static TrackRecordingMode fromSampleLimit(int? sampleLimit) {
    return switch (sampleLimit) {
      100 => TrackRecordingMode.next100Samples,
      200 => TrackRecordingMode.next200Samples,
      300 => TrackRecordingMode.next300Samples,
      _ => TrackRecordingMode.manual,
    };
  }

  static TrackRecordingMode fromJson(String? value) {
    return TrackRecordingMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => TrackRecordingMode.manual,
    );
  }
}

class RecordedLoop extends Equatable {
  const RecordedLoop({
    required this.id,
    required this.title,
    required this.createdAt,
    this.filePath,
    this.sampleCount = 0,
    this.durationSec = 0,
    this.distanceMeters = 0,
    this.recordingMode = TrackRecordingMode.manual,
    this.seriesId,
    this.isSeriesCompleted = false,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String? filePath;
  final int sampleCount;
  final double durationSec;
  final double distanceMeters;
  final TrackRecordingMode recordingMode;
  final String? seriesId;
  final bool isSeriesCompleted;

  double get distanceKm => distanceMeters / 1000;

  bool get isSaved => filePath != null && filePath!.isNotEmpty;

  static String _normalizeTitle(String title) {
    return title.replaceFirst(RegExp(r'^(?:Луп|луп|Трек|трек)'), 'Замер');
  }

  RecordedLoop copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? filePath,
    int? sampleCount,
    double? durationSec,
    double? distanceMeters,
    TrackRecordingMode? recordingMode,
    String? seriesId,
    bool clearSeriesId = false,
    bool? isSeriesCompleted,
  }) {
    return RecordedLoop(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      sampleCount: sampleCount ?? this.sampleCount,
      durationSec: durationSec ?? this.durationSec,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      recordingMode: recordingMode ?? this.recordingMode,
      seriesId: clearSeriesId ? null : seriesId ?? this.seriesId,
      isSeriesCompleted:
          isSeriesCompleted ?? (clearSeriesId ? false : this.isSeriesCompleted),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'filePath': filePath,
    'sampleCount': sampleCount,
    'durationSec': durationSec,
    'distanceMeters': distanceMeters,
    'recordingMode': recordingMode.name,
    'seriesId': seriesId,
    'isSeriesCompleted': isSeriesCompleted,
  };

  factory RecordedLoop.fromJson(Map<String, dynamic> json) {
    return RecordedLoop(
      id: json['id'] as String,
      title: _normalizeTitle(json['title'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      filePath: json['filePath'] as String?,
      sampleCount: json['sampleCount'] as int? ?? 0,
      durationSec: (json['durationSec'] as num?)?.toDouble() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      recordingMode: TrackRecordingMode.fromJson(
        json['recordingMode'] as String?,
      ),
      seriesId: _seriesIdFromJson(json['seriesId']),
      isSeriesCompleted: json['isSeriesCompleted'] as bool? ?? false,
    );
  }

  static String? _seriesIdFromJson(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    filePath,
    sampleCount,
    durationSec,
    distanceMeters,
    recordingMode,
    seriesId,
    isSeriesCompleted,
  ];
}
