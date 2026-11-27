// A page's measure on a wide window: the bar's title and actions, the body
// and the footer's action stand on one column, centred, its edges shared, in
// both directions. A form page that takes a 600 measure keeps its Save under its fields.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Future<void> _page(
  WidgetTester tester,
  TextDirection direction, {
  double? maxWidth,
}) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final bar = StudioAppBar(
    title: 'New episode',
    automaticallyImplyLeading: false,
    actions: [
      StudioIconButton(
        icon: const Icon(LucideIcons.ellipsis),
        tooltip: 'More',
        onPressed: () {},
      ),
    ],
  );
  const body = SizedBox(
    key: ValueKey('body'),
    height: 200,
    width: double.infinity,
  );
  final footer = StudioButton.lit('Save', onPressed: () {});
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: StudioHost(brightness: Brightness.light, child: app!),
      ),
      home: maxWidth == null
          ? StudioScreen(topBar: bar, body: body, footer: footer)
          : StudioScreen(
              topBar: bar,
              body: body,
              footer: footer,
              maxWidth: maxWidth,
            ),
    ),
  );
  await tester.pumpAndSettle();
}

void _onOneColumn(WidgetTester tester, TextDirection direction) {
  final body = tester.getRect(find.byKey(const ValueKey('body')));
  final title = tester.getRect(find.text('New episode'));
  final more = tester.getRect(find.byType(StudioIconButton));
  final save = tester.getRect(find.byType(StudioButton));
  final ltr = direction == TextDirection.ltr;
  expect(
    ltr ? title.left : title.right,
    moreOrLessEquals(ltr ? body.left : body.right, epsilon: 1),
    reason: 'the title at the body\'s start',
  );
  expect(
    ltr ? more.right : more.left,
    moreOrLessEquals(ltr ? body.right : body.left, epsilon: 1),
    reason: 'the actions at the body\'s end',
  );
  expect(
    ltr ? save.right : save.left,
    moreOrLessEquals(ltr ? body.right : body.left, epsilon: 1),
    reason: 'Save at the body\'s end',
  );
}

void main() {
  setUpAll(studioLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      'the bar, the body and the footer share one measure at 1440 (${direction.name})',
      (tester) async {
        await _page(tester, direction);
        _onOneColumn(tester, direction);
      },
    );

    testWidgets(
      'a 600 measure keeps Save under the fields (${direction.name})',
      (tester) async {
        await _page(tester, direction, maxWidth: 600);
        final body = tester.getRect(find.byKey(const ValueKey('body')));
        expect(body.width, 600);
        expect(
          body.center.dx,
          moreOrLessEquals(
            tester.getRect(find.byType(StudioScreen)).center.dx,
            epsilon: 1,
          ),
        );
        _onOneColumn(tester, direction);
      },
    );
  }
}
