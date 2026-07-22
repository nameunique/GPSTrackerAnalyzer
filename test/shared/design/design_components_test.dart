import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/core/theme/theme.dart';
import 'package:gps_tracker_analyzer/shared/design/design.dart';

void main() {
  testWidgets('design component catalog renders on a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTopBar(title: 'Главная', onMore: () {}),
                const SizedBox(height: 12),
                AppActionButton(label: 'Продолжить', onPressed: () {}),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AppStatusChip(kind: AppStatusKind.connected),
                ),
                const SizedBox(height: 12),
                AppDeviceBanner(
                  state: AppDeviceBannerState.connected,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                const AppMetricTile(kind: AppMetricKind.speed, value: '47,6'),
                const SizedBox(height: 12),
                const AppFeedbackBanner(
                  kind: AppFeedbackKind.info,
                  title: 'Безопасность прежде всего',
                  message: 'Не смотрите на экран во время движения.',
                ),
                const SizedBox(height: 12),
                AppRecordLimitOption(
                  limit: AppRecordLimit.records200,
                  selected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                AppMeasurementRow(
                  title: 'Замер 3 • лучший',
                  details: '242 записи • 01:58',
                  result: '7,8 с',
                  range: '0–100 км/ч',
                  state: AppMeasurementState.best,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                AppSessionCard(
                  title: 'Активная серия',
                  subtitle: 'Сегодня, 14:32',
                  measurementCount: 2,
                  recordCount: 400,
                  state: AppSessionState.active,
                  onAction: () {},
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 0,
            onTap: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Продолжить'), findsOneWidget);
    expect(find.text('Активная серия'), findsOneWidget);
    expect(find.text('Устройство'), findsOneWidget);
  });

  testWidgets('record limit and navigation expose their callbacks', (
    tester,
  ) async {
    var limitTapped = false;
    var navigationIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AppRecordLimitOption(
            limit: AppRecordLimit.manual,
            selected: false,
            onTap: () => limitTapped = true,
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: 0,
            onTap: (index) => navigationIndex = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('До остановки'));
    await tester.tap(find.text('История'));

    expect(limitTapped, isTrue);
    expect(navigationIndex, 2);
  });

  testWidgets('tappable surface keeps a 48dp minimum height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: AppSurfaceCard(
              padding: EdgeInsets.zero,
              onTap: () {},
              child: const SizedBox(width: 1, height: 1),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppSurfaceCard)).height, 48);
  });
}
