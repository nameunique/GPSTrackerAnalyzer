enum MobileTab { home, series, history, device }

enum HistoryFilter { all, measurements, series }

enum SearchSignalQuality { excellent, good, weak, unknown }

class SearchDeviceData {
  const SearchDeviceData({
    required this.remoteId,
    required this.name,
    required this.signalLabel,
    this.quality = SearchSignalQuality.unknown,
  });

  final String remoteId;
  final String name;
  final String signalLabel;
  final SearchSignalQuality quality;
}

enum RecordLimit {
  records100(100, '100 записей', 'Короткий замер'),
  records200(200, '200 записей', 'Стандартный замер'),
  records300(300, '300 записей', 'Подробный замер'),
  manual(null, 'До остановки', 'Завершите вручную');

  const RecordLimit(this.value, this.label, this.description);

  final int? value;
  final String label;
  final String description;
}

class MeasurementListData {
  const MeasurementListData({
    required this.title,
    required this.subtitle,
    required this.result,
    this.resultCaption = '0–100 км/ч',
    this.isBest = false,
    this.isPending = false,
  });

  final String title;
  final String subtitle;
  final String result;
  final String resultCaption;
  final bool isBest;
  final bool isPending;
}

class DiagnosticData {
  const DiagnosticData({
    required this.label,
    required this.value,
    required this.kind,
  });

  final String label;
  final String value;
  final DiagnosticKind kind;
}

enum DiagnosticKind { success, gps, warning, error }
