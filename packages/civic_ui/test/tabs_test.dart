// Civic's tabs on ui_core's DesignTabBar: one tab stop, the arrows moving
// along it (mirrored right to left) and choosing the tab they reach, a press
// choosing too; a screen reader hears each tab with its place; the caller
// holds the choice.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

/// Three tabs, the caller's choice kept; returns the choices made.
Future<List<int>> _tabs(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chosen = <int>[];
  var tab = 0;
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      direction: direction,
      home: StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            CivicTabBar(
              tabs: const ['Details', 'Documents', 'History'],
              selectedIndex: tab,
              onTap: (i) => setState(() {
                chosen.add(i);
                tab = i;
              }),
            ),
            Text('Showing ${['Details', 'Documents', 'History'][tab]}'),
            CivicButton(onPressed: () {}, child: const Text('Continue')),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return chosen;
}

void main() {
  testWidgets('a press chooses a tab', (tester) async {
    final chosen = await _tabs(tester);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(chosen, [2]);
    expect(find.text('Showing History'), findsOneWidget);
  });

  // A chosen tab's label turns bold in the room it had: no tab is cut, and
  // no label's box moves, across or up and down (at twice the text too, and
  // right to left). Right to left an underlined label is laid out twice, the
  // words lifted over the underline (CivicUnderlined): the box is the first.
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('a tab keeps its box as it is chosen '
          '(text x$scale, ${direction.name})', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _tabs(tester, direction: direction);
        Map<String, Rect> boxes() => {
          for (final label in ['Details', 'Documents', 'History'])
            label: tester.getRect(find.text(label).first),
        };
        final before = boxes();
        await tester.tap(find.text('History').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Documents').first);
        await tester.pumpAndSettle();
        final after = boxes();
        for (final label in before.keys) {
          expect(after[label]!.top, before[label]!.top, reason: label);
          expect(
            after[label]!.center.dx,
            before[label]!.center.dx,
            reason: label,
          );
        }
        // The chosen label's bold words fit its box: nothing runs over.
        final paragraph = tester.renderObject<RenderBox>(
          find.text('Documents').first,
        );
        expect(
          paragraph.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(paragraph.size.width + 0.01),
        );
      });
    }
  }

  for (final direction in TextDirection.values) {
    testWidgets('the bar is one tab stop; the arrow toward the end moves on '
        'and chooses (${direction.name})', (tester) async {
      final chosen = await _tabs(tester, direction: direction);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<CivicTabBar>(),
        isNotNull,
      );
      await tester.sendKeyEvent(
        direction == TextDirection.ltr
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft,
      );
      await tester.pumpAndSettle();
      expect(chosen, [1]);
      // Tab leaves the bar for what follows it: no second tab stop in it.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<CivicButton>(),
        isNotNull,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  testWidgets('a screen reader hears each tab and where it stands', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _tabs(tester);
    expect(
      tester.getSemantics(find.text('Documents')),
      isSemantics(
        label: 'Documents\nTab 2 of 3',
        isSelected: false,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Details')),
      isSemantics(label: 'Details\nTab 1 of 3', isSelected: true),
    );
    semantics.dispose();
  });
}
