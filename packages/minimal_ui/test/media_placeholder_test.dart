import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/column_host.dart';

void main() {
  group('MinimalMedia', () {
    testWidgets('a placeholder fills the width and is silent by default', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(
          const MinimalMedia(
            MinimalPlaceholderImage(MinimalMediaKind.food, 2),
            height: 120,
          ),
        ),
      );
      expect(tester.getSize(find.byType(MinimalMedia)), const Size(390, 120));
      expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
      handle.dispose();
    });

    testWidgets('an unresolved slot paints the placeholder, labelled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        columnHost(
          const MinimalMedia.media(
            'hero-bakery',
            height: 160,
            semanticLabel: 'The bakery counter',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel('The bakery counter')),
        matchesSemantics(label: 'The bakery counter', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('placeholders are flat quiet fills, no gradient and no hue', (
      tester,
    ) async {
      for (final id in [
        for (final palette in MinimalThemeData.palettes) palette.id,
      ]) {
        for (final b in Brightness.values) {
          final t = MinimalThemeData.preset(id, b);
          await tester.pumpWidget(
            columnHost(
              Wrap(
                children: [
                  for (final kind in MinimalMediaKind.values)
                    for (var i = 0; i < 3; i++)
                      MinimalMedia(
                        MinimalPlaceholderImage(kind, i),
                        width: 44,
                        height: 44,
                      ),
                ],
              ),
              theme: t,
            ),
          );
          // The host eases from the last preset's colours to this one's.
          await tester.pumpAndSettle();
          final fills = tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(MinimalMedia),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .map((d) => d.decoration)
              .whereType<BoxDecoration>()
              .where((d) => d.gradient != null || d.color != null)
              .toList();
          expect(fills, isNotEmpty, reason: '$id $b');
          for (final d in fills) {
            expect(d.gradient, isNull, reason: '$id $b');
          }
          final colors = fills.map((d) => d.color!).toSet();
          // A step lighter or darker by index, between the quiet fill and
          // the well, and never more than those.
          expect(colors.length, inInclusiveRange(2, 3), reason: '$id $b');
          for (final c in colors) {
            expect(
              c == t.muted ||
                  c == t.sunken ||
                  c == Color.lerp(t.muted, t.sunken, 0.5),
              isTrue,
              reason: '$id $b $c',
            );
          }
        }
      }
    });
  });
}
