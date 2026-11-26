// KeycapColors.from works out a brand's colours with ui_core's RawPalette:
// the accent key keeps the named colour with whichever legend reads 4.5:1
// (RawAccentRule.named), its words read 4.5:1 on every ground they are
// painted on, its focus 3:1, and a cream alpha tint leaves the night alphas
// a warm graphite at their own tones. A toast's action reads on the toast.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(keycapLoadFonts);

  const brands = [
    Color(0xFF1F3A68), // navy
    Color(0xFF2E7D32), // green
    Color(0xFFC9A227), // gold
    Color(0xFF16807A), // teal
    Color(0xFFE91E63), // pink
  ];

  for (final b in Brightness.values) {
    for (final brand in brands) {
      final c = KeycapColors.from(brightness: b, accent: brand);
      final name = '${b.name}, #${brand.toARGB32().toRadixString(16)}';

      test(
        '$name: the key reads and keeps its colour where a legend reads',
        () {
          expect(
            keycapContrast(c.accent.legend, c.accent.top),
            greaterThanOrEqualTo(4.5),
          );
          if (keycapContrast(const Color(0xFFFFFFFF), brand) >= 4.5 ||
              keycapContrast(KeycapColors.light.ink, brand) >= 4.5) {
            expect(c.accent.top, brand);
          }
        },
      );

      test('$name: its words read 4.5:1 on every ground', () {
        for (final ground in [
          c.ground,
          c.well,
          c.page,
          c.pageSelected,
          c.panel,
        ]) {
          expect(
            keycapContrast(c.accentInk, ground),
            greaterThanOrEqualTo(4.5),
          );
        }
        if (b == Brightness.dark) {
          expect(
            keycapContrast(c.latchedLegend, c.modifier.top),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('$name: its focus stands 3:1 on the case, wells and panels', () {
        for (final ground in [c.ground, c.well, c.panel]) {
          expect(keycapContrast(c.focus, ground), greaterThanOrEqualTo(3));
        }
      });
    }

    test('${b.name}: a cream alpha tint keeps the alphas\' tones', () {
      final own = b == Brightness.dark ? KeycapColors.dark : KeycapColors.light;
      final c = KeycapColors.from(
        brightness: b,
        alpha: const Color(0xFFF5E6C8),
      );
      for (final (part, mine, theirs) in [
        ('top', c.alpha.top, own.alpha.top),
        ('front', c.alpha.front, own.alpha.front),
      ]) {
        final want = keycapContrast(own.alpha.legend, theirs);
        expect(
          keycapContrast(c.alpha.legend, mine),
          closeTo(want, want * 0.02),
          reason: part,
        );
        // A dark tone holds little chroma: a warm graphite, not brown.
        final hct = RawHct.fromColor(mine);
        if (hct.tone <= 40) expect(hct.chroma, lessThanOrEqualTo(6.5));
      }
    });
  }

  testWidgets("a toast's action reads 4.5:1 on the toast", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            KeycapHost(brightness: Brightness.light, child: app!),
        home: Builder(
          builder: (context) => Center(
            child: KeycapButton(
              onPressed: () => showKeycapToast(
                context,
                'Note moved',
                actionLabel: 'Undo',
                onAction: () {},
              ),
              child: const Text('Move'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Move'));
    await tester.pump(const Duration(milliseconds: 600));
    final c = KeycapColors.light;
    final words =
        tester.widget<Text>(find.text('Undo')).style?.color ??
        DefaultTextStyle.of(tester.element(find.text('Undo'))).style.color!;
    expect(keycapContrast(words, c.toast), greaterThanOrEqualTo(4.5));
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });
}
