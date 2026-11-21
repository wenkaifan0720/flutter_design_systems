// A dialog's keys stand side by side at the end while they fit. When they don't (long labels on a 390-wide phone, or
// the words at twice the size), they stack, each as wide as the slab, the main key (the last) on top, in both reading
// directions: never a staircase of keys at their own widths.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _message = 'It goes back on the shelf, and the order keeps the rest.';

Future<void> _show(
  WidgetTester tester,
  List<String> labels, {
  double width = 390,
  double text = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, (width == 390 ? 844 : 900) * 2);
  addTearDown(tester.view.reset);
  // A fresh app each time: the last one's dialog closes with it.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    neumorphicApp(
      Builder(
        builder: (context) => Center(
          child: NeumorphicButton(
            'Open',
            onPressed: () => showNeumorphicDialog<void>(
              context,
              builder: (context) => NeumorphicDialog(
                title: 'Remove this item?',
                message: _message,
                actions: [
                  for (final (i, label) in labels.indexed)
                    i == labels.length - 1
                        ? NeumorphicButton.filled(label, onPressed: () {})
                        : NeumorphicButton(label, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
      width: width,
      textScale: text,
      direction: direction,
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Rect _key(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(NeumorphicButton)),
);

void _expectRow(
  WidgetTester tester,
  List<String> labels,
  TextDirection direction,
) {
  final keys = [for (final l in labels) _key(tester, l)];
  final words = tester.getRect(find.text(_message));
  final rtl = direction == TextDirection.rtl;
  for (final (i, k) in keys.indexed.skip(1)) {
    final before = keys[i - 1];
    expect(
      k.center.dy,
      moreOrLessEquals(before.center.dy),
      reason: '${labels[i]}: one row',
    );
    expect(
      rtl ? before.left - k.right : k.left - before.right,
      moreOrLessEquals(12),
      reason: '${labels[i]}: in reading order, 12 apart',
    );
  }
  expect(
    rtl ? keys.last.left : keys.last.right,
    moreOrLessEquals(rtl ? words.left : words.right),
    reason: 'the row at the end, the main key last',
  );
}

void _expectStacked(WidgetTester tester, List<String> labels) {
  final keys = [for (final l in labels) _key(tester, l)];
  // The words run the slab's width inside its margins; so does each key.
  final words = tester.getRect(find.text(_message));
  for (final (i, k) in keys.indexed) {
    expect(k.left, moreOrLessEquals(words.left), reason: '${labels[i]}: left');
    expect(
      k.right,
      moreOrLessEquals(words.right),
      reason: '${labels[i]}: right',
    );
    if (i > 0) {
      // The main key (the last) on top, then back up the list, 8 apart.
      expect(
        keys[i - 1].top - k.bottom,
        moreOrLessEquals(8),
        reason: '${labels[i - 1]} under ${labels[i]}',
      );
    }
  }
}

void main() {
  setUpAll(loadNeumorphicFonts);

  const long = ['Keep it on the shelf for now', 'Remove it from the order'];
  const three = ['Not now', 'Keep it', 'Remove from order'];
  const short = ['Keep', 'Remove'];
  const two = ['Keep editing', 'Save changes'];

  for (final direction in TextDirection.values) {
    testWidgets('keys that fit stand side by side, ${direction.name}', (
      tester,
    ) async {
      await _show(tester, short, direction: direction);
      _expectRow(tester, short, direction);
      // Three keys that stack on a phone stand in a row in a desk's dialog.
      await _show(tester, three, width: 1440, direction: direction);
      _expectRow(tester, three, direction);
    });

    testWidgets('long keys at 390 stack full width, the main one on top, '
        '${direction.name}', (tester) async {
      await _show(tester, long, direction: direction);
      _expectStacked(tester, long);
      await _show(tester, three, direction: direction);
      _expectStacked(tester, three);
    });

    testWidgets('keys that fit at 1x stack full width at 2x text, '
        '${direction.name}', (tester) async {
      await _show(tester, two, direction: direction);
      _expectRow(tester, two, direction);
      await _show(tester, two, text: 2, direction: direction);
      _expectStacked(tester, two);
    });
  }
}
