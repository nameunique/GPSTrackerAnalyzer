import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_analyzer/core/platform/result_sharer.dart';

void main() {
  group('ResultSharer', () {
    test(
      'passes text and optional labels to the native share channel',
      () async {
        Map<String, Object?>? receivedArguments;
        var clipboardWasUsed = false;
        final sharer = ResultSharer(
          nativeShareInvoker: (arguments) async {
            receivedArguments = arguments;
          },
          clipboardWriter: (_) async {
            clipboardWasUsed = true;
          },
        );

        final outcome = await sharer.shareText(
          'Lap result',
          subject: 'GPS report',
          chooserTitle: 'Send report',
        );

        expect(outcome, ResultShareOutcome.shared);
        expect(receivedArguments, {
          'text': 'Lap result',
          'subject': 'GPS report',
          'chooserTitle': 'Send report',
        });
        expect(clipboardWasUsed, isFalse);
      },
    );

    test('copies text when the native plugin is missing', () async {
      String? copiedText;
      final sharer = ResultSharer(
        nativeShareInvoker: (_) => throw MissingPluginException(),
        clipboardWriter: (text) async {
          copiedText = text;
        },
      );

      final outcome = await sharer.shareText('Lap result');

      expect(outcome, ResultShareOutcome.copiedToClipboard);
      expect(copiedText, 'Lap result');
    });

    test('copies text after any native share error', () async {
      String? copiedText;
      final sharer = ResultSharer(
        nativeShareInvoker: (_) =>
            throw PlatformException(code: 'share_failed'),
        clipboardWriter: (text) async {
          copiedText = text;
        },
      );

      final outcome = await sharer.shareText('Lap result');

      expect(outcome, ResultShareOutcome.copiedToClipboard);
      expect(copiedText, 'Lap result');
    });

    test('reports unavailable when both delivery paths fail', () async {
      final sharer = ResultSharer(
        nativeShareInvoker: (_) => throw StateError('share failed'),
        clipboardWriter: (_) => throw StateError('clipboard failed'),
      );

      final outcome = await sharer.shareText('Lap result');

      expect(outcome, ResultShareOutcome.unavailable);
    });

    test('rejects empty text before invoking either delivery path', () async {
      var nativeWasUsed = false;
      var clipboardWasUsed = false;
      final sharer = ResultSharer(
        nativeShareInvoker: (_) async {
          nativeWasUsed = true;
        },
        clipboardWriter: (_) async {
          clipboardWasUsed = true;
        },
      );

      await expectLater(sharer.shareText('   '), throwsA(isA<ArgumentError>()));
      expect(nativeWasUsed, isFalse);
      expect(clipboardWasUsed, isFalse);
    });
  });
}
