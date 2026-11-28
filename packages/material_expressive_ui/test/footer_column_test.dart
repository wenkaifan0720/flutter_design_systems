// A page's keys on a desk: from 600 wide an ExpressiveScaffold's footer
// stands at the start of the page's column, as wide as its keys, under the
// start of what the page holds. At 1440 a "Save book" key had run from the
// window's start margin to its end margin (16 to 1424), far past the 640
// column of the form it saves, `expand` or not. A phone's footer still takes
// the page's width.
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _page(
  WidgetTester tester, {
  required double width,
  required bool expand,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: ExpressiveHost(child: child!),
      ),
      home: ExpressiveScaffold(
        title: 'Add a book',
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [ExpressiveTextField(labelText: 'Title')],
            ),
          ),
        ),
        footer: ExpressiveFilledButton(
          'Save book',
          expand: expand,
          onPressed: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final direction in TextDirection.values) {
    for (final expand in [false, true]) {
      testWidgets('at 1440 the footer key stands at the column start, as wide '
          'as its words (${direction.name}, expand: $expand)', (tester) async {
        await _page(tester, width: 1440, expand: expand, direction: direction);
        final field = tester.getRect(find.byType(ExpressiveTextField));
        final key = tester.getRect(find.byType(ExpressiveFilledButton));
        if (direction == TextDirection.ltr) {
          expect(key.left, field.left, reason: 'key $key, field $field');
        } else {
          expect(key.right, field.right, reason: 'key $key, field $field');
        }
        expect(key.width, lessThan(field.width / 2), reason: 'key $key');
      });
    }
  }

  testWidgets("a phone's footer key takes the page's width", (tester) async {
    await _page(tester, width: 390, expand: true);
    final key = tester.getRect(find.byType(ExpressiveFilledButton));
    expect(key.left, 16);
    expect(key.right, 390 - 16);
  });
}
