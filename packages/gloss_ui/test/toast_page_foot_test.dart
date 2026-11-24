// A toast stands above a page's foot (GlossScreen's footer, under its
// hairline), as a Scaffold keeps a snackbar above its persistent footer
// buttons: on a phone "Changes saved" stood over the page's Save.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

// How far the toast's cast shadow stands below it: a raised pearl's ambient
// shadow, cast 2.5 down.
const _shadow = 2.5;

Widget _app({required TextDirection direction, required Widget home}) =>
    MaterialApp(
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: GlossTheme(
          data: GlossThemeData.light(),
          child: GlossToaster(child: navigator!),
        ),
      ),
      home: home,
    );

Widget _page({Key? key}) => GlossScreen(
  key: key,
  topBar: const GlossTopBar(title: 'Task details'),
  footer: GlossButton.filled('Save changes', onPressed: () {}),
  body: const Text('Proof the studio map'),
);

/// The top of the foot's hairline: the lowest GlossDivider on the page.
double _foot(WidgetTester tester) => tester
    .widgetList<GlossDivider>(find.byType(GlossDivider))
    .map((w) => tester.getRect(find.byWidget(w)).top)
    .reduce((a, b) => a > b ? a : b);

Rect _toast(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text('Changes saved'),
        matching: find.byWidgetPredicate(
          (w) => w is ConstrainedBox && w.constraints.minHeight == 52,
        ),
      )
      .first,
);

void main() {
  for (final width in const [390.0, 900.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('at ${width.round()}, ${direction.name}: a toast stands '
          'above the page foot', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final page = GlobalKey();
        await tester.pumpWidget(
          _app(
            direction: direction,
            home: _page(key: page),
          ),
        );
        await tester.pumpAndSettle();
        final rule = _foot(tester);
        final save = tester.getRect(find.text('Save changes'));
        expect(rule, lessThanOrEqualTo(save.top), reason: 'the foot');
        final handle = showGlossToast(
          page.currentContext!,
          'Changes saved',
          duration: null,
        );
        await tester.pumpAndSettle();
        final toast = _toast(tester);
        expect(
          toast.bottom + _shadow,
          lessThanOrEqualTo(rule),
          reason: 'toast $toast, foot from $rule',
        );
        handle.dismiss();
        await tester.pumpAndSettle();
        expect(find.text('Changes saved'), findsNothing);
      });
    }
  }

  testWidgets('a dismissed toast leaves; once the page with a foot is gone, '
      'a toast stands at the foot of the screen again', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final home = GlobalKey();
    final page = GlobalKey();
    await tester.pumpWidget(
      _app(
        direction: TextDirection.ltr,
        home: SizedBox.expand(key: home),
      ),
    );
    unawaited(
      Navigator.of(home.currentContext!).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => _page(key: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rule = _foot(tester);
    final handle = showGlossToast(
      page.currentContext!,
      'Changes saved',
      duration: null,
    );
    await tester.pumpAndSettle();
    expect(_toast(tester).bottom + _shadow, lessThanOrEqualTo(rule));
    handle.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Changes saved'), findsNothing);
    Navigator.of(page.currentContext!).pop();
    await tester.pumpAndSettle();
    final again = showGlossToast(
      home.currentContext!,
      'Changes saved',
      duration: null,
    );
    await tester.pumpAndSettle();
    expect(
      _toast(tester).bottom,
      greaterThan(rule),
      reason: 'the gone foot still holds the toast up',
    );
    again.dismiss();
    await tester.pumpAndSettle();
  });
}
