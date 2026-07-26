import 'dart:convert';
import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:path_provider/path_provider.dart';

class FileSessionStore implements SessionStore {
  IOSink? _sink;
  String? _activeFilePath;

  @override
  Future<ActiveSession> startSession(String loopId) async {
    await endSession();
    final dir = await _resolveDumpDirectory();
    final name =
        'loop_${loopId}_${DateTime.now().millisecondsSinceEpoch}.jsonl';
    final file = File('${dir.path}/$name');
    _sink = file.openWrite(mode: FileMode.writeOnly);
    _activeFilePath = file.path;
    return ActiveSession(filePath: file.path);
  }

  Future<Directory> _resolveDumpDirectory() async {
    // We write into app docs first, then export into Downloads on endSession().
    return getApplicationDocumentsDirectory();
  }

  Future<File> _indexFile() async {
    final dir = await _resolveDumpDirectory();
    return File('${dir.path}/loops_index.json');
  }

  @override
  void appendSample(GpsSample sample) {
    _sink?.writeln(jsonEncode(sample.toJson()));
  }

  @override
  Future<String?> endSession() async {
    final sink = _sink;
    final srcPath = _activeFilePath;
    _sink = null;
    _activeFilePath = null;

    if (sink != null) {
      try {
        await sink.flush();
      } finally {
        await sink.close();
      }
    }
    return srcPath;
  }

  @override
  Future<List<RecordedLoop>> listLoops() async {
    final file = await _indexFile();
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final loops =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(RecordedLoop.fromJson)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return loops;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> upsertLoop(RecordedLoop loop) async {
    final loops = await listLoops();
    final existingIndex = loops.indexWhere((l) => l.id == loop.id);
    if (existingIndex >= 0) {
      loops[existingIndex] = loop;
    } else {
      loops.insert(0, loop);
    }
    loops.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final file = await _indexFile();
    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(loops.map((l) => l.toJson()).toList()),
    );
  }

  @override
  Future<String?> exportLoop(RecordedLoop loop) async {
    final srcPath = loop.filePath;
    if (srcPath == null || srcPath.isEmpty) return null;

    try {
      final src = File(srcPath);
      if (!await src.exists()) return null;
      final fileName = src.uri.pathSegments.isNotEmpty
          ? src.uri.pathSegments.last
          : '${loop.id}.jsonl';
      await copyFileIntoDownloadFolder(srcPath, fileName);
      return srcPath;
    } catch (_) {
      return null;
    }
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
        out.add(
          GpsSample.fromJson(jsonDecode(trimmed) as Map<String, dynamic>),
        );
      } catch (_) {
        continue;
      }
    }
    return out;
  }
}
