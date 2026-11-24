// A desk's sidebar under twice the text keeps its words on a line: its key
// ("New habit"), its places and its foot ("Mara Ilunga"), growing with the
// text as Material's extended rail grows to its labels, up to the width of
// Material's navigation drawer. At the usual text size it keeps its width.
// ignore_for_file: avoid_relative_lib_imports
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/steady/steady.dart';

Future<void> _open(
  WidgetTester tester,
  TextDirection direction, {
  double? textScale,
  Size size = const Size(1440, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SteadyApp(
      initialPlace: SteadyPlace.today,
      initialDirection: direction,
      textScale: textScale,
      parts: [for (final p in galleryPages) (title: p.title, build: p.build)],
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

/// How many lines [text] in the sidebar takes.
int _lines(WidgetTester tester, String text) {
  final finder = find.descendant(
    of: find.byType(ClaySidebar),
    matching: find.text(text),
  );
  final paragraph = tester.renderObject<RenderParagraph>(finder.first);
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      .map((b) => b.top.round())
      .toSet()
      .length;
}

void main() {
  setUpAll(clayLoadFonts);

  for (final size in const [Size(1440, 900), Size(1024, 768)]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${size.width.round()}, twice the text, '
          '${direction.name}: the sidebar keeps each of its words on a line', (
        tester,
      ) async {
        await _open(tester, direction, textScale: 2, size: size);
        for (final words in const [
          'New habit',
          'Clay',
          'Today',
          'Habits',
          'Settings',
          'Mara Ilunga',
          '6 habits',
        ]) {
          expect(_lines(tester, words), 1, reason: words);
        }
        final sidebar = tester.getRect(find.byType(ClaySidebar));
        expect(sidebar.width, lessThanOrEqualTo(360));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('at the usual text size the sidebar keeps its width', (
    tester,
  ) async {
    await _open(tester, TextDirection.ltr, textScale: 1);
    expect(tester.getSize(find.byType(ClaySidebar)).width, ClaySidebar.width);
  });
}
