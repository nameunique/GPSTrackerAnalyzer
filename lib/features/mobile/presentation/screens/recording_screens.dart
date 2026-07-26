import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_models.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

class M07FixedRecordingScreen extends StatelessWidget {
  const M07FixedRecordingScreen({
    super.key,
    this.recorded = 84,
    this.total = 200,
    this.speed = '47,6',
    this.elapsed = '00:38',
    this.distance = '524 м',
    this.gpsAccuracy = '±3 м',
    this.onStop,
  });

  final int recorded;
  final int total;
  final String speed;
  final String elapsed;
  final String distance;
  final String gpsAccuracy;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return _RecordingScreenBody(
      recorded: recorded,
      total: total,
      speed: speed,
      elapsed: elapsed,
      distance: distance,
      gpsAccuracy: gpsAccuracy,
      manual: false,
      onStop: onStop,
    );
  }
}

class M07BManualRecordingScreen extends StatelessWidget {
  const M07BManualRecordingScreen({
    super.key,
    this.recorded = 84,
    this.speed = '47,6',
    this.elapsed = '00:38',
    this.distance = '524 м',
    this.gpsAccuracy = '±3 м',
    this.onStop,
  });

  final int recorded;
  final String speed;
  final String elapsed;
  final String distance;
  final String gpsAccuracy;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    return _RecordingScreenBody(
      recorded: recorded,
      total: null,
      speed: speed,
      elapsed: elapsed,
      distance: distance,
      gpsAccuracy: gpsAccuracy,
      manual: true,
      onStop: onStop,
    );
  }
}

class _RecordingScreenBody extends StatelessWidget {
  const _RecordingScreenBody({
    required this.recorded,
    required this.total,
    required this.speed,
    required this.elapsed,
    required this.distance,
    required this.gpsAccuracy,
    required this.manual,
    required this.onStop,
  });

  final int recorded;
  final int? total;
  final String speed;
  final String elapsed;
  final String distance;
  final String gpsAccuracy;
  final bool manual;
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
      bodyPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              MobileStatusChip(label: 'GPS $gpsAccuracy'),
              MobileStatusChip(
                label: manual ? 'Без лимита' : '$total записей',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (manual)
            MobileRecordingCounter.manual(recorded: recorded)
          else
            MobileRecordingCounter.fixed(recorded: recorded, total: total!),
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
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text('Дистанция', style: MobileDesign.small),
                ),
                Text(
                  distance,
                  style: MobileDesign.label.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MobileFeedbackBanner(
            title: manual ? 'Режим без лимита' : 'Безопасность прежде всего',
            message: manual
                ? 'Замер продолжится, пока вы не остановите его вручную.'
                : 'Не смотрите на экран во время движения.',
          ),
        ],
      ),
    );
  }
}

class M08SavingScreen extends StatelessWidget {
  const M08SavingScreen({super.key, this.recordCountLabel = '200 записей'});

  final String recordCountLabel;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bodyPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderAccent, width: 4),
              ),
              child: const Center(
                child: Text(
                  '•••',
                  style: TextStyle(
                    color: AppColors.gps,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Сохраняем замер…', style: MobileDesign.h1),
            const SizedBox(height: 4),
            const Text(
              'Не закрывайте приложение.',
              style: MobileDesign.bodyLarge,
            ),
            const SizedBox(height: 16),
            MobileStatusChip(
              label: recordCountLabel,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class M09MeasurementResultScreen extends StatelessWidget {
  const M09MeasurementResultScreen({
    super.key,
    this.duration = '01:42',
    this.distance = '1,27 км',
    this.maxSpeed = '87,4 км/ч',
    this.recordCount = '200 записей',
    this.acceleration = '8,4 с',
    this.isBest = true,
    this.onBack,
    this.onDone,
    this.onAddMeasurement,
    this.onFinishSeries,
  });

  final String duration;
  final String distance;
  final String maxSpeed;
  final String recordCount;
  final String acceleration;
  final bool isBest;
  final VoidCallback? onBack;
  final VoidCallback? onDone;
  final VoidCallback? onAddMeasurement;
  final VoidCallback? onFinishSeries;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(
            label: 'Добавить ещё замер',
            onPressed: onAddMeasurement,
          ),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Завершить серию',
            onPressed: onFinishSeries,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(
            title: 'Результат',
            onBack: onBack,
            endLabel: 'Готово',
            onEnd: onDone,
          ),
          const SizedBox(height: 16),
          MobileFeedbackBanner(
            title: 'Замер сохранён',
            message:
                'Сохранено $recordCount. Данные готовы к анализу и сравнению.',
            color: AppColors.success,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: MobileMetricTile(
                  label: 'Длительность',
                  value: duration,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MobileMetricTile(
                  label: 'Расстояние',
                  value: distance,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: MobileMetricTile(
                  label: 'Макс. скорость',
                  value: maxSpeed,
                  compact: true,
                  color: AppColors.borderAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MobileMetricTile(
                  label: 'Записано',
                  value: recordCount,
                  compact: true,
                  color: AppColors.gps,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 118,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(MobileDesign.radius),
              border: Border.all(color: AppColors.borderAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Разгон 0–100 км/ч', style: MobileDesign.small),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          acceleration,
                          maxLines: 1,
                          style: MobileDesign.display,
                        ),
                      ),
                    ),
                    if (isBest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Лучший',
                          style: MobileDesign.small.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class M10AddMeasurementScreen extends StatefulWidget {
  const M10AddMeasurementScreen({
    super.key,
    this.initialSelection = RecordLimit.records200,
    this.savedMeasurements = 1,
    this.onBack,
    this.onSelectionChanged,
    this.onContinue,
    this.onReturnToResult,
  });

  final RecordLimit initialSelection;
  final int savedMeasurements;
  final VoidCallback? onBack;
  final ValueChanged<RecordLimit>? onSelectionChanged;
  final ValueChanged<RecordLimit>? onContinue;
  final VoidCallback? onReturnToResult;

  @override
  State<M10AddMeasurementScreen> createState() =>
      _M10AddMeasurementScreenState();
}

class _M10AddMeasurementScreenState extends State<M10AddMeasurementScreen> {
  late RecordLimit _selection = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(
            label: 'Продолжить',
            onPressed: () => widget.onContinue?.call(_selection),
          ),
          const SizedBox(height: 8),
          MobileActionButton(
            label: 'Вернуться к результату',
            onPressed: widget.onReturnToResult,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(
            title: 'Добавить замер',
            onBack: widget.onBack,
            step: '1 / 2',
          ),
          const SizedBox(height: 12),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.accentSubtle,
              borderRadius: BorderRadius.circular(MobileDesign.radius),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Серия', style: MobileDesign.small)),
                Text(
                  '${widget.savedMeasurements} замер сохранён',
                  style: MobileDesign.body.copyWith(color: AppColors.gps),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Сколько записей сохранить?', style: MobileDesign.h3),
          const SizedBox(height: 14),
          for (final limit in RecordLimit.values) ...<Widget>[
            MobileRecordLimitOption(
              limit: limit,
              selected: limit == _selection,
              onTap: () {
                setState(() => _selection = limit);
                widget.onSelectionChanged?.call(limit);
              },
            ),
            if (limit != RecordLimit.values.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
