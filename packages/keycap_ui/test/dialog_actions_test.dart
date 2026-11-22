// A dialog's keys stand side by side while they fit. When they do not (long
// words on a 390-wide phone, or the words at twice the size), they stack,
// each as wide as the panel, the main key (the last) on top, in both
// reading directions: never a staircase of different widths.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

import '../example/lib/kit_gallery/kit.dart';

const _words = 'Its words go with it.';

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
        child: KeycapTheme(data: kitTheme(Brightness.light), child: app!),
      ),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: KeycapDialog(
              title: 'Delete this note?',
              content: const Text(_words),
              actions: [
                KeycapButton(onPressed: () {}, child: Text(keep)),
                KeycapButton.accent(
                  isDestructiveAction: true,
                  onPressed: () {},
                  child: Text(main),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _key(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(KeycapButton)),
);

void _expectStacked(WidgetTester tester, String keep, String main) {
  final k = _key(tester, keep);
  final m = _key(tester, main);
  // The words run the panel's width inside its margins; so does each key.
  final words = tester.getRect(find.text(_words));
  for (final (name, key) in [('keep', k), ('main', m)]) {
    expect(key.left, moreOrLessEquals(words.left), reason: '$name: left');
    expect(key.right, moreOrLessEquals(words.right), reason: '$name: right');
  }
  expect(m.bottom, lessThanOrEqualTo(k.top), reason: 'the main key on top');
}

void main() {
  setUpAll(keycapLoadFonts);

  for (final dir in TextDirection.values) {
    testWidgets('short keys stand side by side, ${dir.name}', (tester) async {
      await _show(tester, keep: 'Keep', main: 'Delete', direction: dir);
      final k = _key(tester, 'Keep');
      final m = _key(tester, 'Delete');
      expect(m.center.dy, moreOrLessEquals(k.center.dy), reason: 'one row');
      expect(
        dir == TextDirection.ltr ? k.right <= m.left : m.right <= k.left,
        isTrue,
        reason: 'the main key last in reading order',
      );
    });

    testWidgets('long keys at 390 stack full width, the main one on top, '
        '${dir.name}', (tester) async {
      const keep = 'Keep the note in its folder';
      const main = 'Delete the note for good';
      await _show(tester, keep: keep, main: main, direction: dir);
      _expectStacked(tester, keep, main);
    });

    testWidgets('keys that fit at 1x stack full width at 2x text, '
        '${dir.name}', (tester) async {
      const keep = 'Keep editing';
      const main = 'Delete note';
      await _show(tester, keep: keep, main: main, direction: dir);
      expect(
        _key(tester, main).center.dy,
        moreOrLessEquals(_key(tester, keep).center.dy),
        reason: 'side by side at 1x',
      );
      await _show(tester, keep: keep, main: main, text: 2, direction: dir);
      _expectStacked(tester, keep, main);
    });
  }
}
