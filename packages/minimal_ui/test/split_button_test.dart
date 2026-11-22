import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  group('MinimalSplitButton', () {
    final t = MinimalThemeData.preset('standard', Brightness.light);

    Widget split() => MinimalSplitButton(
      'Save',
      onPressed: () {},
      actions: [MinimalMenuItem('Save as…', onPressed: () {})],
    );

    /// The halves' faces wearing the keyboard's ring.
    List<({Color ring, Color? ground})> rings(WidgetTester tester) => [
      for (final c in tester.widgetList<Container>(
        find.descendant(
          of: find.byType(MinimalSplitButton),
          matching: find.byType(Container),
        ),
      ))
        ?_ringOf(c.foregroundDecoration),
    ];

    /// The row of the two halves and the seam, in paint order.
    Row halves(WidgetTester tester) => tester.widget<Row>(
      find.descendant(
        of: find.byType(MinimalSplitButton),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Row &&
              w.children.length == 3 &&
              w.children[1] is KeyedSubtree,
        ),
      ),
    );

    bool holds(WidgetTester tester, Widget child, Finder target) => find
        .descendant(of: find.byWidget(child), matching: target)
        .evaluate()
        .isNotEmpty;

    for (final direction in TextDirection.values) {
      testWidgets('a focused half wears the button\'s ring outside its edge, '
          'painted over its neighbour (${direction.name})', (tester) async {
        await tester.pumpWidget(
          centredHost(Directionality(textDirection: direction, child: split())),
        );
        final save = tester.getRect(find.text('Save'));
        final chevron = tester.getRect(find.byType(MinimalIcon));
        expect(rings(tester), isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final ring = rings(tester).single;
        expect(ring.ring, t.ring);
        // Past a gap of the page it stands on.
        expect(ring.ground, t.background);
        // The main half paints last, over the seam and the chevron, and
        // neither half moved to get there.
        expect(
          holds(tester, halves(tester).children.last, find.text('Save')),
          isTrue,
        );
        expect(tester.getRect(find.text('Save')), save);
        expect(tester.getRect(find.byType(MinimalIcon)), chevron);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(rings(tester), hasLength(1));
        expect(
          holds(tester, halves(tester).children.last, find.byType(MinimalIcon)),
          isTrue,
        );
        expect(tester.getRect(find.text('Save')), save);
        expect(tester.getRect(find.byType(MinimalIcon)), chevron);
      });
    }

    /// How opaque each half paints: its words' and its chevron's opacities
    /// all the way up.
    List<double> dims(WidgetTester tester) => [
      for (final part in [find.text('Save'), find.byType(MinimalIcon)])
        tester
            .widgetList<Opacity>(
              find.ancestor(of: part, matching: find.byType(Opacity)),
            )
            .fold(1.0, (product, o) => product * o.opacity),
    ];

    testWidgets('disabled, both halves take the disabled ink and neither '
        'takes a press; with no main action only the main half does', (
      tester,
    ) async {
      var saved = 0;
      Widget build({bool enabled = true, bool main = true}) => centredHost(
        MinimalSplitButton(
          'Save',
          onPressed: enabled && main ? () => saved++ : null,
          actions: [if (enabled) MinimalMenuItem('Save as…', onPressed: () {})],
        ),
      );

      await tester.pumpWidget(build(enabled: false));
      expect(dims(tester), [0.45, 0.45]);
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.tap(find.byType(MinimalIcon), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(saved, 0);
      expect(find.text('Save as…'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(rings(tester), isEmpty);

      await tester.pumpWidget(build(main: false));
      expect(dims(tester), [0.45, 1]);
      await tester.tap(find.byType(MinimalIcon));
      await tester.pumpAndSettle();
      expect(find.text('Save as…'), findsOneWidget);
    });
  });
}

/// The keyboard ring a part's foreground decoration wears, and the ground
/// in the gap between it and the face; null when it wears none.
({Color ring, Color? ground})? _ringOf(Decoration? decoration) {
  if (decoration == null) return null;
  final properties = {
    for (final p in decoration.toDiagnosticsNode().getProperties())
      p.name: p.value,
  };
  final ring = properties['ring'];
  return ring is Color
      ? (ring: ring, ground: properties['ground'] as Color?)
      : null;
}
