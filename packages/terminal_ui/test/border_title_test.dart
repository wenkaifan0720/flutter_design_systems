// A pane's title longer than its top line ends in an ellipsis, never cut
// mid-letter at the frame, and is read whole: in the look's face at twice the
// text, and with signs the face lacks (emoji), set in a wider fallback.
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

void main() {
  setUpAll(loadFaces);

  for (final (name, title) in const [
    ('a long title in the face', 'deployment history for atlas-api'),
    ('a title with signs the face lacks', 'deploys 🚀 ready ✅ for review 🔥'),
  ]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        '$name in 318 px at 2x, ${direction.name}: an ellipsis, read whole',
        (tester) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            _host(
              Center(
                child: SizedBox(
                  width: 318,
                  child: TermPane(title: title, child: const Text('ok')),
                ),
              ),
              direction: direction,
              scale: 2,
            ),
          );
          await tester.pumpAndSettle();
          final drawn = _paragraph(
            tester,
            (t) => t.contains(title.substring(0, 2)),
          );
          expect(
            _plain(drawn).contains('…') ||
                (drawn.overflow == TextOverflow.ellipsis &&
                    drawn.didExceedMaxLines),
            isTrue,
            reason: 'the title is cut with an ellipsis',
          );
          final report = const DesignClipCheck(look: 'terminal')
              .check(tester.element(find.byType(TermPane)));
          expect(report.problems, isEmpty);
          expect(
            find.bySemanticsLabel(RegExp(RegExp.escape(title))),
            findsOneWidget,
          );
          semantics.dispose();
        },
      );
    }
  }
}
