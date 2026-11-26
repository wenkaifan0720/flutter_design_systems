// ApplianceColors.from works out a brand's colours with ui_core's
// RawPalette: the signal key keeps the named colour with whichever legend
// reads 4.5:1 (RawAccentRule.named), its words read 4.5:1 on the housing, a
// faceplate, a well and a key, its focus 3:1, and a cream finish
// leaves the night plastic a warm graphite at its own tones. A toast's action
// reads on the toast.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(applianceLoadFonts);

  const brands = [
    Color(0xFF1F3A68), // navy
    Color(0xFF2E7D32), // green
    Color(0xFFC9A227), // gold
    Color(0xFF16807A), // teal
    Color(0xFFE91E63), // pink
    Color(0xFF1F7A5C), // the README's green
  ];

  for (final b in Brightness.values) {
    for (final brand in brands) {
      final c = ApplianceColors.from(brightness: b, signal: brand);
      final name = '${b.name}, #${brand.toARGB32().toRadixString(16)}';

      test(
        '$name: the key reads and keeps its colour where a legend reads',
        () {
          expect(
            applianceContrast(c.onSignal, c.signal),
            greaterThanOrEqualTo(4.5),
          );
          if (applianceContrast(const Color(0xFFFFFFFF), brand) >= 4.5 ||
              applianceContrast(ApplianceColors.light.onSignal, brand) >= 4.5) {
            expect(c.signal, brand);
          }
        },
      );

      test('$name: its words read 4.5:1 on the housing, a faceplate, a well '
          'and a key', () {
        for (final ground in [
          c.housingTop,
          c.housingBottom,
          c.face,
          c.well,
          c.keyTop,
          c.keyBottom,
        ]) {
          expect(
            applianceContrast(c.signalInk, ground),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('$name, a cream finish: muted words read 4.5:1 on every '
          'plastic', () {
        final cream = ApplianceColors.from(
          brightness: b,
          finish: const Color(0xFFFFF4EC),
          signal: brand,
        );
        for (final ground in [
          cream.housingTop,
          cream.housingBottom,
          cream.face,
          cream.well,
          cream.keyTop,
          cream.keyBottom,
        ]) {
          expect(
            applianceContrast(cream.printMuted, ground),
            greaterThanOrEqualTo(4.5),
          );
        }
      });

      test('$name: its focus stands 3:1 on the housing and a faceplate', () {
        for (final ground in [c.housingTop, c.housingBottom, c.face]) {
          expect(applianceContrast(c.focus, ground), greaterThanOrEqualTo(3));
        }
      });
    }

    test("${b.name}: a cream finish keeps the plastic's tones", () {
      final own = b == Brightness.dark
          ? ApplianceColors.dark
          : ApplianceColors.light;
      final c = ApplianceColors.from(
        brightness: b,
        finish: const Color(0xFFF5E6C8),
      );
      for (final (part, mine, theirs) in [
        ('housing', c.housingBottom, own.housingBottom),
        ('faceplate', c.face, own.face),
        ('key', c.keyTop, own.keyTop),
      ]) {
        final want = applianceContrast(own.print, theirs);
        expect(
          applianceContrast(c.print, mine),
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
    for (final b in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(b),
          builder: (context, app) => ApplianceHost(brightness: b, child: app!),
          home: Builder(
            builder: (context) => Center(
              child: ApplianceButton(
                'Move',
                onPressed: () => showApplianceToast(
                  context,
                  'Kettle moved',
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Move'));
      await tester.pump(const Duration(milliseconds: 600));
      final c = b == Brightness.dark
          ? ApplianceColors.dark
          : ApplianceColors.light;
      final words =
          tester.widget<Text>(find.text('UNDO')).style?.color ??
          DefaultTextStyle.of(tester.element(find.text('UNDO'))).style.color!;
      expect(
        applianceContrast(words, c.display),
        greaterThanOrEqualTo(4.5),
        reason: b.name,
      );
      await tester.pumpAndSettle(const Duration(seconds: 10));
    }
  });
}
