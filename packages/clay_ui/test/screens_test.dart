// Steady's everyday screens at a phone's, a tablet's and a desktop's width, by day and by night, and on a phone with
// text at 200% and right to left: each lays out with nothing overflowing and nothing thrown. On a desk, Tab runs down
// one column of a screen before the next.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : clayRegisteredFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  // Each screen with two columns on a desk, by a word in its first column.
  for (final (id, anchor) in const [
    ('settings', 'Compact rows'),
    ('overview', 'See Today'),
  ]) {
    testWidgets('$id at 1440: Tab runs down one column, then the next', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final screen = everydayScreens.firstWhere((s) => s.id == id);
      await tester.pumpWidget(screen.app(Brightness.light, TextDirection.ltr));
      await tester.pumpAndSettle();
      // The row of the two columns; read again at each stop, as Tab
      // scrolls the page to bring its stop into view.
      final row = find
          .ancestor(
            of: find.text(anchor),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Row &&
                  w.children.length == 3 &&
                  w.children.first is Expanded &&
                  w.children[1] is SizedBox &&
                  w.children.last is Expanded,
            ),
          )
          .last;
      // The stops in the two columns, in Tab order, until Tab comes round.
      final sides = <int>[];
      FocusNode? first;
      for (var i = 0; i < 80; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final node = FocusManager.instance.primaryFocus;
        if (node == null || node.context == null) continue;
        if (identical(node, first)) break;
        first ??= node;
        final rect = node.rect;
        final columns = tester.getRect(row).inflate(1);
        if (columns.contains(rect.topLeft) &&
            columns.contains(rect.bottomRight)) {
          sides.add(rect.center.dx < columns.center.dx ? 0 : 1);
        }
      }
      // Once Tab has crossed to the second column it stays there.
      final crossed = sides.indexOf(1);
      expect(crossed, greaterThan(0), reason: 'stops in both columns: $sides');
      expect(sides.sublist(crossed), everyElement(1), reason: '$sides');
    });
  }
  for (final screen in everydayScreens) {
    for (final width in const [390.0, 768.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('${screen.id} at ${width.toInt()} by ${brightness.name}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(screen.app(brightness, TextDirection.ltr));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
    testWidgets('${screen.id} at 390 with text at 200%', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(screen.app(Brightness.light, TextDirection.ltr));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
    testWidgets('${screen.id} at 390 right to left', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(screen.app(Brightness.light, TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
