import 'dart:ui' show Tristate;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import 'support/scrolling_host.dart';

void main() {
  group('MinimalSearchEntry', () {
    testWidgets('the entry and its filter square are two controls', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      var filtered = 0;
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchEntry(
            label: 'Search habits',
            detail: 'In Habits',
            onPressed: () => opened += 1,
            onFilter: () => filtered += 1,
            filtersActive: true,
          ),
        ),
      );
      await tester.tap(find.text('Search habits'));
      await tester.tap(find.bySemanticsLabel('Filters, active'));
      expect(opened, 1);
      expect(filtered, 1);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('Search habits')))
            .getSemanticsData()
            .flagsCollection
            .isButton,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('beside a two-line entry the filter square stands as tall '
        'as the entry', (tester) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchEntry(
            label: 'Search issues',
            detail: 'In Habits · 6 open',
            onPressed: () {},
            onFilter: () {},
          ),
        ),
      );
      final entry = tester.getRect(
        find
            .ancestor(
              of: find.text('Search issues'),
              matching: find.byType(Container),
            )
            .first,
      );
      final square = tester.getRect(
        find
            .ancestor(
              of: find.byType(MinimalIcon).last,
              matching: find.byType(Container),
            )
            .first,
      );
      expect(entry.height, greaterThan(MinimalChromeMetrics.control));
      expect(square.top, moreOrLessEquals(entry.top, epsilon: 0.5));
      expect(square.height, moreOrLessEquals(entry.height, epsilon: 0.5));
    });

    testWidgets('with no onPressed it is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        scrollingHost(const MinimalSearchEntry(label: 'Search archive')),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Search archive'));
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      handle.dispose();
    });
  });
}
