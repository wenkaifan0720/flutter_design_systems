// A page row's spans are shares of the row: [1, 1] is halves as [6, 6] is, and a row is always filled. Spans that add
// up to 12 read as a 12-column grid; a row whose spans don't still fills, each child taking its share.
// Side by side, Tab walks each section to its end before the next, as the tree (and a browser) reads them. Below the
// desk a row stacks, unless it is given `from`: then it stands side by side wherever the row itself is that wide.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Future<List<double>> _widths(WidgetTester tester, List<int> spans) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    neumorphicApp(
      SizedBox(
        width: 1028,
        child: NeumorphicRow(
          spans: spans,
          children: [
            for (var i = 0; i < spans.length; i++)
              SizedBox(key: ValueKey(i), height: 40),
          ],
        ),
      ),
      width: 1440,
    ),
  );
  return [
    for (var i = 0; i < spans.length; i++)
      tester.getSize(find.byKey(ValueKey(i))).width,
  ];
}

/// The sections' widths in a [rowWidth] row on a tablet's [window], and whether they stand side by side.
Future<(List<double>, bool)> _tablet(
  WidgetTester tester, {
  required double window,
  required double rowWidth,
  NeumorphicWindow? from,
}) async {
  tester.view.physicalSize = Size(window, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    neumorphicApp(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: rowWidth,
          child: NeumorphicRow(
            spans: const [1, 1],
            from: from,
            children: const [
              SizedBox(key: ValueKey(0), height: 40),
              SizedBox(key: ValueKey(1), height: 40),
            ],
          ),
        ),
      ),
      width: window,
    ),
  );
  final a = tester.getRect(find.byKey(const ValueKey(0)));
  final b = tester.getRect(find.byKey(const ValueKey(1)));
  return ([a.width, b.width], a.top == b.top);
}

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'from: a list beside its item on a tablet, stacked in a row narrower than a tablet\'s',
    (tester) async {
      // 768 past a rail: a row of 640.
      var (w, apart) = await _tablet(
        tester,
        window: 768,
        rowWidth: 640,
        from: NeumorphicWindow.medium,
      );
      expect(apart, isTrue);
      expect(w, [
        moreOrLessEquals((640 - 28) / 2),
        moreOrLessEquals((640 - 28) / 2),
      ]);
      // Without it, a row stacks below the desk.
      (w, apart) = await _tablet(tester, window: 768, rowWidth: 640);
      expect(apart, isFalse);
      expect(w, [640, 640]);
      // A 600 window past its rail leaves a row of 472: halves of 222 would be under a phone's column, so it stacks.
      (w, apart) = await _tablet(
        tester,
        window: 600,
        rowWidth: 472,
        from: NeumorphicWindow.medium,
      );
      expect(apart, isFalse);
      expect(w, [472, 472]);
      // On the desk a row stands side by side whatever its width.
      (w, apart) = await _tablet(
        tester,
        window: 1440,
        rowWidth: 472,
        from: NeumorphicWindow.medium,
      );
      expect(apart, isTrue);
    },
  );

  testWidgets('the grid: 7 and 5 columns, a 28 gutter between', (tester) async {
    final w = await _widths(tester, [7, 5]);
    expect(w[0], moreOrLessEquals((1028 + 28) * 7 / 12 - 28));
    expect(w[1], moreOrLessEquals((1028 + 28) * 5 / 12 - 28));
    expect(w[0] + w[1] + 28, moreOrLessEquals(1028));
  });

  testWidgets('spans that do not add up to 12 are shares of the row', (
    tester,
  ) async {
    final halves = await _widths(tester, [1, 1]);
    expect(halves, [
      moreOrLessEquals((1028 - 28) / 2),
      moreOrLessEquals((1028 - 28) / 2),
    ]);
    expect(await _widths(tester, [6, 6]), halves);
    final thirds = await _widths(tester, [2, 1]);
    expect(thirds[0] + thirds[1] + 28, moreOrLessEquals(1028));
    expect(thirds[0], moreOrLessEquals((1028 + 28) * 2 / 3 - 28));
  });

  testWidgets('Tab walks a section to its end before the one beside it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget key(String name, double above) => Padding(
      padding: EdgeInsets.only(top: above),
      child: NeumorphicButton(name, onPressed: () {}),
    );
    // The aside's keys stand level with the list's, staggered, so a reading order across the row would interleave
    // them: a, x, b, y, c.
    await tester.pumpWidget(
      neumorphicApp(
        SizedBox(
          width: 1028,
          child: NeumorphicRow(
            spans: const [7, 5],
            children: [
              Column(children: [key('a', 0), key('b', 40), key('c', 40)]),
              Column(children: [key('x', 50), key('y', 40)]),
            ],
          ),
        ),
        width: 1440,
      ),
    );
    final walked = <String>[];
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      walked.add(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<NeumorphicButton>()!
            .label,
      );
    }
    expect(walked, ['a', 'b', 'c', 'x', 'y']);
  });
}
