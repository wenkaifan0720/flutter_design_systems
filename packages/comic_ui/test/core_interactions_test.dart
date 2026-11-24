import 'package:comic_ui/comic_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);
  for (final device in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets(
      'Escape clears a ComicChart pointer readout without stealing focus from the button for ${device.name}',
      (t) async {
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await t.pumpWidget(
          comicApp(
            Column(
              children: [
                ComicButton('Continue', focusNode: focus, onPressed: () {}),
                const SizedBox(
                  width: 420,
                  child: ComicChart(
                    label: 'Weekly issues',
                    labels: ['Monday', 'Tuesday', 'Wednesday'],
                    series: [
                      ComicChartSeries('Printed', [3, 5, 7]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        await t.pumpAndSettle();
        focus.requestFocus();
        await t.pump();
        final chart = find.byType(RawChart);
        final center = t.getCenter(chart);
        final pointer = await t.createGesture(kind: device);
        addTearDown(pointer.removePointer);
        if (device == PointerDeviceKind.mouse) {
          await pointer.addPointer(location: Offset.zero);
          await pointer.moveTo(center);
        } else {
          await pointer.down(center);
          await pointer.up();
        }
        await t.pumpAndSettle();
        final readout = find.textContaining('Printed:');
        expect(readout, findsOneWidget);
        expect(focus.hasFocus, isTrue);
        await t.sendKeyEvent(LogicalKeyboardKey.escape);
        await t.pumpAndSettle();
        expect(readout, findsNothing);
        expect(focus.hasFocus, isTrue);
      },
    );
  }

  testWidgets('Alt and an arrow reorder a row from its keyboard grip', (
    t,
  ) async {
    final names = ['Cover', 'Letters', 'Back page'];
    await t.pumpWidget(
      comicApp(
        StatefulBuilder(
          builder: (context, setState) => ComicReorderableListView<String>(
            items: names,
            labelOf: (s) => s,
            itemBuilder: (context, s) => Text(s),
            onReorder: (from, to) =>
                setState(() => names.insert(to, names.removeAt(from))),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await t.pumpAndSettle();
    expect(names, ['Letters', 'Cover', 'Back page']);
  });
}
