import 'package:equatable/equatable.dart';

enum TrackRecordingMode {
  manual,
  next100Samples;

  String get label {
    return switch (this) {
      TrackRecordingMode.manual => 'Старт/стоп вручную',
      TrackRecordingMode.next100Samples => 'Следующие 100 значений',
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
    this.recordingMode = TrackRecordingMode.manual,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String? filePath;
  final int sampleCount;
  final double durationSec;
  final TrackRecordingMode recordingMode;

  bool get isSaved => filePath != null && filePath!.isNotEmpty;

  static String _normalizeTitle(String title) {
    return title.replaceFirst('Луп', 'Трек').replaceFirst('луп', 'трек');
  }

  RecordedLoop copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? filePath,
    int? sampleCount,
    double? durationSec,
    TrackRecordingMode? recordingMode,
  }) {
    return RecordedLoop(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      sampleCount: sampleCount ?? this.sampleCount,
      durationSec: durationSec ?? this.durationSec,
      recordingMode: recordingMode ?? this.recordingMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'filePath': filePath,
    'sampleCount': sampleCount,
    'durationSec': durationSec,
    'recordingMode': recordingMode.name,
  };

  factory RecordedLoop.fromJson(Map<String, dynamic> json) {
    return RecordedLoop(
      id: json['id'] as String,
      title: _normalizeTitle(json['title'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      filePath: json['filePath'] as String?,
      sampleCount: json['sampleCount'] as int? ?? 0,
      durationSec: (json['durationSec'] as num?)?.toDouble() ?? 0,
      recordingMode: TrackRecordingMode.fromJson(json['recordingMode'] as String?),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    filePath,
    sampleCount,
    durationSec,
    recordingMode,
  ];
}
