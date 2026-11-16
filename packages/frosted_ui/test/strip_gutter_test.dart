// A strip that runs on under the page's gutters (the filter chips, the tabs
// on a phone) takes a tap where it is drawn: a chip scrolled out under the
// gutter answers a tap there (ui_core's tap check: "a button 'Everyday': a
// screen reader outlines 68.7 × 48, past where a tap reaches (53 × 48)"; hit
// testing stopped at the line, 16 pt in). The strip clips at the screen's
// edge, its first item on the keyline at rest, left to right and right to
// left.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';

const _options = [
  FrostedFilterOption('all', 'All'),
  FrostedFilterOption('in', 'Money in'),
  FrostedFilterOption('out', 'Money out'),
  FrostedFilterOption('pending', 'Pending'),
  FrostedFilterOption('every', 'Everyday'),
  FrostedFilterOption('travel', 'Travel'),
];

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a chip under the gutter takes a tap there ($direction)', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final chosen = <String>[];
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => Directionality(
            textDirection: direction,
            child: FrostedHost(brightness: Brightness.light, child: page!),
          ),
          home: FrostedScaffold(
            body: FrostedFilterChipGroup<String>(
              options: _options,
              value: 'all',
              label: 'Show',
              onChanged: chosen.add,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final rtl = direction == TextDirection.rtl;
      const gutter = 16.0;
      // The first chip stands on the keyline.
      final first = t.getRect(find.widgetWithText(FrostedPressable, 'All'));
      final face = t.getRect(
        find
            .ancestor(of: find.text('All'), matching: find.byType(FrostedFace))
            .first,
      );
      expect(rtl ? 390 - face.right : face.left, gutter);
      expect(first.height, FrostedBreakpoints.touchHitTarget);
      // A point in the far gutter, on the chips' row: the chip drawn there
      // takes the tap.
      final at = Offset(rtl ? gutter / 2 : 390 - gutter / 2, first.center.dy);
      String? under;
      for (final o in _options) {
        final r = t.getRect(find.widgetWithText(FrostedPressable, o.label));
        if (r.contains(at)) under = o.value;
      }
      expect(under, isNotNull, reason: 'a chip runs on under the gutter');
      await t.tapAt(at);
      await t.pump(const Duration(milliseconds: 100));
      expect(chosen, [under]);
    });
  }
}
