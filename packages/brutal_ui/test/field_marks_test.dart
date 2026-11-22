// A select and a combobox read as one kind of field: both end in the same
// mark at the same place, and a list's keyboard row is marked in the row's
// own ink, not in the signal that marks the screen's main action. The mark
// is a rule round the row inside its edges: a bar along its foot alone reads,
// at a list's last row, as the panel's own rule doubled.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _mark(Finder field) => find.descendant(
  of: field,
  matching: find.byWidgetPredicate(
    (w) => w is CustomPaint && w.size == const Size(12, 8),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: BrutalThemeData.light(),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: 320, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The keyboard row among [labels] (the one whose row carries a mark), and
// the rects its mark paints, in the row's frame.
(Size, List<(Rect, Color)>) _keyboardMark(
  WidgetTester tester,
  List<String> labels,
) {
  for (final label in labels) {
    final paints = tester
        .renderObjectList<RenderCustomPaint>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(CustomPaint),
          ),
        )
        // The row's own paint, not the app's (a row is a line high).
        .where((r) => r.foregroundPainter != null && r.size.height < 100);
    if (paints.isEmpty) continue;
    final row = paints.first;
    final canvas = TestRecordingCanvas();
    row.foregroundPainter!.paint(canvas, row.size);
    return (
      row.size,
      [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawRect)
            (
              call.invocation.positionalArguments[0] as Rect,
              (call.invocation.positionalArguments[1] as Paint).color,
            ),
      ],
    );
  }
  fail('no keyboard row among $labels');
}

// Whether [mark] rules [size]'s row on all four sides, in [ink].
void _expectBoxed(Size size, List<(Rect, Color)> mark, Color ink) {
  expect(mark, isNotEmpty);
  expect(mark.map((m) => m.$2), everyElement(ink));
  bool across(Rect r) => r.width > size.width / 2;
  bool along(Rect r) => r.height > size.height / 2;
  expect(
    mark.any((m) => across(m.$1) && m.$1.top < size.height / 4),
    isTrue,
    reason: 'no rule along the row\'s top',
  );
  expect(
    mark.any((m) => across(m.$1) && m.$1.bottom > size.height * 3 / 4),
    isTrue,
    reason: 'no rule along the row\'s foot',
  );
  expect(
    mark.any((m) => along(m.$1) && m.$1.left < size.width / 4),
    isTrue,
    reason: 'no rule up the row\'s left side',
  );
  expect(
    mark.any((m) => along(m.$1) && m.$1.right > size.width * 3 / 4),
    isTrue,
    reason: 'no rule up the row\'s right side',
  );
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'a combobox ends in the select\'s mark, as far in (${direction.name})',
      (tester) async {
        await _pump(
          tester,
          Column(
            children: [
              BrutalSelect<String>(
                key: const Key('select'),
                label: 'Stage',
                items: const [
                  BrutalSelectItem(value: 'a', label: 'Main hall'),
                  BrutalSelectItem(value: 'b', label: 'Courtyard'),
                ],
                value: 'a',
                onChanged: (_) {},
              ),
              BrutalCombobox<String>(
                key: const Key('combobox'),
                label: 'Venue',
                options: const ['Gallery Nine', 'Library Hall'],
                labelOf: (v) => v,
              ),
            ],
          ),
          direction: direction,
        );
        final select = find.byKey(const Key('select'));
        final combobox = find.byKey(const Key('combobox'));
        expect(_mark(select), findsOneWidget);
        expect(_mark(combobox), findsOneWidget);
        double inset(Finder field, Finder mark) {
          final box = tester.getRect(
            find
                .descendant(of: field, matching: find.byType(BrutalSurface))
                .first,
          );
          final at = tester.getCenter(mark).dx;
          return direction == TextDirection.ltr
              ? box.right - at
              : at - box.left;
        }

        expect(
          inset(combobox, _mark(combobox)),
          closeTo(inset(select, _mark(select)), 0.5),
        );
      },
    );
  }

  testWidgets("a combobox's keyboard row is boxed in ink", (tester) async {
    await _pump(
      tester,
      BrutalCombobox<String>(
        label: 'Venue',
        options: const ['Gallery Nine', 'Library Hall', 'Kino 2'],
        labelOf: (v) => v,
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'l');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final (size, mark) = _keyboardMark(tester, [
      'Gallery Nine',
      'Library Hall',
    ]);
    _expectBoxed(size, mark, BrutalThemeData.light().colors.ink);
  });

  testWidgets("a select's keyboard row is boxed in ink", (tester) async {
    await _pump(
      tester,
      BrutalSelect<String>(
        label: 'Stage',
        items: const [
          BrutalSelectItem(value: 'a', label: 'Main hall'),
          BrutalSelectItem(value: 'b', label: 'Courtyard'),
          BrutalSelectItem(value: 'c', label: 'Rooftop'),
        ],
        value: 'a',
        onChanged: (_) {},
      ),
    );
    await tester.tap(find.byType(BrutalSelect<String>));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final (size, mark) = _keyboardMark(tester, [
      'Main hall',
      'Courtyard',
      'Rooftop',
    ]);
    _expectBoxed(size, mark, BrutalThemeData.light().colors.ink);
  });

  testWidgets("a chosen list row turns its trailing control's ink over", (
    tester,
  ) async {
    await _pump(
      tester,
      BrutalListTile(
        title: 'Done',
        selected: true,
        onTap: () {},
        trailing: BrutalIconButton.plain(
          onPressed: () {},
          tooltip: 'More',
          icon: const Icon(IconData(0x2026)),
        ),
      ),
    );
    final colors = BrutalThemeData.light().colors;
    final glyph = IconTheme.of(
      tester.element(find.byIcon(const IconData(0x2026))),
    );
    expect(glyph.color, colors.paper);
  });
}
