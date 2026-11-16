// In every open list Fluent 2 draws (a select's popover and its phone sheet, a combobox's list, a menu with a
// choice), the chosen option stands out at a glance as Fluent's selected list item does: the subtle brand fill
// (brandBackground2), the 3 × 16 selection pill at its leading edge (compoundBrandStroke) and its check in the brand.
// The pointer over another option only steps the neutral fill, and the keyboard's focus rings its row: neither wears
// the brand fill or the pill, so the list never reads as holding two choices. Day and night.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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

/// The selection pill: the one 3 × 16 box a list draws.
final _pills = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.constraints == const BoxConstraints.tightFor(width: 3, height: 16),
);

Future<Fluent2Colors> _stage(
  WidgetTester t,
  Widget body, {
  required Brightness brightness,
  double width = 1440,
}) async {
  t.view.physicalSize = Size(width, 900);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Fluent2Host(brightness: brightness, child: navigator!),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, child: body),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return t.element(find.byType(Scaffold)).fluent2Theme.colors;
}

/// [label]'s words in the open list (not the field's).
Finder _inList(String label) => find.descendant(
  of: find.byType(Fluent2PopoverSurface),
  matching: find.text(label),
);

/// The row round [words]: the nearest box drawn with the row's corners.
(Rect, Color?) _row(WidgetTester t, Finder words) {
  for (final element
      in find
          .ancestor(of: words, matching: find.byType(Container))
          .evaluate()) {
    final box = element.widget as Container;
    if (box.decoration
        case BoxDecoration(:final color, borderRadius: final radius?)
        when radius == BorderRadius.circular(Fluent2Radius.medium)) {
      return (t.getRect(find.byWidget(box)), color);
    }
  }
  fail('no row round $words');
}

/// The one pill there is stands at the leading edge of [words]'s row.
void _pillOn(WidgetTester t, Finder words, Fluent2Colors c) {
  expect(_pills, findsOneWidget, reason: 'one option wears the pill');
  final pill = t.getRect(_pills);
  final (row, _) = _row(t, words);
  expect(pill.left, moreOrLessEquals(row.left, epsilon: .01));
  expect(pill.center.dy, moreOrLessEquals(row.center.dy, epsilon: .5));
  final drawn = t.widget<Container>(_pills).decoration! as BoxDecoration;
  expect(drawn.color, c.compoundBrandStroke);
}

void main() {
  for (final brightness in Brightness.values) {
    final day = brightness == Brightness.light ? 'day' : 'night';

    testWidgets("a select's list marks its chosen option, $day", (t) async {
      final c = await _stage(
        t,
        Fluent2Select<String>(
          label: 'Type',
          value: 'equipment',
          options: _options,
          onChanged: (_) {},
        ),
        brightness: brightness,
      );
      expect(
        c.brandBackground2,
        isNot(c.neutralBackground1Hover),
        reason: "the chosen fill is not the pointer's",
      );
      await t.tap(find.text('Equipment'));
      await t.pumpAndSettle();
      final chosen = _inList('Equipment');
      expect(_row(t, chosen).$2, c.brandBackground2);
      expect(_row(t, _inList('Access')).$2, c.transparentBackground);
      _pillOn(t, chosen, c);
      final check = t.widget<Icon>(
        find.descendant(
          of: find.byType(Fluent2PopoverSurface),
          matching: find.byIcon(Fluent2Icons.checkmark16Filled),
        ),
      );
      expect(check.color, c.compoundBrandForeground1);

      // The pointer over another option: the neutral step, no pill.
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: t.getCenter(_inList('Room booking')));
      addTearDown(mouse.removePointer);
      await t.pumpAndSettle();
      expect(_row(t, _inList('Room booking')).$2, c.neutralBackground1Hover);
      expect(_row(t, chosen).$2, c.brandBackground2);
      _pillOn(t, chosen, c);

      // The keyboard's focus on another option: a ring, no brand.
      await mouse.moveTo(Offset.zero);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pumpAndSettle();
      expect(_row(t, _inList('Access')).$2, isNot(c.brandBackground2));
      expect(_row(t, chosen).$2, c.brandBackground2);
      _pillOn(t, chosen, c);
    });

    testWidgets("a select's sheet on a phone marks its chosen option, $day", (
      t,
    ) async {
      final c = await _stage(
        t,
        Fluent2Select<String>(
          label: 'Type',
          value: 'access',
          options: _options,
          onChanged: (_) {},
        ),
        brightness: brightness,
        width: 390,
      );
      await t.tap(find.text('Access'));
      await t.pumpAndSettle();
      final chosen = find.text('Access').last;
      expect(_row(t, chosen).$2, c.brandBackground2);
      expect(_row(t, find.text('Equipment')).$2, c.transparentBackground);
      _pillOn(t, chosen, c);
    });

    testWidgets("a combobox's list marks its chosen option, $day", (t) async {
      final c = await _stage(
        t,
        Fluent2Combobox<String>(
          label: 'Type',
          value: 'access',
          options: _options,
          onChanged: (_) {},
        ),
        brightness: brightness,
      );
      await t.tap(find.byType(Fluent2Combobox<String>));
      await t.pumpAndSettle();
      final chosen = _inList('Access');
      expect(_row(t, chosen).$2, c.brandBackground2);
      _pillOn(t, chosen, c);
    });

    testWidgets('a menu with a choice marks it, $day', (t) async {
      final c = await _stage(
        t,
        Fluent2Menu<String>(
          items: const [
            Fluent2MenuItem('grid', 'Grid', checked: true),
            Fluent2MenuItem('list', 'List', checked: false),
          ],
          onSelected: (_) {},
        ),
        brightness: brightness,
      );
      expect(_row(t, find.text('Grid')).$2, c.brandBackground2);
      expect(_row(t, find.text('List')).$2, c.neutralBackground1);
      _pillOn(t, find.text('Grid'), c);
    });
  }
}
