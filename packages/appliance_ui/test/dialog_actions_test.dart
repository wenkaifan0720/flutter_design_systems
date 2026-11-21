// A dialog's keys stand side by side while they fit. When they do not (long
// labels on a 390-wide phone, or the words at twice the size), they stack,
// each as wide as the dialog, the main key (the last) on top, in both
// reading directions: never a staircase of different widths.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester, {
  required String keep,
  required String main,
  double text = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: ApplianceHost(brightness: Brightness.light, child: app!),
      ),
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ApplianceDialog(
                title: 'Remove this item?',
                content: const Text('It goes back on the shelf.'),
                actions: [
                  ApplianceButton(keep, onPressed: () {}),
                  ApplianceButton.filled(main, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _key(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(ApplianceButton)),
);

void _expectStacked(WidgetTester tester, String keep, String main) {
  final k = _key(tester, keep);
  final m = _key(tester, main);
  // The words run the dialog's width inside its margins; so does each key.
  final words = tester.getRect(find.text('It goes back on the shelf.'));
  for (final (name, key) in [('keep', k), ('main', m)]) {
    expect(key.left, moreOrLessEquals(words.left), reason: '$name: left');
    expect(key.right, moreOrLessEquals(words.right), reason: '$name: right');
  }
  // The main key on top.
  expect(m.bottom, lessThanOrEqualTo(k.top), reason: 'the main key on top');
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('short keys stand side by side, ${direction.name}', (
      tester,
    ) async {
      await _show(tester, keep: 'Keep', main: 'Remove', direction: direction);
      final k = _key(tester, 'Keep');
      final m = _key(tester, 'Remove');
      expect(m.center.dy, moreOrLessEquals(k.center.dy), reason: 'one row');
      expect(
        direction == TextDirection.ltr ? k.right <= m.left : m.right <= k.left,
        isTrue,
        reason: 'the main key last in reading order',
      );
    });

    testWidgets('long keys at 390 stack full width, the main one on top, '
        '${direction.name}', (tester) async {
      const keep = 'Keep it on the shelf for now';
      const main = 'Remove it from the order';
      await _show(tester, keep: keep, main: main, direction: direction);
      _expectStacked(tester, keep, main);
    });

    testWidgets('keys that fit at 1x stack full width at 2x text, '
        '${direction.name}', (tester) async {
      const keep = 'Keep';
      const main = 'Remove';
      await _show(tester, keep: keep, main: main, direction: direction);
      expect(
        _key(tester, main).center.dy,
        moreOrLessEquals(_key(tester, keep).center.dy),
        reason: 'side by side at 1x',
      );
      await _show(
        tester,
        keep: keep,
        main: main,
        text: 2,
        direction: direction,
      );
      _expectStacked(tester, keep, main);
    });
  }
}
