// An avatar group's count of the rest reads `+3` in a right-to-left app
// too: the count is isolated, so the line's direction doesn't move its sign.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: MediaQuery.withClampedTextScaling(
      minScaleFactor: scale,
      maxScaleFactor: scale,
      child: TermTheme(data: TermThemeData.light(), child: child),
    ),
  ),
);

String _plain(RenderParagraph p) =>
    p.text.toPlainText(includeSemanticsLabels: false);

RenderParagraph _paragraph(WidgetTester tester, bool Function(String) test) =>
    tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => test(_plain(p)));

// Where [p]'s glyphs from [start] to [end] are drawn, in global coordinates.
Rect _drawn(RenderParagraph p, int start, int end) {
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  final local = boxes
      .map((b) => b.toRect())
      .reduce((a, b) => a.expandToInclude(b));
  return local.shift(p.localToGlobal(Offset.zero));
}

void main() {
  setUpAll(loadFaces);

  for (final direction in TextDirection.values) {
    testWidgets(
      'an avatar group, ${direction.name}: the sign before the count',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const Center(
              child: TermAvatarGroup(
                names: [
                  'Ada Ortiz',
                  'Bo Imai',
                  'Cy Wren',
                  'Di Kerr',
                  'Ed Fox',
                  'Flo Ng',
                ],
                max: 3,
              ),
            ),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        final count = _paragraph(tester, (t) => t.contains('+'));
        final text = _plain(count);
        final sign = text.indexOf('+');
        final digit = text.indexOf('3');
        expect(
          _drawn(count, sign, sign + 1).left,
          lessThan(_drawn(count, digit, digit + 1).left),
        );
      },
    );
  }
}
