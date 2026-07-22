import 'dart:async';
import 'dart:ui' show ImageByteFormat, SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/app.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';
import 'package:gps_tracker_analyzer/domain/entities/ble_device_info.dart';
import 'package:gps_tracker_analyzer/domain/repositories/gps_telemetry_repository.dart';
import 'package:gps_tracker_analyzer/domain/services/run_analytics.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_screens.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

import 'support/mobile_test_fakes.dart';

void main() {
  group('M02 device search flow', () {
    testWidgets('active empty scan never renders a fake result', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(devices: const []);
      addTearDown(telemetry.close);

      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-empty-state')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-stop')), findsOneWidget);
      expect(find.text('GPS Tracker Test'), findsNothing);
      expect(find.text('Подключить'), findsNothing);
      expect(telemetry.connectedRemoteIds, isEmpty);

      await tester.tap(find.byKey(const ValueKey('search-stop')));
      await tester.pump();
    });

    testWidgets('two results render and the second remoteId is connected', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(devices: const []);
      addTearDown(telemetry.close);
      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      telemetry.emitDevices(const <BleDeviceInfo>[
        BleDeviceInfo(
          remoteId: 'tracker-near',
          name: 'GPS Tracker Near',
          rssi: -48,
        ),
        BleDeviceInfo(
          remoteId: 'tracker-far',
          name: 'GPS Tracker Far',
          rssi: -77,
        ),
      ]);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('search-device-tracker-near')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('search-device-tracker-far')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('search-connect-tracker-far')),
      );
      await tester.pumpAndSettle();

      expect(telemetry.connectedRemoteIds, <String>['tracker-far']);
      expect(find.byKey(const ValueKey('screen-M03')), findsOneWidget);
    });

    testWidgets('an empty discovery update removes stale result rows', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(devices: const []);
      addTearDown(telemetry.close);
      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      telemetry.emitDevices(const <BleDeviceInfo>[
        BleDeviceInfo(remoteId: 'first', name: 'First tracker', rssi: -44),
        BleDeviceInfo(remoteId: 'second', name: 'Second tracker', rssi: -70),
      ]);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('search-device-first')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('search-device-second')),
        findsOneWidget,
      );

      telemetry.emitDevices(const <BleDeviceInfo>[]);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('search-device-first')), findsNothing);
      expect(find.byKey(const ValueKey('search-device-second')), findsNothing);
      expect(find.byKey(const ValueKey('search-empty-state')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('search-stop')));
      await tester.pump();
    });

    testWidgets('leaving during a delayed connect cannot reopen M03', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(
        devices: const <BleDeviceInfo>[
          BleDeviceInfo(remoteId: 'delayed', name: 'Delayed tracker'),
        ],
      )..connectGate = Completer<void>();
      addTearDown(telemetry.close);
      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      await tester.tap(find.byKey(const ValueKey('search-connect-delayed')));
      await tester.pump();
      expect(telemetry.connectedRemoteIds, <String>['delayed']);
      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-connecting')), findsOneWidget);
      expect(find.text('Подключаемся…'), findsOneWidget);
      expect(find.byKey(const ValueKey('search-retry')), findsNothing);
      final pendingAction = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const ValueKey('search-connecting')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(pendingAction.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('search-connecting')));
      await tester.pump();
      expect(telemetry.startScanCalls, 1);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);

      telemetry.connectGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);
      expect(find.byKey(const ValueKey('screen-M03')), findsNothing);
      expect(telemetry.disconnectCalls, 1);
      expect(
        telemetry.currentConnectionState,
        GpsTelemetryConnectionState.idle,
      );
    });

    testWidgets('a stale connect cannot replace a newly started search', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(
        devices: const <BleDeviceInfo>[
          BleDeviceInfo(remoteId: 'stale', name: 'Stale tracker'),
        ],
      )..connectGate = Completer<void>();
      addTearDown(telemetry.close);
      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      await tester.tap(find.byKey(const ValueKey('search-connect-stale')));
      await tester.pump();
      await tester.tap(find.byTooltip('Назад'));
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);

      tester
          .widget<M01ConnectScreen>(find.byType(M01ConnectScreen))
          .onFindDevice!();
      await tester.pump();
      expect(telemetry.startScanCalls, 2);
      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
      expect(
        tester
            .widget<M02DeviceSearchScreen>(find.byType(M02DeviceSearchScreen))
            .isSearching,
        isTrue,
      );

      telemetry.connectGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
      expect(find.byKey(const ValueKey('screen-M03')), findsNothing);
      expect(
        tester
            .widget<M02DeviceSearchScreen>(find.byType(M02DeviceSearchScreen))
            .isSearching,
        isTrue,
      );
      expect(
        telemetry.currentConnectionState,
        GpsTelemetryConnectionState.scanning,
      );
      expect(telemetry.disconnectCalls, 1);
      expect(telemetry.startScanCalls, 3);

      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
      expect(find.byKey(const ValueKey('search-retry')), findsOneWidget);
      expect(
        tester
            .widget<M02DeviceSearchScreen>(find.byType(M02DeviceSearchScreen))
            .isSearching,
        isFalse,
      );
    });

    testWidgets('a second connect waits for stale connection cleanup', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository(
        devices: const <BleDeviceInfo>[
          BleDeviceInfo(remoteId: 'tracker-a', name: 'Tracker A'),
          BleDeviceInfo(remoteId: 'tracker-b', name: 'Tracker B'),
        ],
      )..connectGate = Completer<void>();
      addTearDown(telemetry.close);
      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      await tester.tap(find.byKey(const ValueKey('search-connect-tracker-a')));
      await tester.pump();
      await tester.tap(find.byTooltip('Назад'));
      await tester.pump();
      tester
          .widget<M01ConnectScreen>(find.byType(M01ConnectScreen))
          .onFindDevice!();
      await tester.pump();

      final blockedConnect = tester.widget<FilledButton>(
        find.byKey(const ValueKey('search-connect-tracker-b')),
      );
      expect(blockedConnect.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('search-connect-tracker-b')));
      await tester.pump();
      expect(telemetry.connectedRemoteIds, <String>['tracker-a']);

      telemetry.connectGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
      expect(
        tester
            .widget<M02DeviceSearchScreen>(find.byType(M02DeviceSearchScreen))
            .isSearching,
        isTrue,
      );

      final availableConnect = tester.widget<FilledButton>(
        find.byKey(const ValueKey('search-connect-tracker-b')),
      );
      expect(availableConnect.onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('search-connect-tracker-b')));
      await tester.pumpAndSettle();

      expect(telemetry.connectedRemoteIds, <String>['tracker-a', 'tracker-b']);
      expect(
        telemetry.connectedRemoteIds.where((id) => id == 'tracker-b'),
        hasLength(1),
      );
      expect(find.byKey(const ValueKey('screen-M03')), findsOneWidget);
    });

    testWidgets('leaving during a delayed reconnect clears its connection', (
      tester,
    ) async {
      _configurePhoneViewport(tester);
      final telemetry = FakeGpsTelemetryRepository();
      addTearDown(telemetry.close);
      await _pumpFlow(tester, telemetry);
      await _openSearch(tester);

      await tester.tap(
        find.byKey(const ValueKey('search-connect-test-device')),
      );
      await tester.pumpAndSettle();
      tester.widget<M03HomeScreen>(find.byType(M03HomeScreen)).onTabSelected!(
        MobileTab.device,
      );
      await tester.pump();
      tester
          .widget<M16DeviceScreen>(find.byType(M16DeviceScreen))
          .onDisconnect!();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);
      expect(telemetry.disconnectCalls, 1);

      telemetry.connectGate = Completer<void>();
      tester
          .widget<M01ConnectScreen>(find.byType(M01ConnectScreen))
          .onReconnect!();
      await tester.pump();
      expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);

      await tester.tap(find.byTooltip('Назад'));
      await tester.pump();
      telemetry.connectGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);
      expect(find.byKey(const ValueKey('screen-M03')), findsNothing);
      expect(telemetry.disconnectCalls, 2);
      expect(
        telemetry.currentConnectionState,
        GpsTelemetryConnectionState.idle,
      );
    });

    for (final exit in <String>['stop', 'back']) {
      testWidgets('$exit stops scanning and returns to M01', (tester) async {
        _configurePhoneViewport(tester);
        final telemetry = FakeGpsTelemetryRepository(devices: const []);
        addTearDown(telemetry.close);
        await _pumpFlow(tester, telemetry);
        await _openSearch(tester);
        expect(telemetry.startScanCalls, 1);

        if (exit == 'stop') {
          await tester.tap(find.byKey(const ValueKey('search-stop')));
        } else {
          await tester.tap(find.byTooltip('Назад'));
        }
        await tester.pump();

        expect(telemetry.stopScanCalls, 1);
        expect(find.byKey(const ValueKey('screen-M01')), findsOneWidget);
      });
    }
  });

  group('M02 responsive result list', () {
    testWidgets('Bluetooth glyph paints a centered cyan contour at 28 px', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: RepaintBoundary(
                key: repaintKey,
                child: const MobileBluetoothGlyph(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final boundary =
          repaintKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      expect(boundary.size, const Size.square(28));

      final capture = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
        return (image: image, bytes: bytes);
      });
      expect(capture, isNotNull);
      final image = capture!.image;
      addTearDown(image.dispose);
      expect(image.width, 28);
      expect(image.height, 28);
      final bytes = capture.bytes;
      expect(bytes, isNotNull);

      var cyanPixelCount = 0;
      var minX = image.width;
      var minY = image.height;
      var maxX = -1;
      var maxY = -1;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final offset = (y * image.width + x) * 4;
          final red = bytes!.getUint8(offset);
          final green = bytes.getUint8(offset + 1);
          final blue = bytes.getUint8(offset + 2);
          final alpha = bytes.getUint8(offset + 3);
          final isCyan =
              alpha >= 32 && red <= 64 && green >= 150 && blue >= 180;
          if (!isCyan) continue;
          cyanPixelCount++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }

      expect(cyanPixelCount, greaterThan(20));
      expect(maxX, greaterThan(minX));
      expect(maxY, greaterThan(minY));
      expect(maxX - minX + 1, inInclusiveRange(10, 18));
      expect(maxY - minY + 1, inInclusiveRange(22, 28));
      expect((minX + maxX) / 2, closeTo(13.5, 1.5));
      expect((minY + maxY) / 2, closeTo(13.5, 1.5));
    });

    testWidgets('every result uses the deterministic vector Bluetooth glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: M02DeviceSearchScreen(
            devices: <SearchDeviceData>[
              SearchDeviceData(
                remoteId: 'glyph-a',
                name: 'Tracker Alpha',
                signalLabel: 'Сигнал отличный',
              ),
              SearchDeviceData(
                remoteId: 'glyph-b',
                name: 'Tracker Beta',
                signalLabel: 'Сигнал хороший',
              ),
            ],
          ),
        ),
      );

      expect(find.byType(MobileBluetoothGlyph), findsNWidgets(2));
      expect(find.byIcon(Icons.bluetooth_rounded), findsNothing);
      for (final glyph in tester.widgetList<MobileBluetoothGlyph>(
        find.byType(MobileBluetoothGlyph),
      )) {
        expect(glyph.size, 28);
        expect(glyph.color, AppColors.gps);
      }
    });

    testWidgets('each enabled connect action has device-specific semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: M02DeviceSearchScreen(
            devices: const <SearchDeviceData>[
              SearchDeviceData(
                remoteId: 'semantic-a',
                name: 'Tracker Alpha',
                signalLabel: 'Сигнал отличный',
              ),
              SearchDeviceData(
                remoteId: 'semantic-b',
                name: 'Tracker Beta',
                signalLabel: 'Сигнал хороший',
              ),
            ],
            onConnect: (_) {},
          ),
        ),
      );

      for (final name in <String>['Tracker Alpha', 'Tracker Beta']) {
        final node = tester.getSemantics(
          find.bySemanticsLabel('Подключить $name'),
        );
        final data = node.getSemanticsData();
        expect(data.label, 'Подключить $name');
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      semantics.dispose();
    });

    testWidgets('weak signal is visually distinguished as a warning', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: M02DeviceSearchScreen(
            devices: <SearchDeviceData>[
              SearchDeviceData(
                remoteId: 'weak',
                name: 'Weak tracker',
                signalLabel: 'Сигнал слабый',
                quality: SearchSignalQuality.weak,
              ),
            ],
          ),
        ),
      );

      final signal = tester.widget<Text>(find.text('Сигнал слабый'));
      expect(signal.style?.color, AppColors.warning);
    });

    const viewports =
        <
          ({
            String name,
            Size size,
            double textScale,
            EdgeInsets safeInsets,
            int deviceCount,
          })
        >[
          (
            name: '360 accessible',
            size: Size(360, 800),
            textScale: 1.2,
            safeInsets: EdgeInsets.only(top: 24, bottom: 48),
            deviceCount: 4,
          ),
          (
            name: 'POCO',
            size: Size(393, 873),
            textScale: 1,
            safeInsets: EdgeInsets.only(top: 40, bottom: 47),
            deviceCount: 6,
          ),
        ];

    for (final viewport in viewports) {
      testWidgets(
        '${viewport.deviceCount} results remain reachable on ${viewport.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport.size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);

          final devices = List<SearchDeviceData>.generate(
            viewport.deviceCount,
            (index) => SearchDeviceData(
              remoteId: 'responsive-$index',
              name: 'GPS Tracker ${index + 1} with a deliberately long name',
              signalLabel: index.isEven ? 'Сигнал отличный' : 'Сигнал слабый',
              quality: index.isEven
                  ? SearchSignalQuality.excellent
                  : SearchSignalQuality.weak,
            ),
          );

          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    padding: viewport.safeInsets,
                    viewPadding: viewport.safeInsets,
                    textScaler: TextScaler.linear(viewport.textScale),
                  ),
                  child: child!,
                );
              },
              home: M02DeviceSearchScreen(
                devices: devices,
                onConnect: (_) {},
                onStopSearch: () {},
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          final bottomAction = find.byKey(const ValueKey('search-stop'));
          expect(bottomAction, findsOneWidget);
          final actionRect = tester.getRect(bottomAction);
          expect(actionRect.height, greaterThanOrEqualTo(48));
          expect(
            actionRect.bottom,
            lessThanOrEqualTo(
              viewport.size.height - viewport.safeInsets.bottom,
            ),
          );

          final lastResult = find.byKey(
            ValueKey('search-device-responsive-${viewport.deviceCount - 1}'),
          );
          expect(lastResult, findsOneWidget);
          await tester.ensureVisible(lastResult);
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(tester.getRect(lastResult).top, lessThan(actionRect.top));
        },
      );
    }
  });
}

void _configurePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpFlow(
  WidgetTester tester,
  FakeGpsTelemetryRepository telemetry,
) async {
  await tester.pumpWidget(
    GpsTrackerApp(
      telemetryRepository: telemetry,
      sessionStore: InMemorySessionStore(),
      analytics: RunAnalytics(),
    ),
  );
  await tester.pump();
}

Future<void> _openSearch(WidgetTester tester) async {
  tester
      .widget<M01ConnectScreen>(find.byType(M01ConnectScreen))
      .onFindDevice!();
  await tester.pump();
  expect(find.byKey(const ValueKey('screen-M02')), findsOneWidget);
}
