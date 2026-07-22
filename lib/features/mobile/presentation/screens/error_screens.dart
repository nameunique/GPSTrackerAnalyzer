import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

class MobileAlertSheetContent extends StatelessWidget {
  const MobileAlertSheetContent({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    this.color = AppColors.warning,
    this.primaryStyle = MobileButtonStyle.primary,
    this.secondaryStyle = MobileButtonStyle.secondary,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final Color color;
  final MobileButtonStyle primaryStyle;
  final MobileButtonStyle secondaryStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Text('!', style: MobileDesign.h2.copyWith(color: color)),
          ),
          const SizedBox(height: 12),
          Text(title, style: MobileDesign.h2),
          const SizedBox(height: 8),
          Text(message, style: MobileDesign.body),
          const SizedBox(height: 26),
          MobileActionButton(
            label: primaryLabel,
            onPressed: onPrimary,
            style: primaryStyle,
          ),
          const SizedBox(height: 12),
          MobileActionButton(
            label: secondaryLabel,
            onPressed: onSecondary,
            height: 48,
            style: secondaryStyle,
          ),
        ],
      ),
    );
  }
}

class E01BluetoothPermissionSheet extends StatelessWidget {
  const E01BluetoothPermissionSheet({super.key, this.onAllow, this.onNotNow});

  final VoidCallback? onAllow;
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) {
    return MobileAlertSheetContent(
      title: 'Разрешите поиск устройств',
      message:
          'Без доступа к устройствам поблизости приложение не сможет найти GPS-трекер.',
      primaryLabel: 'Разрешить',
      secondaryLabel: 'Не сейчас',
      onPrimary: onAllow,
      onSecondary: onNotNow,
      color: AppColors.gps,
    );
  }
}

class E02BluetoothOffSheet extends StatelessWidget {
  const E02BluetoothOffSheet({super.key, this.onEnable, this.onCancel});

  final VoidCallback? onEnable;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return MobileAlertSheetContent(
      title: 'Bluetooth выключен',
      message: 'Включите Bluetooth, чтобы подключиться к GPS-трекеру.',
      primaryLabel: 'Включить Bluetooth',
      secondaryLabel: 'Отмена',
      onPrimary: onEnable,
      onSecondary: onCancel,
    );
  }
}

class E05EarlyStopSheet extends StatelessWidget {
  const E05EarlyStopSheet({
    super.key,
    this.recorded = 84,
    this.total = 200,
    this.manual = false,
    this.onContinue,
    this.onFinishAndSave,
  });

  final int recorded;
  final int total;
  final bool manual;
  final VoidCallback? onContinue;
  final VoidCallback? onFinishAndSave;

  @override
  Widget build(BuildContext context) {
    return MobileAlertSheetContent(
      title: 'Завершить замер?',
      message: manual
          ? 'Записано $recorded записей. Можно продолжить или сохранить текущие данные.'
          : 'Записано $recorded из $total записей. Можно продолжить или сохранить текущие данные.',
      primaryLabel: 'Продолжить замер',
      secondaryLabel: 'Завершить и сохранить',
      onPrimary: onContinue,
      onSecondary: onFinishAndSave,
      secondaryStyle: MobileButtonStyle.danger,
    );
  }
}

class E01BluetoothPermissionScreen extends StatelessWidget {
  const E01BluetoothPermissionScreen({
    super.key,
    this.onAllow,
    this.onNotNow,
    this.onMore,
  });

  final VoidCallback? onAllow;
  final VoidCallback? onNotNow;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return _ModalStateScreen(
      onMore: onMore,
      sheet: E01BluetoothPermissionSheet(onAllow: onAllow, onNotNow: onNotNow),
    );
  }
}

class E02BluetoothOffScreen extends StatelessWidget {
  const E02BluetoothOffScreen({
    super.key,
    this.onEnable,
    this.onCancel,
    this.onMore,
  });

  final VoidCallback? onEnable;
  final VoidCallback? onCancel;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return _ModalStateScreen(
      onMore: onMore,
      sheet: E02BluetoothOffSheet(onEnable: onEnable, onCancel: onCancel),
    );
  }
}

class _ModalStateScreen extends StatelessWidget {
  const _ModalStateScreen({required this.sheet, required this.onMore});

  final Widget sheet;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MobileDesign.maxWidth),
            child: Stack(
              children: <Widget>[
                Opacity(
                  opacity: 0.55,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MobileTopBar(title: 'Главная', onMore: onMore),
                        const SizedBox(height: 14),
                        const Text('GPS Tracker', style: MobileDesign.h2),
                        const SizedBox(height: 8),
                        const Text(
                          'Для начала подключите устройство.',
                          style: MobileDesign.body,
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 180,
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Новый замер', style: MobileDesign.h2),
                              SizedBox(height: 8),
                              Text(
                                'Проверим Bluetooth, GPS и поток данных перед стартом.',
                                style: MobileDesign.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: AppColors.scrim),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: sheet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class E03WeakGpsRecordingScreen extends StatelessWidget {
  const E03WeakGpsRecordingScreen({
    super.key,
    this.recorded = 84,
    this.total = 200,
    this.manual = false,
    this.speed = '47,6',
    this.elapsed = '00:38',
    this.gpsAccuracy = '±18 м',
    this.onStop,
  });

  final int recorded;
  final int total;
  final bool manual;
  final String speed;
  final String elapsed;
  final String gpsAccuracy;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: MobileActionButton(
        label: 'Остановить',
        onPressed: onStop,
        style: MobileButtonStyle.danger,
      ),
      scrollable: true,
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              MobileStatusChip(
                label: 'GPS $gpsAccuracy',
                color: AppColors.warning,
              ),
              MobileStatusChip(
                label: manual ? 'До остановки' : '$total записей',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const MobileFeedbackBanner(
            title: 'Точность GPS снизилась',
            message: 'Неточные участки будут отмечены в результате.',
            color: AppColors.warning,
          ),
          const SizedBox(height: 14),
          if (manual)
            MobileRecordingCounter.manual(recorded: recorded)
          else
            MobileRecordingCounter.fixed(recorded: recorded, total: total),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: MobileMetricTile(
                  label: 'Скорость',
                  value: speed,
                  unit: 'км/ч',
                  color: AppColors.borderAccent,
                ),
              ),
              const SizedBox(width: 34),
              Expanded(
                child: MobileMetricTile(
                  label: 'Время',
                  value: elapsed,
                  color: AppColors.gps,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class E04ConnectionLostScreen extends StatelessWidget {
  const E04ConnectionLostScreen({
    super.key,
    this.recorded = 84,
    this.total = 200,
    this.manual = false,
    this.beforeStart = false,
    this.onReconnect,
    this.onFinishAndSave,
  });

  final int recorded;
  final int total;
  final bool manual;
  final bool beforeStart;
  final VoidCallback? onReconnect;
  final VoidCallback? onFinishAndSave;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(label: 'Подключить снова', onPressed: onReconnect),
          const SizedBox(height: 8),
          MobileActionButton(
            label: beforeStart ? 'Отменить замер' : 'Завершить и сохранить',
            onPressed: onFinishAndSave,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          MobileFeedbackBanner(
            title: beforeStart
                ? 'Соединение с трекером потеряно'
                : 'Замер приостановлен',
            message: beforeStart
                ? 'Замер ещё не начался. Подключите трекер снова, чтобы продолжить проверку.'
                : 'Новые данные не записываются. Уже полученные записи сохранены.',
            color: AppColors.error,
          ),
          const SizedBox(height: 14),
          if (!beforeStart) ...[
            if (manual)
              MobileRecordingCounter.manual(recorded: recorded)
            else
              MobileRecordingCounter.fixed(
                recorded: recorded,
                total: total,
                paused: true,
              ),
          ],
          const SizedBox(height: 16),
          Text(
            beforeStart
                ? 'Проверьте питание трекера и расстояние до смартфона.'
                : 'Оставайтесь на месте, пока связь восстанавливается.',
            textAlign: TextAlign.center,
            style: MobileDesign.body,
          ),
        ],
      ),
    );
  }
}

class E05EarlyStopScreen extends StatelessWidget {
  const E05EarlyStopScreen({
    super.key,
    this.recorded = 84,
    this.total = 200,
    this.manual = false,
    this.speed = '47,6',
    this.elapsed = '00:38',
    this.onContinue,
    this.onFinishAndSave,
  });

  final int recorded;
  final int total;
  final bool manual;
  final String speed;
  final String elapsed;
  final VoidCallback? onContinue;
  final VoidCallback? onFinishAndSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MobileDesign.maxWidth),
            child: Stack(
              children: <Widget>[
                Opacity(
                  opacity: 0.55,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      children: <Widget>[
                        if (manual)
                          MobileRecordingCounter.manual(recorded: recorded)
                        else
                          MobileRecordingCounter.fixed(
                            recorded: recorded,
                            total: total,
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: MobileMetricTile(
                                label: 'Скорость',
                                value: speed,
                                unit: 'км/ч',
                                color: AppColors.borderAccent,
                              ),
                            ),
                            const SizedBox(width: 34),
                            Expanded(
                              child: MobileMetricTile(
                                label: 'Время',
                                value: elapsed,
                                color: AppColors.gps,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(color: AppColors.scrim),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: E05EarlyStopSheet(
                      recorded: recorded,
                      total: total,
                      manual: manual,
                      onContinue: onContinue,
                      onFinishAndSave: onFinishAndSave,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class E06SaveErrorScreen extends StatelessWidget {
  const E06SaveErrorScreen({
    super.key,
    this.recordCount = 200,
    this.onRetry,
    this.onReturnToMeasurement,
  });

  final int recordCount;
  final VoidCallback? onRetry;
  final VoidCallback? onReturnToMeasurement;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(label: 'Повторить', onPressed: onRetry),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Вернуться к замеру',
            onPressed: onReturnToMeasurement,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error, width: 3),
            ),
            child: Text(
              '!',
              style: MobileDesign.metric.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Не удалось сохранить замер',
            textAlign: TextAlign.center,
            style: MobileDesign.h2,
          ),
          const SizedBox(height: 8),
          const Text(
            'Данные пока остаются на устройстве. Попробуйте ещё раз.',
            textAlign: TextAlign.center,
            style: MobileDesign.bodyLarge,
          ),
          const SizedBox(height: 16),
          MobileFeedbackBanner(
            title: 'Данные не потеряны',
            message: 'Трекер хранит $recordCount записей до повторной попытки.',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
