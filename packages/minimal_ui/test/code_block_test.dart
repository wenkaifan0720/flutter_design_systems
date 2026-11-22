import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/page_host.dart';

void main() {
  group('MinimalCodeBlock', () {
    testWidgets('copy puts the code on the clipboard and toasts', (
      tester,
    ) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      var copied = 0;
      await tester.pumpWidget(
        pageApp(
          MinimalCodeBlock(
            'curl https://api.ritual.app',
            label: 'bash',
            onCopy: () => copied++,
          ),
        ),
      );
      expect(find.text('BASH'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Copy'));
      await tester.pump();
      expect(clipboard, 'curl https://api.ritual.app');
      expect(copied, 1);
      expect(find.text('Copied to clipboard'), findsOneWidget);
      await tester.pump(MinimalChromeMetrics.toast);
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    // Floating over line 1, a finger's target reaches the block's top
    // edge: the rim is the target's too, not a pixel no tap reaches.
    testWidgets('a captionless block\'s copy takes a tap on its top rim', (
      tester,
    ) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      var copied = 0;
      await tester.pumpWidget(
        pageApp(
          MinimalCodeBlock(
            'curl https://api.ritual.app',
            onCopy: () => copied++,
          ),
        ),
      );
      final block = tester.getRect(find.byType(MinimalCodeBlock));
      final copy = tester.getRect(find.bySemanticsLabel('Copy'));
      await tester.tapAt(Offset(copy.center.dx, block.top + 0.5));
      await tester.pump();
      expect(copied, 1);
      await tester.pump(MinimalChromeMetrics.toast);
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('copyable: false drops the action; key caps print', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          const Column(
            children: [
              MinimalCodeBlock('HAB-4', copyable: false, lineNumbers: true),
              MinimalKbd('⌘'),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Copy'), findsNothing);
      // The mono face has no ⌘: the cap draws it as a glyph, named.
      expect(find.text('⌘'), findsNothing);
      expect(find.bySemanticsLabel('Command'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('MinimalCodeBlock line numbers', () {
    testWidgets('wrapped, each number stays beside its own line', (
      tester,
    ) async {
      await tester.pumpWidget(
        pageApp(
          const MinimalCodeBlock(
            'id: HAB-4\n'
            'note: out the door before 8, any distance counts, a run logged '
            'before 08:00 keeps the streak\n'
            'streak: 12',
            wrap: true,
            lineNumbers: true,
            copyable: false,
          ),
          width: 240,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text('3')).dy,
        tester.getTopLeft(find.text('streak: 12')).dy,
      );
      // The middle line wrapped, and the third number waited for it.
      expect(
        tester.getTopLeft(find.text('3')).dy -
            tester.getTopLeft(find.text('2')).dy,
        greaterThan(18),
      );
    });

    testWidgets('the number column fits its numbers at text scale 1.3', (
      tester,
    ) async {
      final code = [for (var i = 1; i <= 120; i++) 'line $i'].join('\n');
      final numbers = [for (var i = 1; i <= 120; i++) '$i'].join('\n');
      await tester.pumpWidget(
        pageApp(
          scaled(MinimalCodeBlock(code, lineNumbers: true, copyable: false)),
        ),
      );
      final column = tester.renderObject<RenderParagraph>(find.text(numbers));
      expect(
        column.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(column.size.width + 0.01),
      );
    });
  });
}
