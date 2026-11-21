// Civic's tabs on ui_core's RawTabBar: one tab stop, the arrows moving
// along it (mirrored right to left) and choosing the tab they reach, a press
// choosing too; a screen reader hears each tab with its place; the caller
// holds the choice.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';

/// Three tabs, the caller's choice kept; returns the choices made.
Future<List<int>> _tabs(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  double width = 1440,
}) async {
  tester.view.physicalSize = Size(width, 900);
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
  // words lifted over the underline (CivicUnderlined), and a chosen label's
  // words stand as lifted, so none settles as it is chosen: the words seen
  // are the last.
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('a tab keeps its box and its words stand still as it is '
          'chosen'
          '(text x$scale, ${direction.name})', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _tabs(tester, direction: direction);
        Map<String, Rect> boxes() => {
          for (final label in ['Details', 'Documents', 'History'])
            label: tester.getRect(find.text(label).last),
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

  // More tabs than fit (a phone at twice the text) scroll along between a
  // chevron at each end, dark where tabs stand past it and faint where none
  // do; a tab chosen at an end stands whole beside the chevrons, none of it
  // under one; no chevrons where every tab fits.
  for (final direction in TextDirection.values) {
    testWidgets('a strip with tabs past its ends says so and shows a chosen '
        'tab whole (${direction.name})', (tester) async {
      const before = ValueKey<String>('civic-tabs-before');
      const after = ValueKey<String>('civic-tabs-after');
      final rtl = direction == TextDirection.rtl;
      Icon icon(Key key) => tester.widget<Icon>(
        find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
      );
      await _tabs(tester, direction: direction);
      expect(find.byKey(before), findsNothing);
      expect(find.byKey(after), findsNothing);

      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final chosen = await _tabs(tester, direction: direction, width: 390);
      // History stands past the end: the end's chevron dark, the start's
      // faint, each pointing on as read.
      expect(icon(after).color!.a, greaterThan(0.9));
      expect(icon(before).color!.a, lessThan(0.5));
      expect(
        icon(after).icon,
        rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      );
      expect(
        icon(before).icon,
        rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
      );
      expect(
        tester.getCenter(find.byKey(after)).dx,
        rtl ? lessThan(195) : greaterThan(195),
      );

      // The keyboard chooses the last tab: the strip brings it whole into
      // view beside the chevrons, and the start's chevron turns dark.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(chosen.last, 2);
      final words = tester.getRect(find.text('History').last);
      for (final key in [before, after]) {
        expect(
          words.overlaps(tester.getRect(find.byKey(key))),
          isFalse,
          reason: '$key',
        );
      }
      expect(words.left, greaterThanOrEqualTo(0));
      expect(words.right, lessThanOrEqualTo(390));
      expect(icon(before).color!.a, greaterThan(0.9));
      expect(icon(after).color!.a, lessThan(0.5));
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
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
