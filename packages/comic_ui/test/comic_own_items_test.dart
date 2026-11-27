// Comic's own: a calendar's days outside its range are printed in the second ink; a description list's term and its
// detail, side by side, stand on one baseline.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
      width: width,
      dark: dark,
    ),
  );
  await tester.pump();
}

Color? _ink(WidgetTester tester, Finder within, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: within, matching: find.text(text)).first,
  );
  return paragraph.text.style?.color;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'days past the last date are printed in the second ink / dark: $dark',
      (tester) async {
        await _pump(
          tester,
          ComicDatePicker(
            value: DateTime(2026, 3, 10),
            firstDate: DateTime(2026, 3, 5),
            lastDate: DateTime(2026, 3, 20),
            currentDate: DateTime(2026, 3, 1),
            onChanged: (_) {},
          ),
          dark: dark,
        );
        final calendar = find.byType(ComicDatePicker);
        final c = ComicTheme.of(tester.element(calendar)).colors;
        expect(_ink(tester, calendar, '12'), c.text);
        expect(_ink(tester, calendar, '25'), c.textSecondary);
        expect(_ink(tester, calendar, '3'), c.textSecondary);
      },
    );
  }

  testWidgets('a term and its detail side by side share a baseline', (
    tester,
  ) async {
    await _pump(
      tester,
      const ComicDescriptionList(
        entries: [
          ComicDescriptionItem('Writer', 'Susanna Clarke'),
          ComicDescriptionItem('Pages', '272'),
        ],
      ),
      width: 1440,
    );
    double baseline(String text) {
      final finder = find.text(text);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      final painter = TextPainter(
        text: paragraph.text,
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      addTearDown(painter.dispose);
      return tester.getTopLeft(finder).dy +
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    }

    expect(
      baseline('WRITER'),
      moreOrLessEquals(baseline('Susanna Clarke'), epsilon: .5),
    );
    expect(baseline('PAGES'), moreOrLessEquals(baseline('272'), epsilon: .5));
  });
}
