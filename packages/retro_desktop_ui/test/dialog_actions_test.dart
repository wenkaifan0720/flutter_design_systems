// An alert's buttons stand in one row at the trailing end while they fit. When they don't (long words on a 390-wide
// phone, or the words at twice the size), they stand in one column at the trailing end, each as wide as the widest,
// the default one (the last) on top, in both reading directions: never two in a row and one below, never a staircase
// of different widths.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _message = 'If you close without saving, your changes are lost.';

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
  // A fresh app each time: the last one's window closes with it.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    retroDesktopApp(
      Builder(
        builder: (context) => Center(
          child: RetroDesktopButton(
            'Open',
            onPressed: () => showRetroDesktopDialog<void>(
              context,
              builder: (context) => RetroDesktopDialog(
                title: 'Save the changes to your details?',
                message: _message,
                tone: RetroDesktopTone.warning,
                actions: [
                  for (final (i, label) in labels.indexed)
                    RetroDesktopDialogAction<void>(
                      label,
                      isDefaultAction: i == labels.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      width: width,
      scale: text,
      direction: direction,
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Rect _button(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(
    of: find.text(label),
    matching: find.byType(RetroDesktopButton),
  ),
);

void _expectRow(
  WidgetTester tester,
  List<String> labels,
  TextDirection direction,
) {
  final buttons = [for (final l in labels) _button(tester, l)];
  final words = tester.getRect(find.text(_message));
  final rtl = direction == TextDirection.rtl;
  for (final (i, b) in buttons.indexed.skip(1)) {
    final before = buttons[i - 1];
    expect(
      b.top,
      moreOrLessEquals(before.top),
      reason: '${labels[i]}: one row',
    );
    expect(
      rtl ? before.left - b.right : b.left - before.right,
      moreOrLessEquals(8),
      reason: '${labels[i]}: in reading order, 8 apart',
    );
  }
  // At the trailing end, the default one last.
  expect(
    rtl ? buttons.last.left : buttons.last.right,
    moreOrLessEquals(rtl ? words.left : words.right),
    reason: 'the row at the trailing end',
  );
}

void _expectColumn(
  WidgetTester tester,
  List<String> labels,
  TextDirection direction,
) {
  final buttons = [for (final l in labels) _button(tester, l)];
  final words = tester.getRect(find.text(_message));
  final rtl = direction == TextDirection.rtl;
  for (final (i, b) in buttons.indexed) {
    expect(
      b.width,
      moreOrLessEquals(buttons.first.width),
      reason: '${labels[i]}: as wide as the others',
    );
    expect(
      rtl ? b.left : b.right,
      moreOrLessEquals(rtl ? words.left : words.right),
      reason: '${labels[i]}: on the trailing edge',
    );
    if (i > 0) {
      // The default one (the last) on top, then back up the list: each in a row of its own.
      expect(
        buttons[i - 1].top - b.bottom,
        moreOrLessEquals(8),
        reason: '${labels[i - 1]} under ${labels[i]}, 8 apart',
      );
    }
  }
  // As wide as the widest: one of them fills the column on its words alone.
  expect(
    buttons.first.width,
    greaterThan(
      labels
          .map((l) => tester.getSize(find.text(l)).width)
          .reduce((a, b) => a > b ? a : b),
    ),
  );
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  // The period's three answers: two in a row and the third below them at 390 until now.
  const three = ['Don’t save', 'Cancel', 'Save changes'];
  const two = ['Keep editing', 'Save changes'];

  for (final direction in TextDirection.values) {
    testWidgets('buttons that fit stand in one row, ${direction.name}', (
      tester,
    ) async {
      await _show(tester, ['Cancel', 'Save'], direction: direction);
      _expectRow(tester, ['Cancel', 'Save'], direction);
      // The three that stack on a phone stand in a row in a desk's window.
      await _show(tester, three, width: 1440, direction: direction);
      _expectRow(tester, three, direction);
    });

    testWidgets('three buttons that miss a row at 390 stack, the same width, '
        'the default on top, ${direction.name}', (tester) async {
      await _show(tester, three, direction: direction);
      _expectColumn(tester, three, direction);
    });

    testWidgets('buttons that fit at 1x stack at 2x text, ${direction.name}', (
      tester,
    ) async {
      await _show(tester, two, direction: direction);
      _expectRow(tester, two, direction);
      await _show(tester, two, text: 2, direction: direction);
      _expectColumn(tester, two, direction);
    });
  }
}
