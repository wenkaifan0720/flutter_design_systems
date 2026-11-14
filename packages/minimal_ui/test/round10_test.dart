// Round 10's fixes: the heatmap's middle step by night; a neutral dot in
// the quiet ink; a section of time rows held to a control's measure; a
// selection list's own inset; a disabled search on the sunken fill; a
// compact clearable field that keeps its height; a multi-select one tag in
// as tall as empty; a range field's prompt in the body face; an attachment
// named in the sans; swipe squares ruled toward the row.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _day = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);
final MinimalThemeData _night = MinimalThemeData.preset(
  'standard',
  Brightness.dark,
);

/// [child] on a full-bleed page [width] wide in [theme].
Widget _app(Widget child, {double width = 390, MinimalThemeData? theme}) =>
    MaterialApp(
      builder: (context, navigator) => MinimalHost(
        light: theme ?? _day,
        dark: _night,
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: MinimalScaffold(
        padding: EdgeInsets.zero,
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

/// The view [size] at one device pixel a logical pixel, for this test.
void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Every fill painted under [of]: its containers' and decorated boxes'.
List<Color> _fills(WidgetTester tester, Finder of) {
  Color? fillOf(Decoration? d) => switch (d) {
    BoxDecoration(:final color) => color,
    ShapeDecoration(:final color) => color,
    _ => null,
  };
  return [
    for (final c in tester.widgetList<Container>(
      find.descendant(of: of, matching: find.byType(Container)),
    ))
      fillOf(c.decoration),
    for (final b in tester.widgetList<DecoratedBox>(
      find.descendant(of: of, matching: find.byType(DecoratedBox)),
    ))
      fillOf(b.decoration),
  ].whereType<Color>().toList();
}

void _none() {}

void main() {
  test("the heatmap's middle step is 45% by day and 60% by night", () {
    expect(MinimalHeatmap.levelColor(_day, 1).a, closeTo(0.45, 0.01));
    expect(MinimalHeatmap.levelColor(_night, 1).a, closeTo(0.6, 0.01));
  });

  test('a neutral dot is the quiet ink, as its words are', () {
    for (final t in [_day, _night]) {
      expect(t.tone(MinimalTone.neutral).indicator, t.mutedForeground);
    }
  });

  testWidgets('a section of time rows holds to the control measure on a '
      'laptop', (tester) async {
    _view(tester, const Size(1440, 900));
    await tester.pumpWidget(
      _app(
        MinimalFormSection(
          title: 'Schedule',
          children: [
            MinimalTimePicker(
              label: 'Remind me at',
              value: DateTime(2026, 3, 12, 7),
              onChanged: (_) {},
            ),
          ],
        ),
        width: 1000,
      ),
    );
    expect(
      tester.getSize(find.byType(MinimalTimePicker)).width,
      lessThanOrEqualTo(MinimalLayout.controlMax),
    );
  });

  testWidgets('a selection list insets its rows by its padding', (
    tester,
  ) async {
    Widget list(EdgeInsetsGeometry padding) => MinimalSelectionList<String>(
      value: 'a',
      options: const [
        MinimalSelectOption('a', 'Alpha'),
        MinimalSelectOption('b', 'Beta'),
      ],
      padding: padding,
      onChanged: (_) {},
    );
    await tester.pumpWidget(_app(list(EdgeInsets.zero)));
    final flush = tester.getTopLeft(find.text('Beta')).dx;
    await tester.pumpWidget(
      _app(list(const EdgeInsets.symmetric(horizontal: 16))),
    );
    expect(tester.getTopLeft(find.text('Beta')).dx - flush, 16);
  });

  testWidgets('a disabled search rests on the sunken fill, as a disabled '
      'text field does', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            MinimalSearchField(hint: 'Search archived', enabled: false),
            MinimalSearchEntry(label: 'Search archive'),
          ],
        ),
      ),
    );
    expect(
      _fills(tester, find.byType(MinimalSearchField)),
      contains(_day.sunken),
    );
    expect(
      _fills(tester, find.byType(MinimalSearchEntry)),
      contains(_day.sunken),
    );
  });

  testWidgets('a compact clearable field keeps its height with the clear '
      'glyph in it', (tester) async {
    final compact = _day.copyWith(density: MinimalDensity.compact);
    final name = TextEditingController(text: 'Morning run');
    addTearDown(name.dispose);
    await tester.pumpWidget(
      _app(MinimalTextField(controller: name, clearable: true), theme: compact),
    );
    final cleared = tester.getSize(find.byType(MinimalTextField)).height;
    name.clear();
    await tester.pump();
    expect(tester.getSize(find.byType(MinimalTextField)).height, cleared);
  });

  for (final (name, theme) in [
    ('standard', _day),
    ('compact', _day.copyWith(density: MinimalDensity.compact)),
  ]) {
    testWidgets('a multi-select with a tag is as tall as empty ($name)', (
      tester,
    ) async {
      Widget field(List<String> values) => MinimalMultiSelect<String>(
        values: values,
        options: const ['Bug', 'Design', 'Docs'],
        onChanged: (_) {},
      );
      await tester.pumpWidget(_app(field(const []), theme: theme));
      final empty = tester.getSize(find.byType(MinimalMultiSelect<String>));
      await tester.pumpWidget(_app(field(const ['Bug']), theme: theme));
      expect(
        tester.getSize(find.byType(MinimalMultiSelect<String>)).height,
        empty.height,
      );
    });
  }

  testWidgets("a range field's prompt is words, in the placeholder face", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDateRangePicker(
          label: 'Stay',
          firstDate: DateTime(2026),
          lastDate: DateTime(2027),
          onChanged: (_) {},
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('Choose')).style!;
    expect(style.fontFamily, _day.body.fontFamily);
    expect(style.fontSize, _day.body.fontSize);
  });

  testWidgets("an attachment chip names its file in the sans, as an "
      "upload list does", (tester) async {
    await tester.pumpWidget(
      _app(
        MinimalComposer(
          onSend: (_) {},
          attachment: 'run-2026-08-28.gpx',
          onRemoveAttachment: () {},
        ),
      ),
    );
    final style = tester.widget<Text>(find.text('run-2026-08-28.gpx')).style!;
    expect(style.fontFamily, _day.bodySmall.fontFamily);
    expect(style.fontFamily, isNot(_day.mono.fontFamily));
  });

  for (final dir in TextDirection.values) {
    testWidgets('swipe squares are ruled toward the row, not at its outer '
        'edge (${dir.name})', (tester) async {
      await tester.pumpWidget(
        _app(
          Directionality(
            textDirection: dir,
            child: const MinimalSwipeActions(
              initiallyOpen: true,
              trailing: [
                MinimalSwipeAction('Archive', onPressed: _none),
                MinimalSwipeAction(
                  'Delete',
                  destructive: true,
                  onPressed: _none,
                ),
              ],
              child: MinimalListTile(title: 'Morning run', meta: '12d'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The resolved rule on each side of [label]'s square.
      Border border(String label) {
        final box = find
            .ancestor(
              of: find.text(label),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).border is BorderDirectional,
              ),
            )
            .first;
        final decoration =
            tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
        final d = decoration.border! as BorderDirectional;
        final rtlBox =
            Directionality.of(tester.element(box)) == TextDirection.rtl;
        return Border(
          top: d.top,
          bottom: d.bottom,
          left: rtlBox ? d.end : d.start,
          right: rtlBox ? d.start : d.end,
        );
      }

      final rtl = dir == TextDirection.rtl;
      // The row stands on the start side, so its actions run toward the
      // end: the inner square's start side meets the row, and the outer
      // square's end side is the list's edge.
      BorderSide towardRow(Border b) => rtl ? b.right : b.left;
      BorderSide outward(Border b) => rtl ? b.left : b.right;
      final archive = tester.getCenter(find.text('Archive')).dx;
      final delete = tester.getCenter(find.text('Delete')).dx;
      final outer = (rtl ? archive < delete : archive > delete)
          ? 'Archive'
          : 'Delete';
      for (final label in ['Archive', 'Delete']) {
        expect(towardRow(border(label)).width, greaterThan(0), reason: label);
      }
      expect(outward(border(outer)), BorderSide.none);
    });
  }
}
