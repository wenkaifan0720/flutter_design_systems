// A page row's spans are shares of the row: [1, 1] is halves as [6, 6] is, and a row is always filled. The 12-column
// grid reads the same as before; a row whose spans don't add up to 12 no longer leaves its children a twelfth each.
import 'package:material_ui/material_ui.dart';
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

void main() {
  setUpAll(loadNeumorphicFonts);

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
}
