import 'package:flutter/services.dart';

/// The operation ultimately used to make the result available to the user.
enum ResultShareOutcome {
  /// Android opened its native share sheet.
  shared,

  /// Native sharing was unavailable, so the text was copied instead.
  copiedToClipboard,

  /// Neither native sharing nor the clipboard was available.
  unavailable,
}

typedef NativeShareInvoker =
    Future<void> Function(Map<String, Object?> arguments);
typedef ClipboardWriter = Future<void> Function(String text);

/// Shares result text through the host platform, with a clipboard fallback.
///
/// The injectable callbacks keep this service usable in widget and unit tests
/// without installing platform-channel handlers.
final class ResultSharer {
  ResultSharer({
    NativeShareInvoker? nativeShareInvoker,
    ClipboardWriter? clipboardWriter,
  }) : _nativeShareInvoker = nativeShareInvoker ?? _invokeNativeShare,
       _clipboardWriter = clipboardWriter ?? _writeToClipboard;

  static const channelName = 'com.example.gps_tracker_analyzer/result_sharer';
  static const methodName = 'shareText';
  static const _channel = MethodChannel(channelName);

  final NativeShareInvoker _nativeShareInvoker;
  final ClipboardWriter _clipboardWriter;

  /// Opens the platform share sheet for [text].
  ///
  /// If the platform implementation is missing or throws, [text] is copied to
  /// the clipboard. Failures in both paths are represented by
  /// [ResultShareOutcome.unavailable] rather than escaping to the UI.
  Future<ResultShareOutcome> shareText(
    String text, {
    String? subject,
    String? chooserTitle,
  }) async {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }

    final arguments = <String, Object?>{
      'text': text,
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject,
      if (chooserTitle != null && chooserTitle.trim().isNotEmpty)
        'chooserTitle': chooserTitle,
    };

    try {
      await _nativeShareInvoker(arguments);
      return ResultShareOutcome.shared;
    } on MissingPluginException {
      return _copyToClipboard(text);
    } catch (_) {
      return _copyToClipboard(text);
    }
  }

  Future<ResultShareOutcome> _copyToClipboard(String text) async {
    try {
      await _clipboardWriter(text);
      return ResultShareOutcome.copiedToClipboard;
    } catch (_) {
      return ResultShareOutcome.unavailable;
    }
  }

  static Future<void> _invokeNativeShare(Map<String, Object?> arguments) =>
      _channel.invokeMethod<void>(methodName, arguments);

  static Future<void> _writeToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
