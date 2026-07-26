import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/mobile_models.dart';
import 'package:gps_tracker_analyzer/features/mobile/presentation/src/mobile_components.dart';

class M05RecordLimitScreen extends StatefulWidget {
  const M05RecordLimitScreen({
    super.key,
    this.initialSelection = RecordLimit.records200,
    this.onBack,
    this.onSelectionChanged,
    this.onContinue,
  });

  final RecordLimit initialSelection;
  final VoidCallback? onBack;
  final ValueChanged<RecordLimit>? onSelectionChanged;
  final ValueChanged<RecordLimit>? onContinue;

  @override
  State<M05RecordLimitScreen> createState() => _M05RecordLimitScreenState();
}

class _M05RecordLimitScreenState extends State<M05RecordLimitScreen> {
  late RecordLimit _selection = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    return _RecordLimitScreenBody(
      selection: _selection,
      description:
          'Замер завершится автоматически после выбранного количества.',
      onBack: widget.onBack,
      onSelectionChanged: _select,
      onContinue: () => widget.onContinue?.call(_selection),
    );
  }

  void _select(RecordLimit value) {
    setState(() => _selection = value);
    widget.onSelectionChanged?.call(value);
  }
}

class M05BManualRecordLimitScreen extends StatefulWidget {
  const M05BManualRecordLimitScreen({
    super.key,
    this.initialSelection = RecordLimit.manual,
    this.onBack,
    this.onSelectionChanged,
    this.onContinue,
  });

  final RecordLimit initialSelection;
  final VoidCallback? onBack;
  final ValueChanged<RecordLimit>? onSelectionChanged;
  final ValueChanged<RecordLimit>? onContinue;

  @override
  State<M05BManualRecordLimitScreen> createState() =>
      _M05BManualRecordLimitScreenState();
}

class _M05BManualRecordLimitScreenState
    extends State<M05BManualRecordLimitScreen> {
  late RecordLimit _selection = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    return _RecordLimitScreenBody(
      selection: _selection,
      description: 'Можно выбрать лимит или остановить замер вручную.',
      onBack: widget.onBack,
      onSelectionChanged: _select,
      onContinue: () => widget.onContinue?.call(_selection),
    );
  }

  void _select(RecordLimit value) {
    setState(() => _selection = value);
    widget.onSelectionChanged?.call(value);
  }
}

class _RecordLimitScreenBody extends StatelessWidget {
  const _RecordLimitScreenBody({
    required this.selection,
    required this.description,
    required this.onBack,
    required this.onSelectionChanged,
    required this.onContinue,
  });

  final RecordLimit selection;
  final String description;
  final VoidCallback? onBack;
  final ValueChanged<RecordLimit> onSelectionChanged;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return MobileScreenShell(
      bottom: MobileActionButton(label: 'Продолжить', onPressed: onContinue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MobileTopBar(title: 'Новый замер', onBack: onBack, step: '1 / 2'),
          const SizedBox(height: 12),
          const Text('Сколько записей сохранить?', style: MobileDesign.h2),
          const SizedBox(height: 8),
          Text(description, style: MobileDesign.body),
          const SizedBox(height: 12),
          for (final limit in RecordLimit.values) ...<Widget>[
            MobileRecordLimitOption(
              limit: limit,
              selected: selection == limit,
              onTap: () => onSelectionChanged(limit),
            ),
            if (limit != RecordLimit.values.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class M06PreflightReadyScreen extends StatelessWidget {
  const M06PreflightReadyScreen({
    super.key,
    this.recordLimitLabel = '200 записей',
    this.accuracyLabel = '±3 м',
    this.onBack,
    this.onStart,
    this.onChangeLimit,
  });

  final String recordLimitLabel;
  final String accuracyLabel;
  final VoidCallback? onBack;
  final VoidCallback? onStart;
  final VoidCallback? onChangeLimit;

  @override
  Widget build(BuildContext context) {
    return _PreflightScreenBody(
      gpsReady: true,
      accuracyLabel: accuracyLabel,
      recordLimitLabel: recordLimitLabel,
      onBack: onBack,
      onPrimary: onStart,
      onSecondary: onChangeLimit,
    );
  }
}

class M06BPreflightWeakGpsScreen extends StatelessWidget {
  const M06BPreflightWeakGpsScreen({
    super.key,
    this.recordLimitLabel = '200 записей',
    this.accuracyLabel = '±18 м',
    this.onBack,
    this.onStart,
    this.onRetry,
  });

  final String recordLimitLabel;
  final String accuracyLabel;
  final VoidCallback? onBack;
  final VoidCallback? onStart;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _PreflightScreenBody(
      gpsReady: false,
      accuracyLabel: accuracyLabel,
      recordLimitLabel: recordLimitLabel,
      onBack: onBack,
      onPrimary: onStart,
      onSecondary: onRetry,
    );
  }
}

class _PreflightScreenBody extends StatelessWidget {
  const _PreflightScreenBody({
    required this.gpsReady,
    required this.accuracyLabel,
    required this.recordLimitLabel,
    required this.onBack,
    required this.onPrimary,
    required this.onSecondary,
  });

  final bool gpsReady;
  final String accuracyLabel;
  final String recordLimitLabel;
  final VoidCallback? onBack;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final gpsColor = gpsReady ? AppColors.gps : AppColors.warning;
    return MobileScreenShell(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MobileActionButton(label: 'Начать замер', onPressed: onPrimary),
          const SizedBox(height: 8),
          MobileActionButton(
            label: gpsReady ? 'Изменить количество' : 'Повторить проверку',
            onPressed: onSecondary,
            height: 48,
            style: MobileButtonStyle.secondary,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          MobileTopBar(
            title: 'Проверка перед стартом',
            onBack: onBack,
            step: '2 / 2',
          ),
          const SizedBox(height: 12),
          const MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'Трекер',
              value: 'Подключён',
              kind: DiagnosticKind.success,
            ),
          ),
          const SizedBox(height: 12),
          MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'GPS',
              value: gpsReady ? 'Точный сигнал' : 'Слабый сигнал',
              kind: gpsReady ? DiagnosticKind.gps : DiagnosticKind.warning,
            ),
          ),
          const SizedBox(height: 12),
          MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'Точность',
              value: accuracyLabel,
              kind: gpsReady ? DiagnosticKind.gps : DiagnosticKind.warning,
            ),
          ),
          const SizedBox(height: 12),
          MobileDiagnosticRow(
            data: DiagnosticData(
              label: 'Будет записано',
              value: recordLimitLabel,
              kind: DiagnosticKind.gps,
            ),
          ),
          const SizedBox(height: 12),
          MobileFeedbackBanner(
            title: gpsReady ? 'Безопасность прежде всего' : 'Слабый GPS-сигнал',
            message: gpsReady
                ? 'Закрепите смартфон и начинайте движение только в безопасном месте.'
                : 'Перейдите на открытое место и дождитесь более точного сигнала.',
            color: gpsColor,
          ),
        ],
      ),
    );
  }
}
