// A grouped list's row is a band of its card, standing out past the row's words; keyboard focus lifts that band. The
// band is the control a person sees, so its focus, its spoken outline and the room the row takes agree with it.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _page = Key('page');

Widget _group() => RepaintBoundary(
  key: _page,
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: NeumorphicListSection(
      children: [
        NeumorphicSwitchRow(label: 'Reminders', value: true, onChanged: (_) {}),
        NeumorphicListTile(title: 'Time', onPressed: () {}),
      ],
    ),
  ),
);

Future<ui.Image> _shot(WidgetTester tester) async => (await tester.runAsync(
  () => captureImage(tester.element(find.byKey(_page))),
))!;

/// The pixels of [a] and [b] that differ inside [area], in logical pixels of a 1x view.
Future<int> _changed(
  WidgetTester tester,
  ui.Image a,
  ui.Image b,
  Rect area,
) async {
  final (pa, pb) = (await tester.runAsync(
    () async => ((await a.toByteData())!, (await b.toByteData())!),
  ))!;
  var n = 0;
  for (
    var y = math.max(0, area.top.floor());
    y < math.min(a.height, area.bottom.ceil());
    y++
  ) {
    for (
      var x = math.max(0, area.left.floor());
      x < math.min(a.width, area.right.ceil());
      x++
    ) {
      final i = (y * a.width + x) * 4;
      if (pa.getUint32(i) != pb.getUint32(i)) n++;
    }
  }
  return n;
}

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final dark in [false, true]) {
    testWidgets(
      'a group\'s first row: its focus shows round where its focus is (${dark ? 'night' : 'day'})',
      (tester) async {
        tester.view.physicalSize = const Size(390, 300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(neumorphicApp(_group(), dark: dark));
        await tester.pumpAndSettle();
        final room = tester.getRect(find.byType(NeumorphicSwitchRow));
        final rest = await _shot(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final focused = await _shot(tester);
        final node = FocusManager.instance.primaryFocus!;
        expect(
          node.context!.findAncestorWidgetOfExactType<NeumorphicSwitchRow>(),
          isNotNull,
        );
        expect(
          tester.getRect(find.byType(NeumorphicSwitchRow)),
          room,
          reason: 'the row keeps its room in its column',
        );
        expect(
          node.rect.top,
          lessThan(room.top - 4),
          reason: 'focus is the band, out past the row\'s words',
        );
        expect(node.rect.left, lessThan(room.left - 4));
        expect(
          tester.getSemantics(find.bySemanticsLabel('Reminders')).rect.size,
          node.rect.size,
          reason: 'a screen reader outlines the band too',
        );
        expect(
          await _changed(
            tester,
            rest,
            focused,
            node.rect.inflate(4).shift(-tester.getTopLeft(find.byKey(_page))),
          ),
          greaterThanOrEqualTo(4),
          reason: 'the lift shows in or just round the focused node',
        );
        rest.dispose();
        focused.dispose();
        semantics.dispose();
      },
    );
  }
}
