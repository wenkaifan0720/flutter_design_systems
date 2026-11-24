// A toast stands above a page's foot (KeycapScreen's footer, under its
// hairline), as a Scaffold keeps a snackbar above its persistent footer
// buttons: on a phone "Changes saved" stood over the page's Save.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

// How far the toast's cast shadow stands below it: a panel's ambient shadow,
// cast 8 down.
const _shadow = 8.0;

Widget _app({required TextDirection direction, required Widget home}) =>
    MaterialApp(
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: KeycapHost(
          brightness: Brightness.light,
          child: KeycapToaster(child: navigator!),
        ),
      ),
      home: home,
    );

Widget _page({Key? key}) => KeycapScreen(
  key: key,
  topBar: const KeycapAppBar(title: 'Task details'),
  footer: KeycapButton.accent(
    onPressed: () {},
    child: const Text('Save changes'),
  ),
  body: const Text('Proof the studio map'),
);

/// The top of the foot's hairline: the lowest band ruled along its top.
double _foot(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .where((w) {
      final d = w.decoration;
      return d is BoxDecoration &&
          d.border is Border &&
          (d.border! as Border).top.width > 0 &&
          (d.border! as Border).bottom == BorderSide.none;
    })
    .map((w) => tester.getRect(find.byWidget(w)).top)
    .reduce((a, b) => a > b ? a : b);

Rect _toast(WidgetTester tester) => tester.getRect(
  find
      .ancestor(
        of: find.text('Changes saved'),
        matching: find.byType(KeycapPanel),
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
        final handle = showKeycapToast(
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
    final handle = showKeycapToast(
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
    final again = showKeycapToast(
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
