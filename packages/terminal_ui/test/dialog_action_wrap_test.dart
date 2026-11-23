// A dialog's stacked actions keep their words whole at twice the text on a
// phone: a label longer than its key wraps onto another line, as a Material
// button's does, and is never cut with an ellipsis.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'faces.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => MaterialApp(
  // Round the navigator, so a dialog's route has the scale and the theme too.
  builder: (context, app) => Directionality(
    textDirection: direction,
    child: MediaQuery.withClampedTextScaling(
      minScaleFactor: scale,
      maxScaleFactor: scale,
      child: TermTheme(data: TermThemeData.light(), child: app!),
    ),
  ),
  home: child,
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
      'a dialog at 390, 2x, ${direction.name}: "save changes" is laid out whole',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            Builder(
              builder: (context) => Center(
                child: TermButton(
                  label: 'open',
                  onPressed: () => showTermDialog<void>(
                    context: context,
                    builder: (context) => TermDialog(
                      title: 'unsaved changes',
                      content: const Text(
                        'the form has edits that are not saved.',
                      ),
                      actions: [
                        TermButton(label: 'cancel', onPressed: () {}),
                        TermButton(label: 'discard', onPressed: () {}),
                        TermButton.filled(
                          label: 'save changes',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            direction: direction,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final words = _paragraph(tester, (t) => t.startsWith('save'));
        expect(_plain(words), 'save changes');
        expect(words.didExceedMaxLines, isFalse);
        // Whole: on one line that holds them, or wrapped onto more.
        final lines = words
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 12),
            )
            .map((b) => b.top.round())
            .toSet()
            .length;
        final fits =
            words.getMaxIntrinsicWidth(double.infinity) <=
            words.size.width + 0.5;
        expect(fits || lines > 1, isTrue, reason: 'the words are cut short');
        final report = const DesignClipCheck(look: 'terminal')
            .check(tester.element(find.byType(TermDialog)));
        expect(report.problems, isEmpty);
        final key = tester.getRect(
          find.byWidgetPredicate(
            (w) => w is TermButton && w.label == 'save changes',
          ),
        );
        expect(_drawn(words, 0, 12).left, greaterThanOrEqualTo(key.left));
        expect(_drawn(words, 0, 12).right, lessThanOrEqualTo(key.right));
      },
    );
  }
}
