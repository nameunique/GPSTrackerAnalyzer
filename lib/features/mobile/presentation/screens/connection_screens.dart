import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_models.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

class M01ConnectScreen extends StatelessWidget {
  const M01ConnectScreen({super.key, this.onFindDevice, this.onReconnect});

  final VoidCallback? onFindDevice;
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(
            label: 'Найти устройство',
            onPressed: onFindDevice,
          ),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Подключиться снова',
            onPressed: onReconnect,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('GPS', style: MobileDesign.h3),
          ),
          const SizedBox(height: 16),
          const Text('Подключите GPS-трекер', style: MobileDesign.h1),
          const SizedBox(height: 8),
          const Text(
            'Включите трекер и держите его рядом со смартфоном.',
            style: MobileDesign.bodyLarge,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 164,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 104,
                  height: 132,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderAccent, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'GPS',
                        style: MobileDesign.h1.copyWith(color: AppColors.gps),
                      ),
                    ],
                  ),
                ),
                const Text('Bluetooth • GPS', style: MobileDesign.small),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Подключение займёт меньше минуты',
              style: MobileDesign.small,
            ),
          ),
        ],
      ),
    );
  }
}

class M02DeviceSearchScreen extends StatelessWidget {
  const M02DeviceSearchScreen({
    super.key,
    this.devices = const <SearchDeviceData>[],
    this.isSearching = true,
    this.isConnecting = false,
    this.isFinishingConnection = false,
    this.onBack,
    this.onConnect,
    this.onStopSearch,
    this.onRetry,
  });

  final List<SearchDeviceData> devices;
  final bool isSearching;
  final bool isConnecting;
  final bool isFinishingConnection;
  final VoidCallback? onBack;
  final ValueChanged<String>? onConnect;
  final VoidCallback? onStopSearch;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      scrollable: true,
      bottom: MobileActionButton(
        key: ValueKey(
          isConnecting
              ? 'search-connecting'
              : isSearching
              ? 'search-stop'
              : 'search-retry',
        ),
        label: isConnecting
            ? 'Подключаемся…'
            : isSearching
            ? 'Остановить поиск'
            : 'Повторить поиск',
        onPressed: isConnecting
            ? null
            : isSearching
            ? onStopSearch
            : onRetry,
        style: isSearching || isConnecting
            ? MobileButtonStyle.secondary
            : MobileButtonStyle.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(
            title: 'Поиск устройства',
            onBack: onBack,
            step: '1 / 3',
          ),
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            label: isConnecting
                ? 'Подключаемся к трекеру. Не закрывайте экран'
                : isFinishingConnection
                ? 'Подготавливаем новый поиск. Завершаем предыдущее подключение'
                : isSearching
                ? 'Ищем трекер. Держите устройство рядом'
                : devices.isEmpty
                ? 'Поиск завершён. Устройства не найдены'
                : 'Поиск завершён. Можно подключиться или повторить поиск',
            child: ExcludeSemantics(
              child: MobileDeviceBanner(
                title: isConnecting
                    ? 'Подключаемся к трекеру…'
                    : isFinishingConnection
                    ? 'Подготавливаем новый поиск…'
                    : isSearching
                    ? 'Ищем трекер…'
                    : 'Поиск завершён',
                subtitle: isConnecting
                    ? 'Не закрывайте экран'
                    : isFinishingConnection
                    ? 'Завершаем предыдущее подключение'
                    : isSearching
                    ? 'Держите устройство рядом'
                    : devices.isEmpty
                    ? 'Устройства не найдены'
                    : 'Можно подключиться или повторить поиск',
                color: isSearching || isConnecting || isFinishingConnection
                    ? AppColors.gps
                    : AppColors.textMuted,
                showChevron: true,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (devices.isEmpty)
            _SearchEmptyState(
              key: const ValueKey('search-empty-state'),
              isSearching: isSearching,
            )
          else
            _SearchResults(
              devices: devices,
              isSearching: isSearching,
              actionsPending: isFinishingConnection,
              onConnect: onConnect,
            ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({super.key, required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Устройства пока не найдены', style: MobileDesign.h2),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 184),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const _SearchRadarIllustration(),
              const SizedBox(height: 8),
              Text(
                'Пока здесь пусто',
                textAlign: TextAlign.center,
                style: MobileDesign.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearching
                    ? 'Включите GPS-трекер и держите его рядом — он появится здесь автоматически.'
                    : 'Включите GPS-трекер, затем нажмите «Повторить поиск».',
                textAlign: TextAlign.center,
                style: MobileDesign.small.copyWith(
                  height: 19 / 13,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Не видите трекер? Проверьте питание устройства и Bluetooth на смартфоне.',
          style: MobileDesign.small.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SearchRadarIllustration extends StatelessWidget {
  const _SearchRadarIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.gps.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gps, width: 2),
            ),
            alignment: Alignment.center,
            child: const SizedBox.square(
              dimension: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.gps,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.devices,
    required this.isSearching,
    required this.actionsPending,
    required this.onConnect,
  });

  final List<SearchDeviceData> devices;
  final bool isSearching;
  final bool actionsPending;
  final ValueChanged<String>? onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('Найденные устройства', style: MobileDesign.h2),
            ),
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${devices.length}',
                style: MobileDesign.small.copyWith(
                  color: AppColors.gps,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < devices.length; index++) ...<Widget>[
          _SearchDeviceCard(
            key: ValueKey('search-device-${devices[index].remoteId}'),
            device: devices[index],
            highlighted: index == 0,
            onConnect: onConnect,
          ),
          if (index != devices.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text(
          actionsPending
              ? 'Завершаем предыдущую попытку подключения. Кнопки станут доступны автоматически.'
              : isSearching
              ? 'Выберите нужный трекер. Поиск продолжится, пока вы не подключитесь или не остановите его.'
              : 'Выберите нужный трекер или повторите поиск, чтобы обновить список.',
          style: MobileDesign.small.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SearchDeviceCard extends StatelessWidget {
  const _SearchDeviceCard({
    super.key,
    required this.device,
    required this.highlighted,
    required this.onConnect,
  });

  final SearchDeviceData device;
  final bool highlighted;
  final ValueChanged<String>? onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? AppColors.borderAccent : AppColors.border,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const MobileBluetoothGlyph(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MobileDesign.label.copyWith(
                    fontSize: 15,
                    height: 21 / 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device.signalLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MobileDesign.small.copyWith(
                    color: switch (device.quality) {
                      SearchSignalQuality.excellent ||
                      SearchSignalQuality.good => AppColors.success,
                      SearchSignalQuality.weak => AppColors.warning,
                      SearchSignalQuality.unknown => AppColors.textMuted,
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            enabled: onConnect != null,
            label: 'Подключить ${device.name}',
            excludeSemantics: true,
            onTap: onConnect == null ? null : () => onConnect!(device.remoteId),
            child: SizedBox(
              width: 120,
              height: 52,
              child: FilledButton(
                key: ValueKey('search-connect-${device.remoteId}'),
                onPressed: onConnect == null
                    ? null
                    : () => onConnect!(device.remoteId),
                style: FilledButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accent.withValues(
                    alpha: AppColors.disabledOpacity,
                  ),
                  foregroundColor: AppColors.textOnAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MobileDesign.radius),
                  ),
                ),
                child: Text(
                  'Подключить',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MobileDesign.small.copyWith(
                    color: AppColors.textOnAccent,
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class M03HomeScreen extends StatelessWidget {
  const M03HomeScreen({
    super.key,
    this.deviceTitle = 'Трекер подключён',
    this.deviceSubtitle = 'Сигнал отличный',
    this.gpsStatus = 'GPS готов • точность ±3 м',
    this.lastMeasurement = const MeasurementListData(
      title: 'Сегодня, 14:32',
      subtitle: '200 записей • 01:42',
      result: '8,4 с',
    ),
    this.onNewMeasurement,
    this.onLastMeasurement,
    this.onDevice,
    this.onMore,
    this.onTabSelected,
  });

  final String deviceTitle;
  final String deviceSubtitle;
  final String gpsStatus;
  final MeasurementListData lastMeasurement;
  final VoidCallback? onNewMeasurement;
  final VoidCallback? onLastMeasurement;
  final VoidCallback? onDevice;
  final VoidCallback? onMore;
  final ValueChanged<MobileTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottomNavigation: MobileBottomNavigation(
        active: MobileTab.home,
        onSelected: onTabSelected,
      ),
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'Главная', onMore: onMore),
          const SizedBox(height: 16),
          MobileDeviceBanner(
            title: deviceTitle,
            subtitle: deviceSubtitle,
            onTap: onDevice,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(MobileDesign.largeRadius),
              border: Border.all(color: AppColors.borderAccent),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Готовы к новому замеру?',
                      style: MobileDesign.h2,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gpsStatus,
                      style: MobileDesign.body.copyWith(color: AppColors.gps),
                    ),
                  ],
                ),
                MobileActionButton(
                  label: 'Новый замер',
                  onPressed: onNewMeasurement,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Последний замер', style: MobileDesign.h3),
          const SizedBox(height: 16),
          MobileMeasurementRow(onTap: onLastMeasurement, data: lastMeasurement),
        ],
      ),
    );
  }
}

class M04ActiveSeriesHomeScreen extends StatelessWidget {
  const M04ActiveSeriesHomeScreen({
    super.key,
    this.deviceTitle = 'Трекер подключён',
    this.deviceSubtitle = 'Сигнал отличный',
    this.seriesSubtitle = 'Сегодня, 14:32',
    this.measurementCount = 2,
    this.recordCount = 400,
    this.previousLimit = '200 записей',
    this.onContinueSeries,
    this.onAddMeasurement,
    this.onDevice,
    this.onMore,
    this.onTabSelected,
  });

  final String deviceTitle;
  final String deviceSubtitle;
  final String seriesSubtitle;
  final int measurementCount;
  final int recordCount;
  final String previousLimit;
  final VoidCallback? onContinueSeries;
  final VoidCallback? onAddMeasurement;
  final VoidCallback? onDevice;
  final VoidCallback? onMore;
  final ValueChanged<MobileTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottomNavigation: MobileBottomNavigation(
        active: MobileTab.home,
        onSelected: onTabSelected,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'Главная', onMore: onMore),
          const SizedBox(height: 16),
          MobileDeviceBanner(
            title: deviceTitle,
            subtitle: deviceSubtitle,
            onTap: onDevice,
          ),
          const SizedBox(height: 16),
          const Text('Продолжить работу', style: MobileDesign.h3),
          const SizedBox(height: 16),
          MobileSessionCard(
            title: 'Активная серия',
            subtitle: seriesSubtitle,
            stats:
                '$measurementCount ${_measurementWord(measurementCount)}'
                '   •   $recordCount ${_recordWord(recordCount)}',
            buttonLabel: 'Продолжить серию',
            onPressed: onContinueSeries,
            active: true,
          ),
          const SizedBox(height: 16),
          const Text('Быстрое действие', style: MobileDesign.h3),
          const SizedBox(height: 16),
          MobileActionButton(
            label: 'Добавить новый замер',
            onPressed: onAddMeasurement,
          ),
          const SizedBox(height: 12),
          Text('Предыдущий выбор: $previousLimit', style: MobileDesign.small),
        ],
      ),
    );
  }

  static String _measurementWord(int value) {
    final mod100 = value % 100;
    final mod10 = value % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'замеров';
    if (mod10 == 1) return 'замер';
    if (mod10 >= 2 && mod10 <= 4) return 'замера';
    return 'замеров';
  }

  static String _recordWord(int value) {
    final mod100 = value % 100;
    final mod10 = value % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'записей';
    if (mod10 == 1) return 'запись';
    if (mod10 >= 2 && mod10 <= 4) return 'записи';
    return 'записей';
  }
}
