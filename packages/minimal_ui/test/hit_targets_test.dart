import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scrolling_host.dart';

void main() {
  group('hit targets', () {
    // A tap just outside what a small control paints, still inside its
    // 44 px target.
    Future<void> tapBelow(WidgetTester tester, Finder painted, double dy) =>
        tester.tapAt(tester.getRect(painted).bottomCenter + Offset(0, dy));

    Finder pill(String text) => find
        .ancestor(of: find.text(text), matching: find.byType(Container))
        .first;

    testWidgets('a date pill opens from 7 px below its face', (tester) async {
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Starts',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.getSize(pill('21 Aug 2026')).height, 28);
      await tapBelow(tester, pill('21 Aug 2026'), 7);
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('the month buttons and the days take taps beside them', (
      tester,
    ) async {
      final chosen = <DateTime>[];
      await tester.pumpWidget(
        scrollingHost(
          MinimalDatePicker(
            labelText: 'Started',
            value: DateTime(2026, 8, 21),
            mode: MinimalDatePickerMode.date,
            presentation: MinimalDatePickerPresentation.inline,
            onChanged: chosen.add,
          ),
        ),
      );
      await tapBelow(tester, find.bySemanticsLabel('Next month'), 6);
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);
      await tester.tapAt(
        tester.getRect(find.bySemanticsLabel('Previous month')).topCenter -
            const Offset(0, 6),
      );
      await tester.pump();
      expect(find.text('August 2026'), findsOneWidget);
      await tapBelow(tester, pill('15'), 5);
      expect(chosen, [DateTime(2026, 8, 15)]);
    });

    testWidgets('the clear glyphs and the scopes take taps beside them', (
      tester,
    ) async {
      final input = TextEditingController(text: 'Morning run');
      addTearDown(input.dispose);
      final search = TextEditingController(text: 'run');
      addTearDown(search.dispose);
      final scopes = <int>[];
      await tester.pumpWidget(
        scrollingHost(
          Column(
            children: [
              MinimalTextField(
                labelText: 'Name',
                helperText: 'Shown on Today.',
                controller: input,
                clearable: true,
              ),
              MinimalSearchField(
                controller: search,
                clearable: true,
                scopes: const ['All', 'Open', 'Done'],
                onScopeChanged: scopes.add,
              ),
            ],
          ),
        ),
      );
      await tapBelow(tester, find.bySemanticsLabel('Clear Name'), 5);
      await tester.pump();
      expect(input.text, isEmpty);
      await tapBelow(tester, find.bySemanticsLabel('Clear'), 6);
      await tester.pump();
      expect(search.text, isEmpty);
      await tapBelow(tester, find.bySemanticsLabel('Done'), 7);
      expect(scopes, [2]);
    });

    // The 28 glyph stands in the taller toolbar box: the box's air under
    // it, and the band round the box, are the glyph's, not the field's.
    testWidgets('the toolbar search\'s clear takes taps under its glyph', (
      tester,
    ) async {
      final search = TextEditingController();
      addTearDown(search.dispose);
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchField(
            controller: search,
            presentation: MinimalSearchPresentation.toolbar,
          ),
        ),
      );
      for (final dy in [3.0, 7.0]) {
        search.text = 'read';
        await tester.pump();
        await tapBelow(tester, find.bySemanticsLabel('Clear'), dy);
        await tester.pump();
        expect(search.text, isEmpty, reason: '$dy px under the glyph');
      }
    });

    testWidgets('the search entry and its filter square take taps below', (
      tester,
    ) async {
      var opened = 0;
      var filtered = 0;
      await tester.pumpWidget(
        scrollingHost(
          MinimalSearchEntry(
            label: 'Search habits',
            onPressed: () => opened += 1,
            onFilter: () => filtered += 1,
          ),
        ),
      );
      // The square's node spans its reach, the floor tall: its bottom row,
      // 5 px under the face, takes the tap.
      final square = tester.getRect(find.bySemanticsLabel('Filters'));
      expect(square.height, 44);
      await tester.tapAt(square.bottomCenter - const Offset(0, 1));
      await tapBelow(tester, find.text('Search habits'), 10);
      expect(filtered, 1);
      expect(opened, 1);
    });
  });
}
