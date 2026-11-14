// The period's drag (the look's laws, 2026-11-12): a row dragged by its grip
// leaves a dotted outline under the pointer and a line where it will land; no
// row moves until the drop; the drop reports the move; a drop off the list
// changes nothing.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _rows = ['Fonts', 'Sounds', 'Scripts'];

Future<List<(int, int)>> _host(WidgetTester tester, {bool dark = false}) async {
  final moves = <(int, int)>[];
  await tester.pumpWidget(
    retroDesktopApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: RetroDesktopReorderableListView<String>(
              items: _rows,
              labelOf: (s) => s,
              itemBuilder: (context, s) => Text(s),
              onReorder: (from, to) => moves.add((from, to)),
            ),
          ),
        ),
      ),
      dark: dark,
    ),
  );
  await tester.pumpAndSettle();
  return moves;
}

Finder _outline() => find.byWidgetPredicate(
  (w) =>
      w is RetroDesktopPixelPaint &&
      w.painter.runtimeType.toString() == '_DragOutline',
);

Finder _line() => find.descendant(
  of: find.byType(RetroDesktopReorderableListView<String>),
  matching: find.byWidgetPredicate((w) => w is Positioned && w.height == 2),
);

void main() {
  for (final dark in [false, true]) {
    final when = dark ? 'by night' : 'by day';

    testWidgets('$when: the outline follows, the line shows the place, '
        'nothing moves before the drop', (tester) async {
      final moves = await _host(tester, dark: dark);
      final before = {
        for (final s in _rows) s: tester.getTopLeft(find.text(s)),
      };
      final grip = tester.getCenter(find.byType(Draggable<Object>).first);
      final below =
          tester.getCenter(find.text('Scripts')).dy -
          tester.getCenter(find.text('Fonts')).dy +
          12;
      final finger = await tester.startGesture(grip);
      for (var i = 1; i <= 8; i++) {
        await finger.moveTo(grip + Offset(0, below * i / 8));
        await tester.pump();
      }
      expect(_outline(), findsOneWidget);
      expect(_line(), findsOneWidget);
      for (final s in _rows) {
        expect(tester.getTopLeft(find.text(s)), before[s], reason: s);
      }
      expect(moves, isEmpty);
      await finger.up();
      await tester.pump();
      expect(moves, [(0, 2)]);
      expect(_outline(), findsNothing);
      expect(_line(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$when: a drop off the list changes nothing', (tester) async {
      final moves = await _host(tester, dark: dark);
      final grip = tester.getCenter(find.byType(Draggable<Object>).first);
      final finger = await tester.startGesture(grip);
      for (var i = 1; i <= 8; i++) {
        await finger.moveTo(grip + Offset(i * 40, i * 20));
        await tester.pump();
      }
      expect(_outline(), findsOneWidget);
      expect(_line(), findsNothing);
      await finger.up();
      await tester.pump();
      expect(moves, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
