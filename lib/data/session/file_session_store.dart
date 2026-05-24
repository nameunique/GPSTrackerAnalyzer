import 'dart:convert';
import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:path_provider/path_provider.dart';

class FileSessionStore implements SessionStore {
  IOSink? _sink;
  String? _activeFilePath;

  @override
  Future<ActiveSession> startSession() async {
    await endSession();
    final dir = await _resolveDumpDirectory();
    final name = 'session_${DateTime.now().millisecondsSinceEpoch}.jsonl';
    final file = File('${dir.path}/$name');
    _sink = file.openWrite(mode: FileMode.writeOnly);
    _activeFilePath = file.path;
    return ActiveSession(filePath: file.path);
  }

  Future<Directory> _resolveDumpDirectory() async {
    // We write into app docs first, then export into Downloads on endSession().
    return getApplicationDocumentsDirectory();
  }

  @override
  void appendSample(GpsSample sample) {
    _sink?.writeln(jsonEncode(sample.toJson()));
  }

  @override
  Future<String?> endSession() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    final srcPath = _activeFilePath;
    _activeFilePath = null;
    if (srcPath == null) return null;

    // Export into public Downloads so user can find it in file manager.
    // On Android 29+ this typically goes through MediaStore (no MANAGE_EXTERNAL_STORAGE).
    try {
      final src = File(srcPath);
      if (!await src.exists()) return null;
      final fileName = src.uri.pathSegments.isNotEmpty
          ? src.uri.pathSegments.last
          : 'session.jsonl';

      await copyFileIntoDownloadFolder(srcPath, fileName);
    } catch (_) {
      // Export to Downloads is best-effort; keep internal copy for in-app loading.
    }

    return srcPath;
  }

  @override
  Future<List<GpsSample>> loadSession(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return [];
    }
    final lines = await file.readAsLines();
    final out = <GpsSample>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        out.add(GpsSample.fromJson(jsonDecode(trimmed) as Map<String, dynamic>));
      } catch (_) {
        continue;
      }
    }
    return out;
  }
}
