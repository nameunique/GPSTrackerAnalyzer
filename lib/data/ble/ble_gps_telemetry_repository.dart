import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gps_tracker_analyzer/core/config/ble_gatt_config.dart';
import 'package:gps_tracker_analyzer/data/ble/gps_packet_parser.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/entities/gps_sample.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:logger/logger.dart';

class BleGpsTelemetryRepository implements GpsTelemetryRepository {
  BleGpsTelemetryRepository({
    required GpsPacketParser parser,
    required Logger logger,
  })  : _parser = parser,
        _logger = logger {
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _emitState(GpsTelemetryConnectionState.error);
      }
    });
    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning &&
          _lastState == GpsTelemetryConnectionState.scanning &&
          (_connectedDevice == null || _connectedDevice!.isDisconnected)) {
        _emitState(GpsTelemetryConnectionState.idle);
      }
    });
  }

  final GpsPacketParser _parser;
  final Logger _logger;

  final _samples = StreamController<GpsSample>.broadcast();
  final _connectionState =
      StreamController<GpsTelemetryConnectionState>.broadcast();
  final _discovered = StreamController<List<BleDeviceInfo>>.broadcast();

  final Map<String, BleDeviceInfo> _deviceMap = {};

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<bool>? _isScanningSub;

  BluetoothDevice? _connectedDevice;

  GpsTelemetryConnectionState _lastState = GpsTelemetryConnectionState.idle;

  void _emitState(GpsTelemetryConnectionState state) {
    _lastState = state;
    if (!_connectionState.isClosed) {
      _connectionState.add(state);
    }
  }

  void _emitDevices() {
    final list = _deviceMap.values.toList()
      ..sort((a, b) => a.remoteId.compareTo(b.remoteId));
    if (!_discovered.isClosed) {
      _discovered.add(list);
    }
  }

  @override
  Stream<GpsSample> get samples => _samples.stream;

  @override
  Stream<GpsTelemetryConnectionState> get connectionState =>
      _connectionState.stream;

  @override
  Stream<List<BleDeviceInfo>> get discoveredDevices => _discovered.stream;

  Guid get _serviceGuid => Guid(BleGattConfig.serviceUuid);

  Guid get _mainCharGuid => Guid(BleGattConfig.mainNotifyCharacteristicUuid);

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (await FlutterBluePlus.isSupported == false) {
      _emitState(GpsTelemetryConnectionState.error);
      throw UnsupportedError('Bluetooth LE is not supported on this device');
    }

    if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.off) {
      _emitState(GpsTelemetryConnectionState.error);
      throw StateError('Bluetooth adapter is off');
    }

    await stopScan();
    _deviceMap.clear();
    _emitDevices();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        // Extra safety: only show devices advertising our service.
        // (We also pass withServices to startScan below.)
        final advertised = r.advertisementData.serviceUuids;
        final hasService = advertised.contains(_serviceGuid);
        if (!hasService) continue;

        final id = r.device.remoteId.str;
        final name = r.device.platformName.isNotEmpty
            ? r.device.platformName
            : (r.device.advName.isNotEmpty ? r.device.advName : null);
        _deviceMap[id] = BleDeviceInfo(remoteId: id, name: name);
      }
      _emitDevices();
    });

    _emitState(GpsTelemetryConnectionState.scanning);

    await FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: [_serviceGuid],
      androidUsesFineLocation: true,
    );
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    if (_connectedDevice == null || _connectedDevice!.isDisconnected) {
      if (_lastState == GpsTelemetryConnectionState.scanning) {
        _emitState(GpsTelemetryConnectionState.idle);
      }
    }
  }

  @override
  Future<void> connect(String remoteId) async {
    await stopScan();
    _emitState(GpsTelemetryConnectionState.connecting);

    final device = BluetoothDevice.fromId(remoteId);
    _connectedDevice = device;

    try {
      // If Android still holds a previous connection, force-close it.
      try {
        await device.disconnect();
      } catch (_) {
        // ignore
      }

      await device.connect(
        timeout: const Duration(seconds: 20),
        autoConnect: false,
        mtu: null,
      );

      await device.connectionState
          .where((s) => s == BluetoothConnectionState.connected)
          .first;

      // Many BLE stacks behave better when MTU is negotiated early.
      try {
        await device.requestMtu(247);
      } catch (_) {
        // ignore (not supported on all devices)
      }

      final services = await device.discoverServices();
      final mainChar = _findMainCharacteristic(services);

      if (mainChar == null) {
        throw StateError(
          'Notify characteristic not found. Check BleGattConfig UUIDs.',
        );
      }

      await mainChar.setNotifyValue(true);

      await _notifySubscription?.cancel();
      _notifySubscription = mainChar.onValueReceived.listen((value) {
        final sample = _parser.parseMainPacket(value, DateTime.now());
        if (sample != null && !_samples.isClosed) {
          _samples.add(sample);
        }
      });

      if (_notifySubscription != null) {
        device.cancelWhenDisconnected(_notifySubscription!, next: true);
      }

      _emitState(GpsTelemetryConnectionState.connected);
    } catch (e, st) {
      _logger.e('BLE connect failed', error: e, stackTrace: st);
      _connectedDevice = null;
      await _notifySubscription?.cancel();
      _notifySubscription = null;
      _emitState(GpsTelemetryConnectionState.error);
      rethrow;
    }
  }

  BluetoothCharacteristic? _findMainCharacteristic(
    List<BluetoothService> services,
  ) {
    BluetoothCharacteristic? anyServiceMatch;
    for (final s in services) {
      final serviceMatches = s.serviceUuid == _serviceGuid;
      for (final c in s.characteristics) {
        if (c.characteristicUuid == _mainCharGuid) {
          if (serviceMatches) {
            return c;
          }
          anyServiceMatch ??= c;
        }
      }
    }
    return anyServiceMatch;
  }

  @override
  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e, st) {
      _logger.w('BLE disconnect', error: e, stackTrace: st);
    } finally {
      _connectedDevice = null;
      _emitState(GpsTelemetryConnectionState.idle);
    }
  }

  Future<void> dispose() async {
    await _isScanningSub?.cancel();
    await _adapterSub?.cancel();
    await disconnect();
    await _scanSubscription?.cancel();
    await _samples.close();
    await _connectionState.close();
    await _discovered.close();
  }
}
