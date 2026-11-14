// A select whose value sits at its leading edge opens its list on the
// field's edges at its width, and its options' words start exactly where
// the field's value does: the card's inset plus an option's leading air is
// the field's text inset (shadcn's Select: trigger 12, content 4 + item 8),
// the check at the trailing end. Read at 390 and 1440, standard and compact:
// the combobox's hint, its typed words, with and without a glyph; the tag
// input's (its suggestions open on its box, ui_core 0e25289dfd), alone on
// its hint, which stands where the first tag's words will, and on its first
// tag's words.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const List<String> _cities = ['Lisbon', 'London', 'Lyon'];
const String _hint = 'Pick a city';

const Map<String, MinimalDensity> _densities = {
  'standard': MinimalDensity.standard,
  'compact': MinimalDensity.compact,
};

/// [field] on a page [width] wide at [density]: the gutter's width in from
/// the leading edge, the page measure on a phone, a form column's on a
/// laptop.
Future<void> _pump(
  WidgetTester tester,
  double width,
  MinimalDensity density,
  Widget field,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => MinimalHost(
        light: MinimalThemeData.preset(
          'standard',
          Brightness.light,
        ).copyWith(density: density),
        dark: MinimalThemeData.preset(
          'standard',
          Brightness.dark,
        ).copyWith(density: density),
        brightness: Brightness.light,
        child: navigator!,
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: width < 600 ? width - 36 : math.min(320, width - 36),
              child: field,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Where the open list's options' words start, each one: the options' rows
/// stand under the field's line.
List<double> _optionsX(WidgetTester tester) {
  final line = tester.getRect(find.byType(EditableText)).bottom;
  final words = find.byWidgetPredicate(
    (w) => w is Text && _cities.contains(w.data),
  );
  return [
    for (final e in words.evaluate())
      if (tester.getTopLeft(find.byWidget(e.widget)).dy > line)
        tester.getTopLeft(find.byWidget(e.widget)).dx,
  ];
}

/// Opens the list by typing "L" (Lisbon, London, Lyon), and holds every
/// option's words, and the typed words, on [value].
Future<void> _expectOn(WidgetTester tester, double value, String what) async {
  await tester.tap(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), 'L');
  await tester.pumpAndSettle();
  final options = _optionsX(tester);
  expect(options, isNotEmpty, reason: '$what: the list is open');
  for (final x in options) {
    expect(x, closeTo(value, 0.5), reason: "$what: an option's words");
  }
}

void main() {
  for (final width in const [390.0, 1440.0]) {
    for (final MapEntry(key: name, value: density) in _densities.entries) {
      final at = '${width.toInt()} $name';

      testWidgets('$at: a combobox lists its options on its words', (
        tester,
      ) async {
        for (final icon in const [null, LucideIcons.mapPin]) {
          await _pump(
            tester,
            width,
            density,
            MinimalCombobox<String>(
              key: ValueKey(icon),
              options: _cities,
              hint: _hint,
              icon: icon,
            ),
          );
          final what = icon == null ? 'combobox' : 'combobox with a glyph';
          final hint = tester.getTopLeft(find.text(_hint)).dx;
          await _expectOn(tester, hint, what);
          // The typed words where the hint stood.
          expect(
            tester.getTopLeft(find.byType(EditableText)).dx,
            closeTo(hint, 0.5),
            reason: '$what: the typed words',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('$at: a tag input lists its options on its tags\' words', (
        tester,
      ) async {
        // Empty, its hint stands where the first tag's words will.
        await _pump(
          tester,
          width,
          density,
          MinimalMultiSelect<String>(
            options: _cities,
            values: const [],
            onChanged: (_) {},
            hint: _hint,
          ),
        );
        final hint = tester.getTopLeft(find.text(_hint)).dx;
        await _expectOn(tester, hint, 'tag input, empty');
        expect(
          tester.getTopLeft(find.byType(EditableText)).dx,
          closeTo(hint, 0.5),
          reason: 'tag input: the typed words',
        );
        await tester.pumpWidget(const SizedBox());

        // With a tag, the options meet its words.
        await _pump(
          tester,
          width,
          density,
          MinimalMultiSelect<String>(
            options: _cities,
            values: const ['Lisbon'],
            onChanged: (_) {},
            hint: _hint,
          ),
        );
        final tag = tester.getTopLeft(find.text('Lisbon').first).dx;
        expect(tag, closeTo(hint, 0.5), reason: "the tag's words");
        await _expectOn(tester, tag, 'tag input, one tag');
      });
    }
  }
}
