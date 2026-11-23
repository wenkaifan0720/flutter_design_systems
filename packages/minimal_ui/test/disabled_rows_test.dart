// A disabled row dims its words and keeps its rule.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

/// How opaque [part] paints: every fade above it, multiplied.
double _fade(WidgetTester tester, Finder part) {
  var opacity = 1.0;
  for (final o in tester.widgetList<Opacity>(
    find.ancestor(of: part, matching: find.byType(Opacity)),
  )) {
    opacity *= o.opacity;
  }
  for (final f in tester.widgetList<FadeTransition>(
    find.ancestor(of: part, matching: find.byType(FadeTransition)),
  )) {
    opacity *= f.opacity.value;
  }
  return opacity;
}

/// A container that rules its foot.
final Finder _ruled = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.foregroundDecoration is BoxDecoration &&
      ((w.foregroundDecoration! as BoxDecoration).border as Border?)
              ?.bottom
              .width !=
          null &&
      ((w.foregroundDecoration! as BoxDecoration).border! as Border)
              .bottom
              .width >
          0,
);

void main() {
  group('a disabled row dims its words and keeps its rule', () {
    Future<void> check(WidgetTester tester, Widget row, String label) async {
      await tester.pumpWidget(scaledPage(row));
      await tester.pump(const Duration(milliseconds: 300));
      final words = find.text(label);
      final rule = find.ancestor(of: words, matching: _ruled).first;
      expect(_fade(tester, words), lessThan(1));
      expect(_fade(tester, rule), 1);
    }

    testWidgets('MinimalSelect', (tester) async {
      await check(
        tester,
        const MinimalSelect<String>(
          labelText: 'Repeats',
          value: 'daily',
          options: [MinimalSelectOption('daily', 'Every day')],
        ),
        'Repeats',
      );
    });

    testWidgets('MinimalChoiceRow', (tester) async {
      await check(
        tester,
        const MinimalChoiceRow(title: 'Every day', selected: false),
        'Every day',
      );
    });

    testWidgets('MinimalDatePicker', (tester) async {
      await check(
        tester,
        MinimalDatePicker(
          labelText: 'Paused until',
          value: DateTime(2026, 9, 14, 7),
        ),
        'Paused until',
      );
    });

    testWidgets('MinimalInputRow', (tester) async {
      await check(
        tester,
        const MinimalInputRow(labelText: 'Name', enabled: false),
        'Name',
      );
    });
  });
}
