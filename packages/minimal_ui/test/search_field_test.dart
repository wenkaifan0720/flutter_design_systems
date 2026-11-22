import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalSearchField', () {
    testWidgets('typing reports; the clear cap and Escape empty it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchField(
            hint: 'Search habits',
            clearable: true,
            focusNode: focus,
            onChanged: typed.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'run');
      await tester.pump();
      expect(find.text('run'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pump();
      expect(typed, ['run', '']);
      await tester.enterText(find.byType(TextField), 'read');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(typed.last, '');
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      handle.dispose();
    });

    testWidgets('Cancel shows while focused, and clears and leaves', (
      tester,
    ) async {
      var cancelled = 0;
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchField(showCancel: true, onCancel: () => cancelled += 1),
        ),
      );
      expect(find.text('Cancel'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancelled, 1);
      expect(find.text('water'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('scopes announce the current one and switch', (tester) async {
      final handle = tester.ensureSemantics();
      final scopes = <int>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchField(
            scopes: const ['All', 'Open', 'Done'],
            scopeIndex: 1,
            onScopeChanged: scopes.add,
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Open'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await tester.tap(find.text('Done'));
      expect(scopes, [2]);
      handle.dispose();
    });

    testWidgets('a tap on the box beside the text, its glyph too, focuses it', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        scrollingHost(MinimalSearchField(focusNode: focus)),
      );
      final box = tester.getRect(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.decoration is BoxDecoration,
              ),
            )
            .first,
      );
      final line = tester.getRect(find.byType(EditableText));
      // The glyph's column, left of the editable line.
      final glyph = box.centerLeft + const Offset(12, 0);
      expect(line.contains(glyph), isFalse);
      await tester.tapAt(glyph);
      await tester.pump();
      expect(focus.hasFocus, isTrue);
    });

    testWidgets('a disabled field takes no text', (tester) async {
      await tester.pumpWidget(
        scrollingHost(const MinimalSearchField(enabled: false)),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    });
  });
}
