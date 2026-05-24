import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';

class ActiveSession {
  const ActiveSession({required this.filePath});

  final String filePath;
}

abstract class SessionStore {
  Future<ActiveSession> startSession();

  void appendSample(GpsSample sample);

  /// Stops writing, exports a copy into Downloads (best-effort),
  /// and returns the internal session file path for in-app loading.
  Future<String?> endSession();

  Future<List<GpsSample>> loadSession(String filePath);
}
