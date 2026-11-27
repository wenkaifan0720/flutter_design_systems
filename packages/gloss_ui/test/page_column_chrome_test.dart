// On a wide screen a page's top bar and its footer keep to the page's
// column: the title starts where the page's words do and the footer's key
// ends where they end, left to right and right to left. On a phone both
// stand on the page's margin as before.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

const _words = Key('words');

Future<void> _show(WidgetTester t, double width, TextDirection dir) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 900);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF0E7652),
      builder: (context, _) => Directionality(
        textDirection: dir,
        child: GlossTheme(
          data: GlossThemeData.preset('jade', Brightness.light),
          child: GlossScreen(
            topBar: const GlossTopBar(title: 'Books'),
            body: const SizedBox(
              key: _words,
              width: double.infinity,
              height: 40,
            ),
            footer: GlossButton('Save', onPressed: () {}),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  for (final dir in TextDirection.values) {
    for (final width in [390.0, 1440.0]) {
      testWidgets(
        'chrome on the page column at ${width.toInt()} (${dir.name})',
        (t) async {
          await _show(t, width, dir);
          final words = t.getRect(find.byKey(_words));
          final title = t.getRect(find.text('Books'));
          final save = t.getRect(find.byType(GlossButton));
          final ltr = dir == TextDirection.ltr;
          if (ltr) {
            expect(title.left, moreOrLessEquals(words.left, epsilon: .5));
          } else {
            expect(title.right, moreOrLessEquals(words.right, epsilon: .5));
          }
          if (width >= 1024) {
            // The key ends where the page's words end.
            expect(
              ltr ? save.right : save.left,
              moreOrLessEquals(ltr ? words.right : words.left, epsilon: .5),
            );
          } else {
            expect(save.left, moreOrLessEquals(words.left, epsilon: .5));
            expect(save.right, moreOrLessEquals(words.right, epsilon: .5));
          }
        },
      );
    }
  }
}
