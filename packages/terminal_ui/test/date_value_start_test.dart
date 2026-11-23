// A date field's value stands at the field's start, as every field's value
// does: on the left left to right, on the right right to left.
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
    testWidgets('a date field, ${direction.name}: its value at the start', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          Center(
            child: SizedBox(
              width: 336,
              child: TermDatePicker(
                labelText: 'freeze from',
                value: DateTime(2026, 11, 20),
                onChanged: (_) {},
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 12, 31),
              ),
            ),
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final value = _paragraph(tester, (t) => t.contains('2026'));
      final glyphs = _drawn(value, 0, _plain(value).length);
      final field = tester.getRect(find.byType(TermDatePicker));
      final fromLeft = glyphs.left - field.left;
      final fromRight = field.right - glyphs.right;
      if (direction == TextDirection.ltr) {
        expect(fromLeft, lessThan(fromRight));
      } else {
        expect(fromRight, lessThan(fromLeft));
      }
    });
  }
}
