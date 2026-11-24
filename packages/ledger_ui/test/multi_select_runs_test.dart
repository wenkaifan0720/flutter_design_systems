// A multi-select's tags in runs: a pill stands the tags' gap from the pill
// above it and from the field's rule under the last run, as it does from
// the pill beside it, with a pointer (a pill taller than the pointer's
// floor) and on touch (the floor already parts them). The last run keeps
// the same room above the rule whatever the count, as one run does.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _categories = ['Rent', 'Groceries', 'Transit', 'Utilities'];

// The gap between two tags on a run.
const _gap = 6.0;

void main() {
  setUpAll(ledgerLoadFonts);

  for (final platform in [TargetPlatform.macOS, TargetPlatform.android]) {
    Future<({List<Rect> pills, Rect field, Rect entry})> measure(
      WidgetTester tester,
      int tags,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) =>
              LedgerHost(brightness: Brightness.light, child: child!),
          home: Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 340,
                  child: LedgerMultiSelect<String>(
                    labelText: 'Categories',
                    values: _categories.take(tags).toList(),
                    options: _categories,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Each pill: its tag's box, narrowed to the pill's height.
      final pills = [
        for (final word in _categories.take(tags))
          () {
            final tag = tester.getRect(
              find
                  .ancestor(
                    of: find.text(word.toUpperCase()),
                    matching: find.byType(Stack),
                  )
                  .first,
            );
            return Rect.fromCenter(
              center: tag.center,
              width: tag.width,
              height: 28,
            );
          }(),
      ];
      final field = tester.getRect(find.byType(LedgerMultiSelect<String>));
      final entry = tester.getRect(find.byType(EditableText));
      return (pills: pills, field: field, entry: entry);
    }

    testWidgets('on ${platform.name}, four tags on two runs stand apart', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final (:pills, :field, entry: _) = await measure(tester, 4);
      final lastTop = pills.map((p) => p.top).reduce((a, b) => a > b ? a : b);
      expect(pills.first.top, lessThan(lastTop), reason: 'two runs');
      for (final upper in pills.where((p) => p.top < lastTop)) {
        for (final lower in pills.where((p) => p.top == lastTop)) {
          expect(lower.top - upper.bottom, greaterThanOrEqualTo(_gap));
        }
      }
      for (final last in pills.where((p) => p.top == lastTop)) {
        expect(field.bottom - last.bottom, greaterThanOrEqualTo(_gap));
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'on ${platform.name}, the last run of tags keeps one room above the '
      'rule whatever the count',
      (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        final rooms = <int, double>{};
        for (final tags in [1, 2, 4]) {
          final (:pills, :field, :entry) = await measure(tester, tags);
          // Counted where the entry stands beside the last tag, on its run.
          if ((entry.center.dy - pills.last.center.dy).abs() > 1) continue;
          rooms[tags] = field.bottom - pills.last.bottom;
        }
        expect(rooms.length, greaterThanOrEqualTo(2), reason: '$rooms');
        for (final room in rooms.values) {
          expect(room, closeTo(rooms.values.first, 0.5), reason: '$rooms');
          expect(room, greaterThanOrEqualTo(_gap));
        }
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
