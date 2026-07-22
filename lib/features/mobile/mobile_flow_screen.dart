import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gps_tracker_analyzer/core/config/validation_config.dart';
import 'package:gps_tracker_analyzer/core/platform/result_sharer.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/entities/performance_report_data.dart';
import 'package:gps_tracker_analyzer/domain/entities/recorded_loop.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/repositories/session_store.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_cubit.dart';
import 'package:gps_tracker_analyzer/features/bluetooth/bluetooth_state.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_screens.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_cubit.dart';
import 'package:gps_tracker_analyzer/features/recording/recording_state.dart';

enum _FlowStage {
  connect,
  search,
  main,
  limit,
  preflight,
  recording,
  saving,
  result,
  addMeasurement,
  seriesSummary,
  detail,
  analysis,
  permission,
  bluetoothOff,
  earlyStop,
  connectionLost,
  saveError,
}

class MobileFlowScreen extends StatefulWidget {
  const MobileFlowScreen({
    super.key,
    required this.telemetryRepository,
    required this.sessionStore,
    required this.analytics,
  });

  final GpsTelemetryRepository telemetryRepository;
  final SessionStore sessionStore;
  final RunAnalytics analytics;

  @override
  State<MobileFlowScreen> createState() => _MobileFlowScreenState();
}

class _MobileFlowScreenState extends State<MobileFlowScreen> {
  static const Duration _gpsSampleMaxAge = Duration(seconds: 5);
  static const Duration _gpsFutureTolerance = Duration(seconds: 1);
  static const Duration _scanTimeout = Duration(seconds: 15);

  late _FlowStage _stage;
  MobileTab _tab = MobileTab.home;
  RecordLimit _selectedLimit = RecordLimit.records200;
  String? _pendingLoopId;
  RecordedLoop? _lastResult;
  RecordedLoop? _selectedLoop;
  String? _activeSeriesId;
  String? _summarySeriesId;
  bool _sortSeriesByResult = false;
  HistoryFilter _historyFilter = HistoryFilter.all;
  _FlowStage _summaryReturnStage = _FlowStage.result;
  MobileTab _summaryReturnTab = MobileTab.series;
  _FlowStage _detailReturnStage = _FlowStage.main;
  MobileTab _detailReturnTab = MobileTab.history;
  StreamSubscription<GpsSample>? _sampleSubscription;
  Timer? _gpsFreshnessTimer;
  Timer? _scanTimeoutTimer;
  GpsSample? _latestSample;
  bool _latestSampleIsFresh = false;
  String? _lastDeviceId;
  String _lastDeviceName = 'GPS Tracker';
  int? _lastDeviceRssi;
  bool _connecting = false;
  bool _scanHasStarted = false;
  bool _searchActive = false;
  int _searchSession = 0;
  int _connectOperation = 0;
  bool _connectionCleanupPending = false;
  bool _handlingCompletion = false;
  bool _addingMeasurement = false;
  bool _preparingMeasurement = false;
  bool _connectionLostBeforeStart = false;

  @override
  void initState() {
    super.initState();
    _stage =
        widget.telemetryRepository.currentConnectionState ==
            GpsTelemetryConnectionState.connected
        ? _FlowStage.main
        : _FlowStage.connect;
    _sampleSubscription = widget.telemetryRepository.samples.listen(
      _onTelemetrySample,
    );
  }

  @override
  void dispose() {
    _gpsFreshnessTimer?.cancel();
    _scanTimeoutTimer?.cancel();
    _sampleSubscription?.cancel();
    super.dispose();
  }

  TrackRecordingMode get _recordingMode => switch (_selectedLimit) {
    RecordLimit.records100 => TrackRecordingMode.next100Samples,
    RecordLimit.records200 => TrackRecordingMode.next200Samples,
    RecordLimit.records300 => TrackRecordingMode.next300Samples,
    RecordLimit.manual => TrackRecordingMode.manual,
  };

  void _onTelemetrySample(GpsSample sample) {
    _gpsFreshnessTimer?.cancel();
    final age = DateTime.now().difference(sample.receivedAt);
    final isFresh = age >= -_gpsFutureTolerance && age <= _gpsSampleMaxAge;
    if (mounted) {
      setState(() {
        _latestSample = sample;
        _latestSampleIsFresh = isFresh;
      });
    }
    if (!isFresh) return;

    final remaining = _gpsSampleMaxAge - age;
    _gpsFreshnessTimer = Timer(remaining, () {
      if (mounted && identical(_latestSample, sample)) {
        setState(() => _latestSampleIsFresh = false);
      }
    });
  }

  bool _dataActive(GpsTelemetryConnectionState connection) {
    return connection == GpsTelemetryConnectionState.connected &&
        _latestSample != null &&
        _latestSampleIsFresh;
  }

  bool _gpsReady(GpsTelemetryConnectionState connection) {
    final sample = _latestSample;
    return _dataActive(connection) &&
        sample != null &&
        sample.fixType >= ValidationConfig.minFixTypeForValid &&
        sample.numSv >= ValidationConfig.minSatellitesForValid &&
        sample.hdop > 0 &&
        sample.hdop <= 30;
  }

  int get _gpsAccuracyMeters {
    final sample = _latestSample;
    if (sample == null || sample.hdop <= 0) return 18;
    final estimated = (sample.hdop * 0.1 * 4).round();
    return estimated.clamp(3, 99);
  }

  String _newSeriesId() => 'series-${DateTime.now().microsecondsSinceEpoch}';

  String? _effectiveActiveSeriesId(RecordingState state) {
    final preferred = _activeSeriesId;
    if (preferred != null &&
        state.loops.any(
          (loop) => loop.seriesId == preferred && !loop.isSeriesCompleted,
        )) {
      return preferred;
    }
    for (final loop in state.loops) {
      if (loop.seriesId != null && !loop.isSeriesCompleted) {
        return loop.seriesId;
      }
    }
    return null;
  }

  String? _latestCompletedSeriesId(RecordingState state) {
    for (final loop in state.loops) {
      if (loop.seriesId != null && loop.isSeriesCompleted) {
        return loop.seriesId;
      }
    }
    return null;
  }

  List<RecordedLoop> _loopsForSeries(RecordingState state, String? seriesId) {
    if (seriesId == null) return const <RecordedLoop>[];
    return state.loops
        .where((loop) => loop.seriesId == seriesId && loop.isSaved)
        .toList(growable: false);
  }

  Future<PerformanceReportData?> _loadAnalytics(RecordedLoop loop) async {
    final path = loop.filePath;
    if (path == null || path.isEmpty) return null;
    try {
      final samples = await widget.sessionStore.loadSession(path);
      return widget.analytics.compute(samples);
    } catch (_) {
      return null;
    }
  }

  void _setStage(_FlowStage stage) {
    if (stage != _FlowStage.search) {
      _searchSession++;
      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = null;
      _scanHasStarted = false;
      _searchActive = false;
    }
    if (mounted) setState(() => _stage = stage);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startSearch() async {
    if (_connecting) return;
    _scanTimeoutTimer?.cancel();
    final session = ++_searchSession;
    _scanHasStarted = false;
    _searchActive = true;
    _setStage(_FlowStage.search);
    _scanTimeoutTimer = Timer(
      _scanTimeout,
      () => unawaited(_finishTimedOutSearch(session)),
    );
    await context.read<BluetoothCubit>().scan();
  }

  Future<void> _enableBluetoothAndSearch() async {
    final bluetooth = context.read<BluetoothCubit>();
    final enabled = await bluetooth.enableBluetooth();
    if (!mounted) return;
    if (enabled) {
      await _startSearch();
    } else if (bluetooth.state.errorMessage case final message?) {
      _showMessage(message);
    }
  }

  Future<void> _finishTimedOutSearch(int session) async {
    if (!mounted ||
        _stage != _FlowStage.search ||
        session != _searchSession ||
        !_searchActive) {
      return;
    }
    _scanTimeoutTimer = null;
    _scanHasStarted = false;
    await context.read<BluetoothCubit>().stopScan();
    if (!mounted || _stage != _FlowStage.search || session != _searchSession) {
      return;
    }
    setState(() => _searchActive = false);
  }

  Future<void> _stopSearchAndReturn() async {
    _connectOperation++;
    if (_connecting && mounted) {
      setState(() {
        _connecting = false;
        _connectionCleanupPending = true;
      });
    }
    _setStage(_FlowStage.connect);
    await context.read<BluetoothCubit>().stopScan();
  }

  void _completeSearch() {
    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;
    _scanHasStarted = false;
    if (mounted) setState(() => _searchActive = false);
  }

  Future<void> _connectDevice(BleDeviceInfo device) async {
    if (_connecting || _connectionCleanupPending) return;
    final operation = ++_connectOperation;
    final returnToPreflight =
        _connectionLostBeforeStart && _pendingLoopId != null;
    _scanTimeoutTimer?.cancel();
    _searchSession++;
    setState(() {
      _connecting = true;
      _searchActive = false;
      _scanHasStarted = false;
      _lastDeviceId = device.remoteId;
      _lastDeviceRssi = device.rssi;
      _lastDeviceName = device.name?.trim().isNotEmpty == true
          ? device.name!.trim()
          : 'GPS Tracker';
    });
    await context.read<BluetoothCubit>().connect(device.remoteId);
    if (!mounted) return;
    if (operation != _connectOperation) {
      final bluetooth = context.read<BluetoothCubit>();
      if (!_connecting) {
        final interruptedSearchSession =
            _stage == _FlowStage.search && _searchActive
            ? _searchSession
            : null;
        if (interruptedSearchSession != null) {
          // Ignore the idle event produced while cleaning up this stale
          // connection. It does not belong to the current scan session.
          _scanHasStarted = false;
        }
        await bluetooth.disconnect();
        if (mounted &&
            interruptedSearchSession != null &&
            interruptedSearchSession == _searchSession &&
            _stage == _FlowStage.search &&
            _searchActive &&
            !_connecting) {
          unawaited(bluetooth.scan());
        }
        if (mounted) {
          setState(() => _connectionCleanupPending = false);
        }
      }
      return;
    }
    setState(() => _connecting = false);
    if (context.read<BluetoothCubit>().state.connection ==
        GpsTelemetryConnectionState.connected) {
      final recording = context.read<RecordingCubit>().state;
      if (returnToPreflight && !recording.isRecording) {
        _connectionLostBeforeStart = false;
      }
      _setStage(
        recording.isRecording
            ? _FlowStage.recording
            : returnToPreflight
            ? _FlowStage.preflight
            : _FlowStage.main,
      );
    }
  }

  Future<void> _reconnectLastDevice() async {
    final deviceId = _lastDeviceId;
    if (deviceId == null) {
      await _startSearch();
      return;
    }
    _setStage(_FlowStage.search);
    await _connectDevice(
      BleDeviceInfo(
        remoteId: deviceId,
        name: _lastDeviceName,
        rssi: _lastDeviceRssi,
      ),
    );
    if (!mounted) return;
    if (_stage == _FlowStage.search &&
        context.read<BluetoothCubit>().state.connection !=
            GpsTelemetryConnectionState.connected) {
      _setStage(_FlowStage.connect);
    }
  }

  Future<void> _disconnect() async {
    await context.read<BluetoothCubit>().disconnect();
    if (!mounted) return;
    _setStage(_FlowStage.connect);
  }

  Future<void> _findAnotherDevice() async {
    if (context.read<BluetoothCubit>().state.connection ==
        GpsTelemetryConnectionState.connected) {
      await context.read<BluetoothCubit>().disconnect();
      if (!mounted) return;
    }
    await _startSearch();
  }

  void _openNewMeasurement({bool addToSeries = false}) {
    _discardPendingDraft();
    _addingMeasurement = addToSeries;
    _setStage(addToSeries ? _FlowStage.addMeasurement : _FlowStage.limit);
  }

  Future<void> _continueLimitSelection() async {
    if (_preparingMeasurement) return;
    _preparingMeasurement = true;
    final cubit = context.read<RecordingCubit>();
    try {
      var seriesId = _addingMeasurement
          ? _effectiveActiveSeriesId(cubit.state)
          : _activeSeriesId;
      seriesId ??= _newSeriesId();
      _activeSeriesId = seriesId;

      RecordedLoop? loop;
      final pendingId = _pendingLoopId;
      if (pendingId != null) {
        for (final candidate in cubit.state.loops) {
          if (candidate.id == pendingId &&
              !candidate.isSaved &&
              candidate.sampleCount == 0 &&
              cubit.state.activeLoopId != candidate.id) {
            loop = candidate;
            break;
          }
        }
      }
      loop ??= cubit.addLoop(seriesId: seriesId);
      if (loop == null) return;
      if (loop.seriesId != seriesId) {
        await cubit.assignLoopToSeries(loop.id, seriesId);
      }
      _pendingLoopId = loop.id;
      await cubit.updateRecordingMode(loop.id, _recordingMode);
      if (!mounted) return;
      final connection = context.read<BluetoothCubit>().state.connection;
      setState(() {
        _connectionLostBeforeStart =
            connection != GpsTelemetryConnectionState.connected;
        _stage = connection == GpsTelemetryConnectionState.bluetoothOff
            ? _FlowStage.bluetoothOff
            : _connectionLostBeforeStart
            ? _FlowStage.connectionLost
            : _FlowStage.preflight;
      });
    } finally {
      _preparingMeasurement = false;
    }
  }

  void _discardPendingDraft() {
    final id = _pendingLoopId;
    if (id == null) return;
    final discarded = context.read<RecordingCubit>().discardDraftLoop(id);
    if (discarded) _pendingLoopId = null;
  }

  void _leaveMeasurementSetup(_FlowStage target) {
    _discardPendingDraft();
    _setStage(target);
  }

  Future<void> _startRecording() async {
    final id = _pendingLoopId;
    if (id == null) return;
    final cubit = context.read<RecordingCubit>();
    await cubit.startRecording(id);
    if (!mounted) return;
    if (cubit.state.isRecording) {
      _setStage(_FlowStage.recording);
    } else if (cubit.state.errorMessage case final message?) {
      _showMessage(message);
    }
  }

  Future<void> _stopRecording() async {
    final saved = await context.read<RecordingCubit>().stopRecording();
    if (!mounted) return;
    if (saved != null) {
      await _handleCompletedLoop(saved);
    }
  }

  Future<void> _handleCompletedLoop(RecordedLoop loop) async {
    if (_handlingCompletion || !mounted) return;
    _handlingCompletion = true;
    _activeSeriesId = loop.seriesId ?? _activeSeriesId;
    setState(() {
      _lastResult = loop;
      _pendingLoopId = null;
      _stage = _FlowStage.saving;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final error = context.read<RecordingCubit>().state.errorMessage;
    setState(() {
      _stage = error == null ? _FlowStage.result : _FlowStage.saveError;
      _handlingCompletion = false;
    });
  }

  Future<void> _retrySave() async {
    final loop = _lastResult;
    if (loop == null) {
      _setStage(_FlowStage.main);
      return;
    }
    final recordingCubit = context.read<RecordingCubit>();
    try {
      await widget.sessionStore.upsertLoop(loop);
      await recordingCubit.loadLoops();
      if (mounted) _setStage(_FlowStage.result);
    } catch (error) {
      _showMessage('Сохранение не удалось: $error');
    }
  }

  Future<void> _reconnectDuringRecording() async {
    final deviceId = _lastDeviceId;
    if (deviceId == null) {
      await _startSearch();
      return;
    }
    final returnToPreflight =
        _connectionLostBeforeStart && _pendingLoopId != null;
    await context.read<BluetoothCubit>().connect(deviceId);
    if (!mounted) return;
    final recording = context.read<RecordingCubit>().state;
    if (recording.connection == GpsTelemetryConnectionState.connected) {
      if (recording.isRecording) {
        await context.read<RecordingCubit>().resumeRecording();
        if (mounted) _setStage(_FlowStage.recording);
      } else if (returnToPreflight) {
        _connectionLostBeforeStart = false;
        _setStage(_FlowStage.preflight);
      }
    }
  }

  Future<void> _finishCurrentSeries() async {
    final cubit = context.read<RecordingCubit>();
    final seriesId =
        _lastResult?.seriesId ?? _effectiveActiveSeriesId(cubit.state);
    if (seriesId == null) {
      _showMessage('В серии пока нет сохранённых замеров');
      return;
    }
    _summarySeriesId = seriesId;
    _sortSeriesByResult = false;
    _summaryReturnStage = _FlowStage.result;
    final completed = await cubit.completeSeries(seriesId);
    if (!mounted) return;
    if (!completed) {
      _showMessage(
        cubit.state.errorMessage ?? 'Не удалось завершить серию замеров',
      );
      return;
    }
    setState(() {
      if (_activeSeriesId == seriesId) _activeSeriesId = null;
      _stage = _FlowStage.seriesSummary;
    });
  }

  Future<void> _beginNewSeries() async {
    final cubit = context.read<RecordingCubit>();
    final activeId = _effectiveActiveSeriesId(cubit.state);
    if (activeId != null) {
      final completed = await cubit.completeSeries(activeId);
      if (!mounted) return;
      if (!completed) {
        _showMessage(
          cubit.state.errorMessage ?? 'Не удалось завершить активную серию',
        );
        return;
      }
    }
    setState(() {
      _activeSeriesId = _newSeriesId();
      _summarySeriesId = null;
      _sortSeriesByResult = false;
    });
    _openNewMeasurement();
  }

  Future<void> _addLoopToActiveSeries(RecordedLoop loop) async {
    final cubit = context.read<RecordingCubit>();
    final seriesId = _effectiveActiveSeriesId(cubit.state) ?? _newSeriesId();
    await cubit.assignLoopToSeries(loop.id, seriesId);
    if (!mounted) return;
    final updatedLoop = cubit.state.loops
        .where((candidate) => candidate.id == loop.id)
        .firstOrNull;
    setState(() {
      _activeSeriesId = seriesId;
      if (updatedLoop != null && _selectedLoop?.id == updatedLoop.id) {
        _selectedLoop = updatedLoop;
      }
    });
    _showMessage(
      cubit.state.errorMessage == null
          ? 'Замер добавлен в активную серию'
          : 'Не удалось сохранить изменение серии',
    );
  }

  void _openSeriesSummary(String? seriesId) {
    if (seriesId == null) return;
    setState(() {
      _summarySeriesId = seriesId;
      _sortSeriesByResult = false;
      _summaryReturnStage = _stage == _FlowStage.analysis
          ? _FlowStage.detail
          : _FlowStage.main;
      _summaryReturnTab = _tab;
      _stage = _FlowStage.seriesSummary;
    });
  }

  void _returnFromSeriesSummary() {
    if (_summaryReturnStage == _FlowStage.main) {
      _tab = _summaryReturnTab;
    }
    _setStage(_summaryReturnStage);
  }

  void _openLoop(RecordedLoop loop) {
    setState(() {
      if (_stage == _FlowStage.seriesSummary) {
        _detailReturnStage = _FlowStage.seriesSummary;
      } else {
        _detailReturnStage = _FlowStage.main;
        _detailReturnTab = _tab;
      }
      _selectedLoop = loop;
      _stage = _FlowStage.detail;
    });
  }

  void _returnFromDetail() {
    if (_detailReturnStage == _FlowStage.main) {
      _tab = _detailReturnTab;
    }
    _setStage(_detailReturnStage);
  }

  String _durationLabel(Duration value) {
    final total = value.inSeconds;
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _loopDurationLabel(RecordedLoop loop) {
    return _durationLabel(
      Duration(milliseconds: (loop.durationSec * 1000).round()),
    );
  }

  String _decimal(double value, {int digits = 1}) {
    return value.toStringAsFixed(digits).replaceAll('.', ',');
  }

  String _resultLabel(PerformanceReportData? data) {
    final value = data?.isValid == true ? data!.time0to100Sec : null;
    return value == null ? 'Не рассчитан' : '${_decimal(value)} с';
  }

  String _signalLabel(int? rssi) {
    if (rssi == null) return 'Устройство рядом';
    if (rssi >= -60) return 'Сигнал отличный';
    if (rssi >= -75) return 'Сигнал хороший';
    return 'Сигнал слабый';
  }

  SearchSignalQuality _signalQuality(int? rssi) {
    if (rssi == null) return SearchSignalQuality.unknown;
    if (rssi >= -60) return SearchSignalQuality.excellent;
    if (rssi >= -75) return SearchSignalQuality.good;
    return SearchSignalQuality.weak;
  }

  String _recordWord(int value) {
    final mod100 = value % 100;
    final mod10 = value % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'записей';
    if (mod10 == 1) return 'запись';
    if (mod10 >= 2 && mod10 <= 4) return 'записи';
    return 'записей';
  }

  String _measurementWord(int value) {
    final mod100 = value % 100;
    final mod10 = value % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'замеров';
    if (mod10 == 1) return 'замер';
    if (mod10 >= 2 && mod10 <= 4) return 'замера';
    return 'замеров';
  }

  String _recordLimitLabel(TrackRecordingMode mode) {
    final limit = mode.sampleLimit;
    return limit == null ? 'До остановки' : '$limit записей';
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    if (sameDay) return 'Сегодня, $hour:$minute';
    const months = <String>[
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]}, $hour:$minute';
  }

  Future<List<_LoopViewData>> _loadLoopViewData(
    List<RecordedLoop> loops,
  ) async {
    final output = <_LoopViewData>[];
    for (final loop in loops) {
      output.add(_LoopViewData(loop, await _loadAnalytics(loop)));
    }
    final calculated = output
        .where(
          (item) =>
              item.analytics?.isValid == true &&
              item.analytics?.time0to100Sec != null,
        )
        .toList(growable: false);
    double? best;
    for (final item in calculated) {
      final current = item.analytics!.time0to100Sec!;
      if (best == null || current < best) best = current;
    }
    return output
        .map(
          (item) => item.copyWith(
            isBest:
                item.analytics?.isValid == true &&
                item.analytics?.time0to100Sec == best,
          ),
        )
        .toList(growable: false);
  }

  MeasurementListData _measurementListData(_LoopViewData item) {
    final loop = item.loop;
    final result = _resultLabel(item.analytics);
    return MeasurementListData(
      title: _dateLabel(loop.createdAt),
      subtitle:
          '${loop.sampleCount} ${_recordWord(loop.sampleCount)} • ${_loopDurationLabel(loop)}',
      result: result,
      isBest: item.isBest,
      isPending: item.analytics?.time0to100Sec == null,
    );
  }

  List<_SeriesViewData> _seriesViewData(RecordingState state) {
    final grouped = <String, List<RecordedLoop>>{};
    for (final loop in state.loops) {
      final seriesId = loop.seriesId;
      if (seriesId == null || !loop.isSaved) continue;
      grouped.putIfAbsent(seriesId, () => <RecordedLoop>[]).add(loop);
    }
    return grouped.entries
        .map((entry) => _SeriesViewData(entry.key, entry.value))
        .toList(growable: false);
  }

  MeasurementListData _seriesListData(_SeriesViewData item) {
    final records = item.loops.fold<int>(
      0,
      (total, loop) => total + loop.sampleCount,
    );
    return MeasurementListData(
      title: item.isCompleted ? 'Завершённая серия' : 'Активная серия',
      subtitle:
          '${_dateLabel(item.loops.first.createdAt)} • $records ${_recordWord(records)}',
      result: '${item.loops.length}',
      resultCaption: _measurementWord(item.loops.length),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bluetooth_searching_rounded),
              title: const Text('Найти другое устройство'),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(_findAnotherDevice());
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Обновить данные'),
              onTap: () {
                Navigator.pop(sheetContext);
                unawaited(context.read<RecordingCubit>().loadLoops());
              },
            ),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('GPS Tracker Analyzer'),
              subtitle: Text('Мобильный анализ GPS-замеров'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTab(MobileTab tab) {
    setState(() {
      _tab = tab;
      _stage = _FlowStage.main;
    });
  }

  Future<void> _exportSeries(List<RecordedLoop> loops) async {
    if (loops.isEmpty) return;
    var exported = 0;
    for (final loop in loops) {
      try {
        if (await widget.sessionStore.exportLoop(loop) != null) exported++;
      } catch (_) {
        // Report the aggregate result after all files have been attempted.
      }
    }
    if (!mounted) return;
    _showMessage(
      exported == loops.length
          ? 'Серия экспортирована в папку Downloads'
          : 'Экспортировано $exported из ${loops.length} файлов',
    );
  }

  Future<void> _exportLoop(RecordedLoop loop) async {
    String? result;
    try {
      result = await widget.sessionStore.exportLoop(loop);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    _showMessage(
      result == null
          ? 'Не удалось экспортировать замер'
          : 'Замер экспортирован в папку Downloads',
    );
  }

  Future<void> _shareResult(PerformanceReportData? analytics) async {
    final loop = _selectedLoop ?? _lastResult;
    if (loop == null) return;
    final acceleration = analytics?.isValid == true
        ? analytics?.time0to100Sec
        : null;
    final text = acceleration == null
        ? '${loop.title}: ${loop.sampleCount} записей'
        : '${loop.title}: 0–100 км/ч за ${acceleration.toStringAsFixed(1)} с';
    final outcome = await ResultSharer().shareText(
      text,
      subject: loop.title,
      chooserTitle: 'Поделиться результатом',
    );
    if (!mounted) return;
    switch (outcome) {
      case ResultShareOutcome.shared:
        break;
      case ResultShareOutcome.copiedToClipboard:
        _showMessage('Системное меню недоступно — результат скопирован');
      case ResultShareOutcome.unavailable:
        _showMessage('Не удалось поделиться результатом');
    }
  }

  bool _canSystemPop(RecordingState recording) {
    if (recording.isRecording) return false;
    return _stage == _FlowStage.connect ||
        (_stage == _FlowStage.main && _tab == MobileTab.home);
  }

  void _handleSystemBack(RecordingState recording) {
    if (_stage == _FlowStage.saving) return;

    if (recording.isRecording) {
      if (_stage == _FlowStage.earlyStop) {
        _setStage(
          recording.isPaused ? _FlowStage.connectionLost : _FlowStage.recording,
        );
      } else {
        _setStage(_FlowStage.earlyStop);
      }
      return;
    }

    switch (_stage) {
      case _FlowStage.connect:
        break;
      case _FlowStage.search:
        unawaited(_stopSearchAndReturn());
      case _FlowStage.main:
        if (_tab != MobileTab.home) {
          setState(() => _tab = MobileTab.home);
        }
      case _FlowStage.limit:
        _leaveMeasurementSetup(_FlowStage.main);
      case _FlowStage.preflight:
        _setStage(
          _addingMeasurement ? _FlowStage.addMeasurement : _FlowStage.limit,
        );
      case _FlowStage.recording:
        _setStage(_FlowStage.main);
      case _FlowStage.saving:
        break;
      case _FlowStage.result:
        _setStage(_FlowStage.main);
      case _FlowStage.addMeasurement:
        _leaveMeasurementSetup(_FlowStage.result);
      case _FlowStage.seriesSummary:
        _returnFromSeriesSummary();
      case _FlowStage.detail:
        _returnFromDetail();
      case _FlowStage.analysis:
        _setStage(_FlowStage.detail);
      case _FlowStage.permission:
      case _FlowStage.bluetoothOff:
        if (_connectionLostBeforeStart) {
          _leaveMeasurementSetup(_FlowStage.main);
          _connectionLostBeforeStart = false;
        } else {
          _setStage(_FlowStage.connect);
        }
      case _FlowStage.earlyStop:
        _setStage(_lastResult == null ? _FlowStage.main : _FlowStage.result);
      case _FlowStage.connectionLost:
        if (_connectionLostBeforeStart) {
          _leaveMeasurementSetup(_FlowStage.main);
          _connectionLostBeforeStart = false;
        } else {
          _setStage(_FlowStage.main);
        }
      case _FlowStage.saveError:
        _setStage(_FlowStage.result);
    }
  }

  void _onBluetoothState(BluetoothState current) {
    if (current.connection == GpsTelemetryConnectionState.bluetoothOff) {
      if (_stage == _FlowStage.preflight) {
        _connectionLostBeforeStart = true;
      }
      _setStage(_FlowStage.bluetoothOff);
      return;
    }
    if (current.connection == GpsTelemetryConnectionState.scanning &&
        _stage == _FlowStage.search) {
      _scanHasStarted = true;
    }
    if (current.connection == GpsTelemetryConnectionState.connected &&
        _stage == _FlowStage.search &&
        _searchActive &&
        !_connecting) {
      // A cancelled connection can finish after a newer scan has started.
      // Its owner performs cleanup; it must not complete or untimer the scan.
      return;
    }
    if (current.connection == GpsTelemetryConnectionState.connected) {
      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = null;
      final recording = context.read<RecordingCubit>().state;
      if (_connectionLostBeforeStart &&
          _pendingLoopId != null &&
          !recording.isRecording) {
        _connectionLostBeforeStart = false;
        _setStage(_FlowStage.preflight);
        return;
      }
      if (recording.isRecording &&
          (_stage == _FlowStage.connectionLost ||
              _stage == _FlowStage.search)) {
        _setStage(_FlowStage.recording);
        return;
      }
    } else if (current.connection == GpsTelemetryConnectionState.idle &&
        _stage == _FlowStage.preflight) {
      _connectionLostBeforeStart = true;
      _setStage(_FlowStage.connectionLost);
      return;
    } else if (current.connection == GpsTelemetryConnectionState.idle &&
        _stage == _FlowStage.search &&
        _scanHasStarted &&
        _searchActive) {
      _completeSearch();
      return;
    }
    final error = current.errorMessage;
    if (error == null) return;
    final normalized = error.toLowerCase();
    if (normalized.contains('разреш') || normalized.contains('permission')) {
      _setStage(_FlowStage.permission);
    } else if (normalized.contains('adapter is off') ||
        normalized.contains('bluetooth') && normalized.contains('off')) {
      _setStage(_FlowStage.bluetoothOff);
    } else {
      _showMessage(error);
    }
  }

  void _onRecordingState(RecordingState current) {
    final limit = current.recordingLimit;
    if (current.isRecording &&
        limit != null &&
        current.sampleCount >= limit &&
        _stage == _FlowStage.recording) {
      _setStage(_FlowStage.saving);
      return;
    }
    if (current.isPaused && _stage == _FlowStage.recording) {
      _setStage(_FlowStage.connectionLost);
      return;
    }
    if (current.isRecording &&
        !current.isPaused &&
        _stage == _FlowStage.connectionLost) {
      _setStage(_FlowStage.recording);
      return;
    }
    if (!current.isRecording && current.lastCompletedLoop != null) {
      unawaited(_handleCompletedLoop(current.lastCompletedLoop!));
      return;
    }
    if (!current.isRecording && current.errorMessage != null) {
      _setStage(_FlowStage.saveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BluetoothCubit, BluetoothState>(
          listenWhen: (previous, current) =>
              current.connection != previous.connection ||
              current.errorMessage != previous.errorMessage,
          listener: (context, state) => _onBluetoothState(state),
        ),
        BlocListener<RecordingCubit, RecordingState>(
          listenWhen: (previous, current) =>
              (current.recordingLimit != null &&
                  previous.sampleCount < current.recordingLimit! &&
                  current.sampleCount >= current.recordingLimit!) ||
              (current.isPaused && !previous.isPaused) ||
              (previous.isPaused && !current.isPaused && current.isRecording) ||
              (previous.isRecording &&
                  !current.isRecording &&
                  (current.lastCompletedLoop != null ||
                      current.errorMessage != null)),
          listener: (context, state) => _onRecordingState(state),
        ),
      ],
      child: BlocBuilder<RecordingCubit, RecordingState>(
        builder: (context, recording) {
          return PopScope<Object?>(
            canPop: _canSystemPop(recording),
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _handleSystemBack(recording);
            },
            child: BlocBuilder<BluetoothCubit, BluetoothState>(
              builder: (context, bluetooth) {
                return _buildCurrentScreen(recording, bluetooth);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen(
    RecordingState recording,
    BluetoothState bluetooth,
  ) {
    final activeSeriesId = _effectiveActiveSeriesId(recording);
    final series = _loopsForSeries(recording, activeSeriesId);
    final completedSeriesId = _latestCompletedSeriesId(recording);
    final completedSeries = _loopsForSeries(recording, completedSeriesId);
    final summarySeriesId = _summarySeriesId ?? activeSeriesId;
    final summarySeries = _loopsForSeries(recording, summarySeriesId);
    final activeSample = recording.latestSample ?? _latestSample;
    final dataActive = _dataActive(bluetooth.connection);
    final gpsReady = _gpsReady(bluetooth.connection);
    final speed = _decimal(activeSample?.speedKmh ?? 0);
    final elapsed = _durationLabel(recording.elapsed);
    final distance = recording.distanceMeters < 1000
        ? '${recording.distanceMeters.round()} м'
        : '${_decimal(recording.distanceKm, digits: 2)} км';
    final total =
        recording.recordingLimit ??
        (_selectedLimit.value ?? (recording.sampleCount + 1));

    return switch (_stage) {
      _FlowStage.connect => M01ConnectScreen(
        key: const ValueKey('screen-M01'),
        onFindDevice: () => unawaited(_startSearch()),
        onReconnect: _connectionCleanupPending
            ? null
            : () => unawaited(_reconnectLastDevice()),
      ),
      _FlowStage.search => Builder(
        key: const ValueKey('screen-M02'),
        builder: (context) {
          final discoveredDevices = List<BleDeviceInfo>.of(bluetooth.devices)
            ..sort((left, right) {
              final leftRssi = left.rssi;
              final rightRssi = right.rssi;
              if (leftRssi == null && rightRssi == null) {
                return left.remoteId.compareTo(right.remoteId);
              }
              if (leftRssi == null) return 1;
              if (rightRssi == null) return -1;
              final signalOrder = rightRssi.compareTo(leftRssi);
              return signalOrder != 0
                  ? signalOrder
                  : left.remoteId.compareTo(right.remoteId);
            });
          final devices = discoveredDevices
              .map(
                (device) => SearchDeviceData(
                  remoteId: device.remoteId,
                  name: device.name?.trim().isNotEmpty == true
                      ? device.name!.trim()
                      : 'GPS Tracker',
                  signalLabel: _signalLabel(device.rssi),
                  quality: _signalQuality(device.rssi),
                ),
              )
              .toList(growable: false);
          return M02DeviceSearchScreen(
            devices: devices,
            isSearching: _searchActive,
            isConnecting: _connecting,
            isFinishingConnection: _connectionCleanupPending,
            onBack: () => unawaited(_stopSearchAndReturn()),
            onConnect: _connecting || _connectionCleanupPending
                ? null
                : (remoteId) {
                    for (final device in bluetooth.devices) {
                      if (device.remoteId == remoteId) {
                        unawaited(_connectDevice(device));
                        return;
                      }
                    }
                    _showMessage('Устройство больше не доступно');
                  },
            onStopSearch: () => unawaited(_stopSearchAndReturn()),
            onRetry: _connecting ? null : () => unawaited(_startSearch()),
          );
        },
      ),
      _FlowStage.main => switch (_tab) {
        MobileTab.home =>
          series.isEmpty
              ? FutureBuilder<List<_LoopViewData>>(
                  future: _loadLoopViewData(
                    recording.loops.isEmpty
                        ? const <RecordedLoop>[]
                        : <RecordedLoop>[recording.loops.first],
                  ),
                  builder: (context, snapshot) {
                    final latest = snapshot.data?.firstOrNull;
                    return M03HomeScreen(
                      key: const ValueKey('screen-M03'),
                      deviceTitle:
                          bluetooth.connection ==
                              GpsTelemetryConnectionState.connected
                          ? 'Трекер подключён'
                          : 'Подключите трекер',
                      deviceSubtitle:
                          bluetooth.connection ==
                              GpsTelemetryConnectionState.connected
                          ? _signalLabel(_lastDeviceRssi)
                          : 'Нет соединения',
                      gpsStatus: gpsReady
                          ? 'GPS готов • точность ±$_gpsAccuracyMeters м'
                          : 'GPS ожидает точный сигнал',
                      lastMeasurement: latest == null
                          ? const MeasurementListData(
                              title: 'Замеров пока нет',
                              subtitle: 'Начните первый замер',
                              result: '—',
                              isPending: true,
                            )
                          : _measurementListData(latest),
                      onNewMeasurement: () => _openNewMeasurement(),
                      onLastMeasurement: recording.loops.isEmpty
                          ? null
                          : () => _openLoop(recording.loops.first),
                      onDevice: () => _selectTab(MobileTab.device),
                      onMore: _showMoreMenu,
                      onTabSelected: _selectTab,
                    );
                  },
                )
              : M04ActiveSeriesHomeScreen(
                  key: const ValueKey('screen-M04'),
                  deviceTitle:
                      bluetooth.connection ==
                          GpsTelemetryConnectionState.connected
                      ? _lastDeviceName
                      : 'Подключите трекер',
                  deviceSubtitle:
                      bluetooth.connection ==
                          GpsTelemetryConnectionState.connected
                      ? _signalLabel(_lastDeviceRssi)
                      : 'Нет соединения',
                  seriesSubtitle: _dateLabel(series.first.createdAt),
                  measurementCount: series.length,
                  recordCount: series.fold(
                    0,
                    (total, loop) => total + loop.sampleCount,
                  ),
                  previousLimit: _recordLimitLabel(series.first.recordingMode),
                  onContinueSeries: () =>
                      _openNewMeasurement(addToSeries: true),
                  onAddMeasurement: () =>
                      _openNewMeasurement(addToSeries: true),
                  onDevice: () => _selectTab(MobileTab.device),
                  onMore: _showMoreMenu,
                  onTabSelected: _selectTab,
                ),
        MobileTab.series => M12SeriesListScreen(
          key: const ValueKey('screen-M12'),
          hasActiveSeries: series.isNotEmpty,
          hasCompletedSeries: completedSeries.isNotEmpty,
          activeSubtitle: series.isEmpty
              ? 'Нет активной серии'
              : _dateLabel(series.first.createdAt),
          activeMeasurementCount: series.length,
          activeRecordCount: series.fold(
            0,
            (total, loop) => total + loop.sampleCount,
          ),
          completedMeasurementCount: completedSeries.length,
          completedRecordCount: completedSeries.fold(
            0,
            (total, loop) => total + loop.sampleCount,
          ),
          onContinueActive: series.isEmpty
              ? null
              : () => _openNewMeasurement(addToSeries: true),
          onOpenCompleted: completedSeries.isEmpty
              ? null
              : () => _openSeriesSummary(completedSeriesId),
          onNewSeries: () => unawaited(_beginNewSeries()),
          onMore: _showMoreMenu,
          onTabSelected: _selectTab,
        ),
        MobileTab.history => FutureBuilder<List<_LoopViewData>>(
          future: _loadLoopViewData(recording.loops),
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <_LoopViewData>[];
            final seriesRows = _seriesViewData(recording);
            return M13HistoryScreen(
              key: const ValueKey('screen-M13'),
              initialFilter: _historyFilter,
              measurements: rows.map(_measurementListData).toList(),
              series: seriesRows.map(_seriesListData).toList(),
              onFilterChanged: (filter) => _historyFilter = filter,
              onStartFirstMeasurement: () => _openNewMeasurement(),
              onMeasurement: (index) {
                if (index >= 0 && index < rows.length) {
                  _openLoop(rows[index].loop);
                }
              },
              onSeries: (index) {
                if (index >= 0 && index < seriesRows.length) {
                  _openSeriesSummary(seriesRows[index].id);
                }
              },
              onMore: _showMoreMenu,
              onTabSelected: _selectTab,
            );
          },
        ),
        MobileTab.device => M16DeviceScreen(
          key: const ValueKey('screen-M16'),
          deviceName: _lastDeviceName,
          signalLabel: _signalLabel(_lastDeviceRssi),
          connected:
              bluetooth.connection == GpsTelemetryConnectionState.connected,
          gpsReady: gpsReady,
          dataActive: dataActive,
          lastSyncLabel: dataActive
              ? 'сейчас'
              : _latestSample == null
              ? 'нет данных'
              : _dateLabel(_latestSample!.receivedAt),
          onDisconnect: () => unawaited(_disconnect()),
          onMore: _showMoreMenu,
          onTabSelected: _selectTab,
        ),
      },
      _FlowStage.limit =>
        (_selectedLimit == RecordLimit.manual
            ? M05BManualRecordLimitScreen(
                key: const ValueKey('screen-M05B'),
                initialSelection: _selectedLimit,
                onBack: () => _leaveMeasurementSetup(_FlowStage.main),
                onSelectionChanged: (value) =>
                    setState(() => _selectedLimit = value),
                onContinue: (value) {
                  _selectedLimit = value;
                  unawaited(_continueLimitSelection());
                },
              )
            : M05RecordLimitScreen(
                key: const ValueKey('screen-M05'),
                initialSelection: _selectedLimit,
                onBack: () => _leaveMeasurementSetup(_FlowStage.main),
                onSelectionChanged: (value) =>
                    setState(() => _selectedLimit = value),
                onContinue: (value) {
                  _selectedLimit = value;
                  unawaited(_continueLimitSelection());
                },
              )),
      _FlowStage.preflight =>
        gpsReady
            ? M06PreflightReadyScreen(
                key: const ValueKey('screen-M06'),
                recordLimitLabel: _recordLimitLabel(_recordingMode),
                accuracyLabel: '±$_gpsAccuracyMeters м',
                onBack: () => _setStage(
                  _addingMeasurement
                      ? _FlowStage.addMeasurement
                      : _FlowStage.limit,
                ),
                onStart: () => unawaited(_startRecording()),
                onChangeLimit: () => _setStage(
                  _addingMeasurement
                      ? _FlowStage.addMeasurement
                      : _FlowStage.limit,
                ),
              )
            : M06BPreflightWeakGpsScreen(
                key: const ValueKey('screen-M06B'),
                recordLimitLabel: _recordLimitLabel(_recordingMode),
                accuracyLabel: '±$_gpsAccuracyMeters м',
                onBack: () => _setStage(
                  _addingMeasurement
                      ? _FlowStage.addMeasurement
                      : _FlowStage.limit,
                ),
                onRetry: () => setState(() {}),
              ),
      _FlowStage.recording =>
        !gpsReady
            ? E03WeakGpsRecordingScreen(
                key: const ValueKey('screen-E03'),
                recorded: recording.sampleCount,
                total: total,
                manual: recording.recordingMode == TrackRecordingMode.manual,
                speed: speed,
                elapsed: elapsed,
                gpsAccuracy: '±$_gpsAccuracyMeters м',
                onStop: () => _setStage(_FlowStage.earlyStop),
              )
            : recording.recordingMode == TrackRecordingMode.manual
            ? M07BManualRecordingScreen(
                key: const ValueKey('screen-M07B'),
                recorded: recording.sampleCount,
                speed: speed,
                elapsed: elapsed,
                distance: distance,
                gpsAccuracy: '±$_gpsAccuracyMeters м',
                onStop: () => _setStage(_FlowStage.earlyStop),
              )
            : M07FixedRecordingScreen(
                key: const ValueKey('screen-M07'),
                recorded: recording.sampleCount,
                total: total,
                speed: speed,
                elapsed: elapsed,
                distance: distance,
                gpsAccuracy: '±$_gpsAccuracyMeters м',
                onStop: () => _setStage(_FlowStage.earlyStop),
              ),
      _FlowStage.earlyStop => E05EarlyStopScreen(
        key: const ValueKey('screen-E05'),
        recorded: recording.sampleCount,
        total: total,
        manual: recording.recordingMode == TrackRecordingMode.manual,
        speed: speed,
        elapsed: elapsed,
        onContinue: () => _setStage(
          recording.isPaused ? _FlowStage.connectionLost : _FlowStage.recording,
        ),
        onFinishAndSave: () => unawaited(_stopRecording()),
      ),
      _FlowStage.saving => M08SavingScreen(
        key: const ValueKey('screen-M08'),
        recordCountLabel:
            '${_lastResult?.sampleCount ?? recording.sampleCount} записей',
      ),
      _FlowStage.result => FutureBuilder<List<_LoopViewData>>(
        future: _loadLoopViewData(
          series.isNotEmpty
              ? series
              : _lastResult == null
              ? const <RecordedLoop>[]
              : <RecordedLoop>[_lastResult!],
        ),
        builder: (context, snapshot) {
          final loop = _lastResult;
          _LoopViewData? current;
          for (final item in snapshot.data ?? const <_LoopViewData>[]) {
            if (item.loop.id == loop?.id) {
              current = item;
              break;
            }
          }
          final data = current?.analytics;
          return M09MeasurementResultScreen(
            key: const ValueKey('screen-M09'),
            duration: loop == null ? '00:00' : _loopDurationLabel(loop),
            distance: loop == null
                ? '0 м'
                : '${_decimal(loop.distanceKm, digits: 2)} км',
            maxSpeed: '${_decimal(data?.maxSpeedKmh ?? 0)} км/ч',
            recordCount:
                '${loop?.sampleCount ?? 0} ${_recordWord(loop?.sampleCount ?? 0)}',
            acceleration: _resultLabel(data),
            isBest: current?.isBest == true && data?.time0to100Sec != null,
            onBack: () => _setStage(_FlowStage.main),
            onDone: () => _setStage(_FlowStage.main),
            onAddMeasurement: () => _openNewMeasurement(addToSeries: true),
            onFinishSeries: () => unawaited(_finishCurrentSeries()),
          );
        },
      ),
      _FlowStage.addMeasurement => M10AddMeasurementScreen(
        key: const ValueKey('screen-M10'),
        initialSelection: _selectedLimit,
        savedMeasurements: series.length,
        onBack: () => _leaveMeasurementSetup(_FlowStage.result),
        onSelectionChanged: (value) => setState(() => _selectedLimit = value),
        onContinue: (value) {
          _selectedLimit = value;
          unawaited(_continueLimitSelection());
        },
        onReturnToResult: () => _leaveMeasurementSetup(_FlowStage.result),
      ),
      _FlowStage.seriesSummary => FutureBuilder<List<_LoopViewData>>(
        future: _loadLoopViewData(summarySeries),
        builder: (context, snapshot) {
          final items = List<_LoopViewData>.of(
            snapshot.data ?? const <_LoopViewData>[],
          );
          if (_sortSeriesByResult) {
            items.sort((a, b) {
              final left = a.analytics?.time0to100Sec;
              final right = b.analytics?.time0to100Sec;
              if (left == null) return right == null ? 0 : 1;
              if (right == null) return -1;
              return left.compareTo(right);
            });
          }
          double? best;
          for (final item in items) {
            if (item.isBest) {
              best = item.analytics?.time0to100Sec;
              break;
            }
          }
          return M11SeriesSummaryScreen(
            key: const ValueKey('screen-M11'),
            measurements: items.map(_measurementListData).toList(),
            bestResult: best == null ? 'Не рассчитан' : '${_decimal(best)} с',
            measurementCount: summarySeries.length,
            recordCount: summarySeries.fold(
              0,
              (total, loop) => total + loop.sampleCount,
            ),
            completed:
                summarySeries.isNotEmpty &&
                summarySeries.every((loop) => loop.isSeriesCompleted),
            onBack: _returnFromSeriesSummary,
            onDone: () {
              _tab = MobileTab.series;
              _setStage(_FlowStage.main);
            },
            onMeasurement: (index) {
              if (index >= 0 && index < items.length) {
                _openLoop(items[index].loop);
              }
            },
            onCompare: () {
              setState(() => _sortSeriesByResult = true);
              _showMessage('Замеры отсортированы по результату');
            },
            onExport: () => unawaited(_exportSeries(summarySeries)),
          );
        },
      ),
      _FlowStage.detail => FutureBuilder<PerformanceReportData?>(
        future: _selectedLoop == null
            ? Future<PerformanceReportData?>.value()
            : _loadAnalytics(_selectedLoop!),
        builder: (context, snapshot) {
          final loop = _selectedLoop;
          final data = snapshot.data;
          return M14MeasurementDetailScreen(
            key: const ValueKey('screen-M14'),
            title: loop?.title ?? 'Замер',
            subtitle: loop == null
                ? 'Нет данных'
                : '${_dateLabel(loop.createdAt)} • ${loop.sampleCount} записей',
            duration: loop == null ? '00:00' : _loopDurationLabel(loop),
            distance: loop == null
                ? '0 м'
                : '${_decimal(loop.distanceKm, digits: 2)} км',
            maxSpeed: _decimal(data?.maxSpeedKmh ?? 0),
            acceleration: _resultLabel(data),
            chartSeries: data?.series ?? const <ChartSeriesPoint>[],
            onBack: _returnFromDetail,
            onMore: () {
              if (loop != null) {
                unawaited(_exportLoop(loop));
              }
            },
            onOpenAnalysis: () => _setStage(_FlowStage.analysis),
            onAddToSeries: loop == null
                ? null
                : () => unawaited(_addLoopToActiveSeries(loop)),
          );
        },
      ),
      _FlowStage.analysis => FutureBuilder<PerformanceReportData?>(
        future: _selectedLoop == null
            ? Future<PerformanceReportData?>.value()
            : _loadAnalytics(_selectedLoop!),
        builder: (context, snapshot) {
          final data = snapshot.data;
          return M15AnalysisScreen(
            key: const ValueKey('screen-M15'),
            result: _resultLabel(data),
            chartSeries: data?.series ?? const <ChartSeriesPoint>[],
            targetTimeSec: data?.isValid == true ? data?.time0to100Sec : null,
            analysisValid: data?.isValid == true && data?.time0to100Sec != null,
            onBack: () => _setStage(_FlowStage.detail),
            onMore: _showMoreMenu,
            onCompare: () {
              final seriesId = _selectedLoop?.seriesId;
              if (seriesId == null) {
                _showMessage('Сначала добавьте замер в серию');
              } else {
                _openSeriesSummary(seriesId);
              }
            },
            onShare: () => unawaited(_shareResult(data)),
          );
        },
      ),
      _FlowStage.permission => E01BluetoothPermissionScreen(
        key: const ValueKey('screen-E01'),
        onAllow: () => unawaited(_startSearch()),
        onNotNow: () => _setStage(_FlowStage.connect),
        onMore: _showMoreMenu,
      ),
      _FlowStage.bluetoothOff => E02BluetoothOffScreen(
        key: const ValueKey('screen-E02'),
        onEnable: () => unawaited(_enableBluetoothAndSearch()),
        onCancel: () {
          if (_connectionLostBeforeStart) {
            _leaveMeasurementSetup(_FlowStage.main);
            _connectionLostBeforeStart = false;
          } else {
            _setStage(_FlowStage.connect);
          }
        },
        onMore: _showMoreMenu,
      ),
      _FlowStage.connectionLost => E04ConnectionLostScreen(
        key: const ValueKey('screen-E04'),
        recorded: recording.sampleCount,
        total: total,
        manual: recording.recordingMode == TrackRecordingMode.manual,
        beforeStart: _connectionLostBeforeStart,
        onReconnect: () => unawaited(_reconnectDuringRecording()),
        onFinishAndSave: _connectionLostBeforeStart
            ? () {
                _leaveMeasurementSetup(_FlowStage.main);
                _connectionLostBeforeStart = false;
              }
            : () => unawaited(_stopRecording()),
      ),
      _FlowStage.saveError => E06SaveErrorScreen(
        key: const ValueKey('screen-E06'),
        recordCount: _lastResult?.sampleCount ?? recording.sampleCount,
        onRetry: () => unawaited(_retrySave()),
        onReturnToMeasurement: () => _setStage(_FlowStage.result),
      ),
    };
  }
}

class _LoopViewData {
  const _LoopViewData(this.loop, this.analytics, {this.isBest = false});

  final RecordedLoop loop;
  final PerformanceReportData? analytics;
  final bool isBest;

  _LoopViewData copyWith({bool? isBest}) {
    return _LoopViewData(loop, analytics, isBest: isBest ?? this.isBest);
  }
}

class _SeriesViewData {
  const _SeriesViewData(this.id, this.loops);

  final String id;
  final List<RecordedLoop> loops;

  bool get isCompleted => loops.every((loop) => loop.isSeriesCompleted);
}
