import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';

class ActiveSession {
  const ActiveSession({required this.filePath});

  final String filePath;
}

abstract class SessionStore {
  Future<ActiveSession> startSession(String loopId);

  void appendSample(GpsSample sample);

  /// Stops writing and returns the internal session file path for in-app loading.
  Future<String?> endSession();

  Future<List<RecordedLoop>> listLoops();

  Future<void> upsertLoop(RecordedLoop loop);

  Future<String?> exportLoop(RecordedLoop loop);

  Future<List<GpsSample>> loadSession(String filePath);
}
