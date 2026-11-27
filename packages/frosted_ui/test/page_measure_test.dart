// A page held to a measure (FrostedScaffold.maxWidth): on a desktop the
// bar's title and actions, the body and the footer's acts keep to one
// column on the start edge, in either direction; without one the page
// spans its box.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

Future<void> _pump(
  WidgetTester t, {
  double? maxWidth,
  TextDirection direction = TextDirection.ltr,
}) async {
  t.view.physicalSize = const Size(1440, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: Directionality(
        textDirection: direction,
        child: FrostedScaffold(
          maxWidth: maxWidth,
          topBar: FrostedAppBar(
            title: 'New book',
            actions: [
              FrostedIconButton(
                FrostedGlyphs.more,
                semanticLabel: 'More',
                onPressed: () {},
              ),
            ],
          ),
          body: const FrostedTextField(labelText: 'Title'),
          // The acts at the footer's end, as a desktop form sets them.
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 12,
            children: [
              FrostedButton.glass('Cancel', onPressed: () {}),
              FrostedButton('Save', onPressed: () {}),
            ],
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'the bar, the body and the footer keep to the measure (${direction.name})',
      (t) async {
        await _pump(t, maxWidth: 720, direction: direction);
        final ltr = direction == TextDirection.ltr;
        final field = t.getRect(find.byType(FrostedTextField));
        final title = t.getRect(find.text('New book'));
        final more = t.getRect(find.byType(FrostedIconButton));
        final save = t.getRect(find.widgetWithText(FrostedButton, 'Save'));
        // The column: from the start edge, 720 wide with its padding.
        if (ltr) {
          expect(field.right, lessThanOrEqualTo(720));
          expect(title.left, moreOrLessEquals(field.left, epsilon: 1));
          expect(more.right, lessThanOrEqualTo(field.right + .5));
          expect(save.right, moreOrLessEquals(field.right, epsilon: 1));
        } else {
          expect(field.left, greaterThanOrEqualTo(1440 - 720));
          expect(title.right, moreOrLessEquals(field.right, epsilon: 1));
          expect(more.left, greaterThanOrEqualTo(field.left - .5));
          expect(save.left, moreOrLessEquals(field.left, epsilon: 1));
        }
      },
    );
  }

  testWidgets('without a measure the page spans its box', (t) async {
    await _pump(t);
    final field = t.getRect(find.byType(FrostedTextField));
    expect(field.right, greaterThan(1200));
  });
}
