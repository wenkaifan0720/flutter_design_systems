// A plate set in its container keeps one inset all round (coordinator, 11-17:
// read from painted pixels at 390 and 1440, v030/plates). Two failed under a
// finger on ui_core 0.3.0, whose touch target keeps a face its own size:
// - a list's rows were 44 in their 48 target, so the first row's fill stood 6
//   from the popover's top and 4 from its sides;
// - a one-line message bar's act, its face the whole 48 target, stood 1 from
//   the bar's top and foot and 13 from its end.
// Fluent's own corner is kept: a row 4 round in a 4 round surface 4 in, as
// Fluent's MenuPopover and Listbox draw it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2PopoverSurface;

const _options = [
  Fluent2Option('equipment', 'Equipment'),
  Fluent2Option('access', 'Access'),
  Fluent2Option('room', 'Room booking'),
];

Future<void> _stage(WidgetTester t, Widget body, {double width = 1440}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => Fluent2Host(child: navigator!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(alignment: Alignment.topLeft, child: body),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Rect _rect(WidgetTester t, Finder f) => t.getRect(f);

/// The painted fill of the row holding [label] in the open list.
Rect _rowFill(WidgetTester t, String label) {
  final fill = find.ancestor(
    of: find.descendant(
      of: find.byType(Fluent2PopoverSurface),
      matching: find.text(label),
    ),
    matching: find.byWidgetPredicate(
      (w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).borderRadius ==
              BorderRadius.circular(Fluent2Radius.medium),
    ),
  );
  return _rect(t, fill.first);
}

void main() {
  test("a menu row under a finger is the finger's whole target", () {
    expect(Fluent2ChromeMetrics.menuItemTouch, Fluent2Layout.touchHitTarget);
  });

  for (final (value, label, edge) in [
    ('equipment', 'Equipment', 'top'),
    ('room', 'Room booking', 'foot'),
  ]) {
    testWidgets("a list's chosen row under a finger, at its $edge, stands as "
        'far from the edge as from the sides', (t) async {
      await _stage(
        t,
        SizedBox(
          width: 320,
          child: Fluent2Select<String>(
            label: 'Type',
            value: value,
            options: _options,
            onChanged: (_) {},
          ),
        ),
      );
      await t.tap(find.text(label));
      await t.pumpAndSettle();
      final surface = _rect(t, find.byType(Fluent2PopoverSurface));
      final row = _rowFill(t, label);
      final side = row.left - surface.left;
      expect(surface.right - row.right, closeTo(side, .5));
      final end = edge == 'top'
          ? row.top - surface.top
          : surface.bottom - row.bottom;
      expect(end, closeTo(side, .5), reason: 'the row at the list\'s $edge');
      expect(row.height, Fluent2Layout.touchHitTarget);
    });
  }

  Widget bar() => SizedBox(
    width: 900,
    child: Fluent2MessageBar(
      body: 'You are viewing an older version.',
      actions: [
        Fluent2Button(
          'Restore',
          size: Fluent2ButtonSize.small,
          onPressed: () {},
        ),
      ],
    ),
  );

  testWidgets("a one-line message bar's act under a finger stands as far "
      'from its top and foot as from its end', (t) async {
    await _stage(t, bar());
    final b = _rect(t, find.byType(Fluent2MessageBar));
    final act = _rect(t, find.byType(Fluent2Button));
    final end = b.right - act.right;
    expect(act.top - b.top, closeTo(end, 1));
    expect(b.bottom - act.bottom, closeTo(end, 1));
  });

  testWidgets("under a pointer a one-line message bar keeps Fluent's 36 band", (
    t,
  ) async {
    await _stage(t, bar());
    expect(_rect(t, find.byType(Fluent2MessageBar)).height, 36);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
