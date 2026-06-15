import 'package:equatable/equatable.dart';

class RecordedLoop extends Equatable {
  const RecordedLoop({
    required this.id,
    required this.title,
    required this.createdAt,
    this.filePath,
    this.sampleCount = 0,
    this.durationSec = 0,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final String? filePath;
  final int sampleCount;
  final double durationSec;

  bool get isSaved => filePath != null && filePath!.isNotEmpty;

  RecordedLoop copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    String? filePath,
    int? sampleCount,
    double? durationSec,
  }) {
    return RecordedLoop(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      filePath: filePath ?? this.filePath,
      sampleCount: sampleCount ?? this.sampleCount,
      durationSec: durationSec ?? this.durationSec,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'filePath': filePath,
    'sampleCount': sampleCount,
    'durationSec': durationSec,
  };

  factory RecordedLoop.fromJson(Map<String, dynamic> json) {
    return RecordedLoop(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      filePath: json['filePath'] as String?,
      sampleCount: json['sampleCount'] as int? ?? 0,
      durationSec: (json['durationSec'] as num?)?.toDouble() ?? 0,
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
  ];
}
