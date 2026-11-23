// A phone's window list shares its width in equal cells, as Material's
// NavigationBar does: its names stand evenly along the line, whatever their
// lengths, each starting on the character grid (so a name's middle is its
// cell's to half a cell).
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

void main() {
  setUpAll(loadFaces);

  for (final direction in TextDirection.values) {
    testWidgets(
      'a window list at 390, ${direction.name}: names of unlike lengths in '
      'equal cells',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _host(
            Align(
              alignment: Alignment.bottomCenter,
              child: TermNavigationBar(
                destinations: const [
                  TermNavigationDestination(label: 'releases'),
                  TermNavigationDestination(label: 'runs'),
                  TermNavigationDestination(label: 'env'),
                ],
                selectedIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        final cw = tester
            .element(find.byType(TermNavigationBar))
            .termGrid
            .cellWidth;
        final middles = <double>[];
        for (final name in const ['releases', 'runs', 'env']) {
          final p = _paragraph(tester, (t) => t.contains(name));
          final box = p.localToGlobal(Offset.zero) & p.size;
          final start = direction == TextDirection.ltr
              ? box.left
              : 390 - box.right;
          expect(
            (start / cw - (start / cw).round()).abs(),
            lessThan(0.001),
            reason: '$name starts at $start',
          );
          middles.add(box.center.dx);
        }
        middles.sort();
        expect(
          (middles[1] - middles[0]) - (middles[2] - middles[1]),
          inInclusiveRange(-cw - 0.001, cw + 0.001),
          reason: '$middles',
        );
      },
    );
  }
}
