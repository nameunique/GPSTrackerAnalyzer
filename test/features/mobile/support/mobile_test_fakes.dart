import 'dart:async';

import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';

/// Deterministic telemetry source used by the mobile widget and flow tests.
class FakeGpsTelemetryRepository implements GpsTelemetryRepository {
  FakeGpsTelemetryRepository({
    GpsTelemetryConnectionState initialConnection =
        GpsTelemetryConnectionState.idle,
    List<BleDeviceInfo> devices = const <BleDeviceInfo>[
      BleDeviceInfo(remoteId: 'test-device', name: 'GPS Tracker Test'),
    ],
  }) : _currentConnection = initialConnection,
       _devices = List<BleDeviceInfo>.of(devices);

  final StreamController<GpsSample> _samples =
      StreamController<GpsSample>.broadcast(sync: true);
  final StreamController<GpsTelemetryConnectionState> _connections =
      StreamController<GpsTelemetryConnectionState>.broadcast(sync: true);
  final StreamController<List<BleDeviceInfo>> _discoveredDevices =
      StreamController<List<BleDeviceInfo>>.broadcast(sync: true);

  final List<BleDeviceInfo> _devices;
  GpsTelemetryConnectionState _currentConnection;

  int startScanCalls = 0;
  int stopScanCalls = 0;
  int disconnectCalls = 0;
  final List<String> connectedRemoteIds = <String>[];
  Completer<void>? connectGate;

  String? get lastConnectedRemoteId => connectedRemoteIds.lastOrNull;

  bool get isClosed => _samples.isClosed;

  @override
  GpsTelemetryConnectionState get currentConnectionState => _currentConnection;

  @override
  Stream<GpsTelemetryConnectionState> get connectionState async* {
    yield _currentConnection;
    yield* _connections.stream;
  }

  @override
  Stream<List<BleDeviceInfo>> get discoveredDevices =>
      _discoveredDevices.stream;

  @override
  Stream<GpsSample> get samples => _samples.stream;

  @override
  Future<void> requestEnableBluetooth() async {}

  void emitSample(GpsSample sample) => _samples.add(sample);

  void emitConnection(GpsTelemetryConnectionState state) {
    _currentConnection = state;
    _connections.add(state);
  }

  void emitDevices([List<BleDeviceInfo>? devices]) {
    _discoveredDevices.add(
      List<BleDeviceInfo>.unmodifiable(devices ?? _devices),
    );
  }

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    startScanCalls++;
    emitConnection(GpsTelemetryConnectionState.scanning);
    emitDevices();
  }

  @override
  Future<void> stopScan() async {
    stopScanCalls++;
    emitConnection(GpsTelemetryConnectionState.idle);
  }

  @override
  Future<void> connect(String remoteId) async {
    connectedRemoteIds.add(remoteId);
    emitConnection(GpsTelemetryConnectionState.connecting);
    await connectGate?.future;
    emitConnection(GpsTelemetryConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    emitConnection(GpsTelemetryConnectionState.idle);
  }

  Future<void> close() async {
    await _samples.close();
    await _connections.close();
    await _discoveredDevices.close();
  }
}

/// Session store with no filesystem or platform-channel dependency.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore({
    Iterable<RecordedLoop> initialLoops = const <RecordedLoop>[],
  }) : _loops = List<RecordedLoop>.of(initialLoops) {
    _loops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  final List<RecordedLoop> _loops;
  final Map<String, List<GpsSample>> _sessions = <String, List<GpsSample>>{};

  String? _activePath;
  List<GpsSample>? _activeSamples;

  List<RecordedLoop> get loops => List<RecordedLoop>.unmodifiable(_loops);

  @override
  Future<ActiveSession> startSession(String loopId) async {
    if (_activePath != null) {
      throw StateError('A test session is already active');
    }
    final path = 'memory://sessions/$loopId.jsonl';
    _activePath = path;
    _activeSamples = <GpsSample>[];
    return ActiveSession(filePath: path);
  }

  @override
  void appendSample(GpsSample sample) {
    final samples = _activeSamples;
    if (samples == null) {
      throw StateError('No active test session');
    }
    samples.add(sample);
  }

  @override
  Future<String?> endSession() async {
    final path = _activePath;
    final samples = _activeSamples;
    if (path == null || samples == null) return null;
    _sessions[path] = List<GpsSample>.unmodifiable(samples);
    _activePath = null;
    _activeSamples = null;
    return path;
  }

  @override
  Future<List<RecordedLoop>> listLoops() async =>
      List<RecordedLoop>.unmodifiable(_loops);

  @override
  Future<void> upsertLoop(RecordedLoop loop) async {
    _loops.removeWhere((candidate) => candidate.id == loop.id);
    _loops.insert(0, loop);
    _loops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<String?> exportLoop(RecordedLoop loop) async {
    if (loop.filePath == null || !_sessions.containsKey(loop.filePath)) {
      return null;
    }
    return 'memory://exports/${loop.id}.jsonl';
  }

  @override
  Future<List<GpsSample>> loadSession(String filePath) async =>
      List<GpsSample>.of(_sessions[filePath] ?? const <GpsSample>[]);
}

GpsSample mobileTestSample({
  required DateTime receivedAt,
  double speedKmh = 0,
  int fixType = 3,
  int satelliteCount = 12,
  int hdop = 8,
}) {
  return GpsSample(
    receivedAt: receivedAt,
    gpsSyncBits: 0,
    timeTicksSinceHourStart: receivedAt.millisecond,
    fixType: fixType,
    numSv: satelliteCount,
    latitudeDeg: 55.751244,
    longitudeDeg: 37.618423,
    altitudeM: 150,
    speedKmh: speedKmh,
    headingDeg: 90,
    hdop: hdop,
  );
}
