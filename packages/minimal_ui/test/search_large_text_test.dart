// Search grows with its words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/text_scale_host.dart';

/// The nearest box around [of]: the face it stands in.
Rect _box(WidgetTester tester, Finder of) => tester.getRect(
  find.ancestor(of: of, matching: find.byType(Container)).first,
);

/// What a 1.3 text scale adds to a 16 px line.
const double _grown = 16 * 1.3 - 16;

void main() {
  group('search grows with its words', () {
    testWidgets('the field at text scale 1.3 grows as a text field does', (
      tester,
    ) async {
      final glyph = find.byWidgetPredicate(
        (w) => w is MinimalIcon && w.icon == LucideIcons.search,
      );
      Future<double> face(double scale) async {
        await tester.pumpWidget(
          textScaleHost(
            const MinimalSearchField(hint: 'Search habits'),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        return _box(tester, glyph).height;
      }

      final rest = await face(1);
      expect(await face(1.3), greaterThanOrEqualTo(rest + _grown - 0.5));
    });

    testWidgets('the entry at text scale 1.3 grows as the field does', (
      tester,
    ) async {
      Future<double> entry(double scale) async {
        await tester.pumpWidget(
          textScaleHost(
            MinimalSearchEntry(label: 'Search habits', onPressed: () {}),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        return _box(tester, find.text('Search habits')).height;
      }

      final rest = await entry(1);
      expect(await entry(1.3), greaterThanOrEqualTo(rest + _grown - 0.5));
    });
  });
}
