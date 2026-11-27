// Every count's numerals on their fill.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/chart_host.dart';

void main() {
  group('badges', () {
    const tones = [
      ('12', MinimalTone.neutral),
      ('4', MinimalTone.primary),
      ('5', MinimalTone.success),
      ('6', MinimalTone.warning),
      ('3', MinimalTone.destructive),
    ];

    Container capsule(WidgetTester tester, String count) =>
        tester.widget<Container>(
          find
              .ancestor(of: find.text(count), matching: find.byType(Container))
              .first,
        );

    Color fillOf(Container box) => switch (box.decoration) {
      BoxDecoration(:final color?) => color,
      ShapeDecoration(:final color?) => color,
      _ => throw StateError('no fill'),
    };

    testWidgets("every count's numerals clear 4.5:1 on its fill, in every "
        'preset and either mode', (tester) async {
      for (final preset in [
        for (final palette in MinimalThemeData.palettes) palette.id,
      ]) {
        for (final brightness in Brightness.values) {
          final t = MinimalThemeData.preset(preset, brightness);
          await tester.pumpWidget(
            chartHost(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (count, tone) in tones)
                    MinimalBadge(count: int.parse(count), tone: tone),
                ],
              ),
              brightness: brightness,
              preset: preset,
            ),
          );
          // The host cross-fades between modes: read the settled colours.
          await tester.pumpAndSettle();
          for (final (count, tone) in tones) {
            final ink = tester.widget<Text>(find.text(count)).style!.color!;
            final fill = fillOf(capsule(tester, count));
            expect(
              contrastRatio(ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$preset, ${brightness.name}, ${tone.name}',
            );
          }
          // A plain count is a neutral tag's: the muted fill in a hairline,
          // not a mid-grey capsule.
          final plain = capsule(tester, '12');
          expect(fillOf(plain), t.muted, reason: '$preset, $brightness');
          final rim = switch (plain.foregroundDecoration) {
            ShapeDecoration(:final OutlinedBorder shape) => shape.side,
            BoxDecoration(:final Border border) => border.top,
            _ => BorderSide.none,
          };
          expect(rim.color, t.border, reason: '$preset, $brightness');
          expect(rim.width, t.hairline, reason: '$preset, $brightness');
        }
      }
    });
  });
}
