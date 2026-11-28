// On a tablet and a desk, a screen's footer keys stand at the start of the
// page's column, under the start of what the page holds: a form 640 wide
// from the start edge, as the README lays one out, has its key under it. The
// keys had stood at the column's far end, about 700 px from the form at
// 1440. A phone's footer keeps its width.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Finder _face(Finder of) =>
    find.descendant(of: of, matching: find.byType(ClaySurface)).first;

void main() {
  for (final width in [768.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('the footer key stands under the form at ${width.round()} '
          '(${direction.name})', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) => ClayTheme(
              data: ClayThemeData.clay(Brightness.light),
              child: app!,
            ),
            home: Directionality(
              textDirection: direction,
              child: ClayScreen(
                topBar: const ClayTopBar(title: 'Add a book'),
                footer: ClayButton.filled('Save book', onPressed: () {}),
                body: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ClayMetrics.readingWidth,
                    ),
                    child: const ClayTextField(labelText: 'Title'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final form = tester.getRect(_face(find.byType(ClayTextField)));
        final key = tester.getRect(_face(find.byType(ClayButton)));
        final rtl = direction == TextDirection.rtl;
        expect(
          rtl ? key.right : key.left,
          moreOrLessEquals(rtl ? form.right : form.left, epsilon: 0.5),
          reason: 'the key ($key) is not under the form ($form)',
        );
        expect(key.width, lessThan(form.width));
      });
    }
  }
}
