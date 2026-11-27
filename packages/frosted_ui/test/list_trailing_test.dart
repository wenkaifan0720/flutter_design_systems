// A list row's end: the trailing part keeps to two thirds of the line (the
// title keeps a third, a long tag gives way instead of overflowing), on the
// row's end edge in either direction; the hairline between rows runs under
// the trailing column and the row's own control.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) async {
  t.view.physicalSize = Size(width, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: Directionality(
        textDirection: direction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [child],
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

const _long = 'Returned to the library after the second reminder';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'a long trailing tag keeps to two thirds of the line (${direction.name})',
      (t) async {
        await _pump(
          t,
          const FrostedListTile(
            leading: FrostedMonogram('Piranesi'),
            title: 'Piranesi',
            meta: 'Susanna Clarke',
            trailing: FrostedTag(_long),
          ),
          direction: direction,
        );
        final row = t.getRect(find.byType(FrostedListTile));
        final tag = t.getRect(find.byType(FrostedTag));
        final title = t.getRect(find.text('Piranesi'));
        final words = direction == TextDirection.ltr
            ? tag.left - title.left
            : title.right - tag.right;
        final line = direction == TextDirection.ltr
            ? row.right - title.left
            : title.right - row.left;
        // The tag at the row's end edge, the title keeping a third of the line.
        if (direction == TextDirection.ltr) {
          expect(tag.right, moreOrLessEquals(row.right, epsilon: .5));
        } else {
          expect(tag.left, moreOrLessEquals(row.left, epsilon: .5));
        }
        expect(tag.width, lessThanOrEqualTo(line * 2 / 3 + .5));
        expect(words, greaterThanOrEqualTo(line / 3 - .5));
      },
    );
  }

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'the hairline between rows runs under the trailing column and the control (${width.toInt()})',
      (t) async {
        Widget row(String title) => FrostedListTile(
          title: title,
          trailing: const FrostedTag('Due Friday'),
          onPressed: () {},
          action: FrostedIconButton(
            FrostedGlyphs.more,
            semanticLabel: 'More',
            onPressed: () {},
          ),
        );
        await _pump(
          t,
          FrostedRowGroup(
            hairlines: true,
            children: [row('Piranesi'), row('Middlemarch')],
          ),
          width: width,
        );
        final lined = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_Lined',
        );
        expect(lined, findsOneWidget);
        final rule = t.getRect(lined);
        final control = t.getRect(find.byType(FrostedIconButton).last);
        final tag = t.getRect(find.byType(FrostedTag).last);
        expect(rule.right, greaterThanOrEqualTo(control.right - .5));
        expect(rule.right, greaterThanOrEqualTo(tag.right));
      },
    );
  }

  testWidgets("a row end's long note gives way with an ellipsis", (t) async {
    // _pump expects no exception: an overflowing note would throw.
    await _pump(
      t,
      const FrostedListTile(
        leading: FrostedMonogram('Savings'),
        title: 'Savings',
        trailing: FrostedRowEnd(
          amount: FrostedAmount(21500, signed: false),
          note: _long,
          noteTone: FrostedTone.success,
        ),
      ),
    );
    final note = t.widget<Text>(find.text(_long));
    expect(note.overflow, TextOverflow.ellipsis);
    final line = t.getRect(find.byType(FrostedListTile));
    expect(t.getRect(find.text(_long)).width, lessThan(line.width * 2 / 3));
  });
}
