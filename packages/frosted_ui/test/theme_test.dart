import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/css_gradient.dart';
import 'package:frosted_ui/src/frosted/internal/themes/platinum.g.dart';

void main() {
  group('FrostedThemeData.preset', () {
    for (final id in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        test('$id ${brightness.name} builds its own appearance', () {
          final t = FrostedThemeData.preset(id, brightness);
          expect(t.id, id);
          expect(t.isDark, brightness == Brightness.dark);
          // The same preset is the same value, so the scope does not notify
          // on every host rebuild.
          expect(identical(t, FrostedThemeData.preset(id, brightness)), isTrue);
          expect(t.textTheme.titleMedium.fontFamily, FrostedThemeData.textFace);
          expect(t.textTheme.headlineSmall.fontFamily, FrostedThemeData.face);
          expect(t.textTheme.displayMedium.fontFamily, FrostedThemeData.face);
          // Every style sets its weight twice: as the FontWeight Flutter
          // reads and as the variable face's wght axis, with its optical
          // size on opsz (Chrome sets it on its own; Flutter does not).
          for (final s in [
            t.textTheme.titleMedium,
            t.textTheme.headlineSmall,
            t.textTheme.displayMedium,
            t.textTheme.labelMedium,
            t.textTheme.amount,
          ]) {
            final axes = {for (final v in s.fontVariations!) v.axis: v.value};
            expect(axes['wght'], s.fontWeight!.value.toDouble());
            expect(axes['opsz'], isNotNull);
          }
        });

        test('$id ${brightness.name}: words read on the grounds', () {
          final t = FrostedThemeData.preset(id, brightness);
          final words = <String, Color>{
            'textPrimary': t.colorScheme.textPrimary,
            'textSecondary': t.colorScheme.textSecondary,
            'accentText': t.colorScheme.accentText,
            'moneyIn': t.colorScheme.moneyIn,
            'over': t.colorScheme.over,
            'warn': t.colorScheme.warning,
            'cold': t.colorScheme.cold,
          };
          // The canvas and the tile: where the source sets words. The well
          // (surfaceAlt) holds controls, never a flow's ink.
          for (final ground in [
            t.colorScheme.background,
            t.colorScheme.surface,
          ]) {
            words.forEach((name, ink) {
              expect(
                FrostedThemeData.contrast(ink, ground),
                greaterThanOrEqualTo(4.5),
                reason: '$id ${brightness.name} $name on $ground',
              );
            });
          }
          expect(
            FrostedThemeData.contrast(
              t.colorScheme.onAccent,
              t.colorScheme.accent,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '$id ${brightness.name} onAccent on accent',
          );
          expect(
            FrostedThemeData.contrast(
              t.colorScheme.textInverse,
              t.colorScheme.surfaceInverse,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '$id ${brightness.name} textInverse on surfaceInverse',
          );
          expect(
            FrostedThemeData.contrast(
              t.colorScheme.onButton,
              t.colorScheme.buttonBottom,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '$id ${brightness.name} onAct on the act',
          );
          expect(
            FrostedThemeData.contrast(t.toast.text, t.toast.bottom),
            greaterThanOrEqualTo(4.5),
            reason: '$id ${brightness.name} onToast on the toast',
          );
          // A tone's ink on its tint over the canvas (a chip): 4.5:1 where
          // the appearance is derived; the captured one keeps the source's
          // own chip (its money-in ink reads 4.2:1 on its tint), held to the
          // large-text floor.
          final captured = id == 'opal' && brightness == Brightness.light;
          for (final tone in FrostedTone.values) {
            final ground = Color.alphaBlend(
              t.toneTint(tone),
              t.colorScheme.background,
            );
            expect(
              FrostedThemeData.contrast(t.toneInk(tone), ground),
              greaterThanOrEqualTo(captured ? 3.0 : 4.5),
              reason: '$id ${brightness.name} ${tone.name} ink on its tint',
            );
          }
          // The card's words on its pearl (the Keel Card, the avatars'
          // cards), over the canvas, at both ends of the pearl.
          for (final pearl in [t.pearl.from, t.pearl.to]) {
            final ground = Color.alphaBlend(pearl, t.colorScheme.background);
            for (final (name, ink) in [
              ('pearlInk', t.pearl.text),
              ('pearlInkQuiet', t.pearl.textSecondary),
            ]) {
              expect(
                FrostedThemeData.contrast(ink, ground),
                greaterThanOrEqualTo(4.5),
                reason: '$id ${brightness.name} $name on the pearl',
              );
            }
          }
          // A hue's ink on its tint (a category's token, a chip).
          for (final (i, hue) in t.hues.categories.indexed) {
            final ground = Color.alphaBlend(hue.tint, t.colorScheme.surface);
            expect(
              FrostedThemeData.contrast(hue.ink, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$id ${brightness.name} hue $i ink on its tint',
            );
          }
        });

        test('$id ${brightness.name}: glyphs read on the grounds', () {
          final t = FrostedThemeData.preset(id, brightness);
          final glyphs = <String, Color>{
            'textTertiary': t.colorScheme.textTertiary,
            'success': t.colorScheme.success,
            'danger': t.colorScheme.danger,
            'warning': t.colorScheme.warning,
            'accent': t.colorScheme.accent,
          };
          for (final ground in [
            t.colorScheme.background,
            t.colorScheme.surface,
          ]) {
            glyphs.forEach((name, ink) {
              expect(
                FrostedThemeData.contrast(ink, ground),
                greaterThanOrEqualTo(3),
                reason: '$id ${brightness.name} $name on $ground',
              );
            });
          }
        });
      }
    }

    test('an unknown preset throws', () {
      expect(
        () => FrostedThemeData.preset('neon', Brightness.light),
        throwsArgumentError,
      );
    });

    test('prism light is the source palette', () {
      final t = FrostedThemeData.preset('opal', Brightness.light);
      expect(t.colorScheme.background, const Color(0xFFF3F3F7));
      expect(t.colorScheme.textPrimary, const Color(0xFF15151D));
      // The quieter inks are the source's eased until they read on the washes.
      for (final ink in [
        t.colorScheme.textSecondary,
        t.colorScheme.textTertiary,
        t.colorScheme.textTertiary,
      ]) {
        for (final ground in t.lights.peaksOver(t.colorScheme.background)) {
          expect(FrostedThemeData.contrast(ink, ground), greaterThan(4.5));
        }
      }
      expect(
        FrostedLightPainter.phone.map((w) => w.opacity),
        FrostedLights.peaks,
      );
      // The act is the ink: there is no second accent.
      expect(t.colorScheme.accent, t.colorScheme.textPrimary);
      // Money in, over, warn and cold are the source's green, red, amber and
      // blue eased the same way, on the washes and on their own tints there.
      for (final (ink, source, tint) in [
        (
          t.colorScheme.moneyIn,
          const Color(0xFF257B51),
          t.colorScheme.moneyInTint,
        ),
        (t.colorScheme.over, const Color(0xFFBC484B), t.colorScheme.overTint),
        (
          t.colorScheme.warning,
          const Color(0xFF8E5D1E),
          t.colorScheme.warningSubtle,
        ),
        (t.colorScheme.cold, const Color(0xFF2F5C8F), t.colorScheme.coldTint),
      ]) {
        expect(ink, isNot(t.colorScheme.textPrimary));
        expect([
          for (var i = 0; i <= 20; i++)
            Color.lerp(source, t.colorScheme.textPrimary, i / 20),
        ], contains(ink));
        for (final ground in [
          ...t.lights.peaksOver(t.colorScheme.background),
          Color.alphaBlend(tint, t.colorScheme.background),
        ]) {
          expect(FrostedThemeData.contrast(ink, ground), greaterThan(4.5));
        }
      }
      expect(t.colorScheme.unreadDot, const Color(0xFFE2707A));
      expect(t.glass.fill, const Color(0x9EFFFFFF));
      expect(t.glass.fillHigh, const Color(0xC7FFFFFF));
      expect(t.hues.categories.length, greaterThanOrEqualTo(8));
      expect(t.hue(t.hues.categories.length), t.hue(0));
      // The spectrum rim: five hues, laid as the source's six stops (the
      // first and last fading out at 4% and 96%).
      expect(t.glass.spectrumStops, hasLength(5));
      expect(t.glass.spectrumStops.first, const Color(0xFFA9AEF0));
      expect(t.glass.spectrumStops.last, const Color(0xFF7EBEF0));
      expect(t.glass.spectrumRim.stops, [0.04, 0.18, 0.38, 0.56, 0.76, 0.96]);
      expect(t.glass.spectrumRim.colors.first.a, 0);
      expect(t.glass.spectrumRim.colors.last.a, 0);
    });

    test('prism carries the source size and leading of every step', () {
      final t = FrostedThemeData.preset('opal', Brightness.light);
      double line(TextStyle s) => s.fontSize! * s.height!;
      final steps = <String, (TextStyle, double, double)>{
        'giant': (t.textTheme.displayLarge, 96, 83),
        'display': (t.textTheme.displayMedium, 64, 55),
        'figure': (t.textTheme.displaySmall, 40, 34),
        'figureSmall': (t.textTheme.headlineLarge, 28, 24),
        'stat': (t.textTheme.stat, 20, 22),
        'hero': (t.textTheme.headlineMedium, 28, 31),
        'h1': (t.textTheme.headlineSmall, 20, 22),
        'h2': (t.textTheme.titleLarge, 16, 20),
        'h3': (t.textTheme.titleSmall, 14, 14),
        'bodyLarge': (t.textTheme.bodyLarge, 16, 22),
        'body': (t.textTheme.titleMedium, 16, 20),
        'bodySmall': (t.textTheme.bodyMedium, 14, 19),
        'amount': (t.textTheme.amount, 16, 20),
        'amountSmall': (t.textTheme.amountSmall, 14, 16),
        'caption': (t.textTheme.labelMedium, 12, 16),
        'note': (t.textTheme.bodySmall, 12, 17),
        'label': (t.textTheme.labelLarge, 14, 14),
        'labelSmall': (t.textTheme.labelSmall, 12, 12),
        'link': (t.textTheme.link, 14, 14),
        'tab': (t.textTheme.tab, 12, 12),
        'eyebrow': (t.textTheme.overline, 12, 16),
        'mono': (t.textTheme.mono, 14, 14),
        'monoSmall': (t.textTheme.monoSmall, 12, 12),
        'monogram': (t.textTheme.monogram, 14, 14),
        'wordmark': (t.textTheme.wordmark, 24, 24),
      };
      steps.forEach((name, step) {
        expect(step.$1.fontSize, step.$2, reason: '$name size');
        expect(line(step.$1), closeTo(step.$3, 0.001), reason: '$name line');
      });
      // Money is the medium cut, tightly tracked; the heads are semibold.
      expect(t.textTheme.displayMedium.fontWeight, const FontWeight(500));
      expect(t.textTheme.headlineSmall.fontWeight, const FontWeight(600));
      expect(
        t.textTheme.displayMedium.letterSpacing,
        closeTo(64 * -0.035, 0.001),
      );
      expect(t.textTheme.wordmark.letterSpacing, closeTo(24 * -0.04, 0.001));
      // Rows' amounts are tabular (`tnum`); the figures keep proportional
      // numerals, as the source's `.money` sets none.
      expect(
        t.textTheme.amount.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(t.textTheme.displayMedium.fontFeatures, isNull);
      expect(t.textTheme.displayLarge.fontFeatures, isNull);
    });

    test('the optical size follows the size within the face', () {
      final t = FrostedThemeData.preset('opal', Brightness.light);
      double opsz(TextStyle s) =>
          s.fontVariations!.firstWhere((v) => v.axis == 'opsz').value;
      expect(opsz(t.textTheme.displayLarge), 96);
      expect(opsz(t.textTheme.titleSmall), 14);
      // DM Sans runs 9 to 40: a body of 16 sits inside it.
      expect(opsz(t.textTheme.titleMedium), 16);
      expect(opsz(t.textTheme.labelMedium), 12);
    });

    test("quartz is Cody's platinum, baked, through the same roles", () {
      final preset = FrostedThemeData.preset('quartz', Brightness.light);
      expect(preset.colorScheme.background, platinumTokens.light.background);
      // Its corners are the look's (one family since the settings cut), not
      // platinum's 22.
      expect(
        preset.colorScheme.background,
        isNot(
          FrostedThemeData.preset(
            'opal',
            Brightness.light,
          ).colorScheme.background,
        ),
      );
    });

    test('quartz keeps its steps in order, largest first', () {
      final t = FrostedThemeData.preset('quartz', Brightness.light);
      final sizes = [
        t.textTheme.displayLarge,
        t.textTheme.displayMedium,
        t.textTheme.displaySmall,
        t.textTheme.headlineMedium,
        t.textTheme.headlineSmall,
        t.textTheme.titleLarge,
        t.textTheme.titleMedium,
        t.textTheme.bodyMedium, //
      ].map((s) => s.fontSize!).toList();
      expect(sizes, [...sizes]..sort((a, b) => b.compareTo(a)));
    });

    test('a flow has its ink and a tone its tint', () {
      for (final id in FrostedThemeData.presets) {
        for (final brightness in Brightness.values) {
          final t = FrostedThemeData.preset(id, brightness);
          expect(
            t.flowInk(FrostedMoneyFlow.inflow),
            t.colorScheme.moneyIn,
            reason: id,
          );
          expect(
            t.flowInk(FrostedMoneyFlow.outflow),
            t.colorScheme.textPrimary,
            reason: id,
          );
          expect(t.toneInk(FrostedTone.danger), t.colorScheme.over, reason: id);
          expect(
            t.toneTint(FrostedTone.info),
            t.colorScheme.coldTint,
            reason: id,
          );
          expect(t.toneTint(FrostedTone.quiet), t.glass.wash, reason: id);
        }
      }
    });

    test('the light is the source\'s three washes', () {
      expect(FrostedLightPainter.phone, hasLength(3));
      expect(FrostedLightPainter.desktop, hasLength(3));
      final b1 = FrostedLightPainter.phone[0];
      expect((b1.diameter, b1.x, b1.y, b1.opacity), (260.0, -90.0, 60.0, 0.85));
      expect(FrostedLightPainter.phone[2].fromEnd, isTrue);
      final t = FrostedThemeData.preset('opal', Brightness.light);
      expect(t.lights.strength, 1);
      expect(
        FrostedThemeData.preset('opal', Brightness.dark).lights.strength,
        lessThan(1),
      );
    });
  });

  group('FrostedFormat', () {
    final now = DateTime(2026, 10, 28, 19, 42);

    test('money reads as the pilot writes it', () {
      final parts = FrostedFormat.moneyParts(-1326.44);
      expect(parts.sign, '−');
      expect(parts.whole, '1,326');
      expect(parts.cents, '44');
      expect(FrostedFormat.money(6248.30), '\$6,248.30');
      expect(FrostedFormat.money(-1326.44), '−\$1,326.44');
      expect(FrostedFormat.money(3412.5, sign: true), '+\$3,412.50');
      expect(FrostedFormat.money(2700.4, cents: false), '\$2,700');
      // A zero carries no sign.
      expect(FrostedFormat.money(0, sign: true), '\$0.00');
      expect(FrostedFormat.money(-0.001), '\$0.00');
    });

    test('whole dollars round half to even', () {
      expect(FrostedFormat.wholeDollars(2.5), 2);
      expect(FrostedFormat.wholeDollars(3.5), 4);
      expect(FrostedFormat.wholeDollars(2.51), 3);
      expect(FrostedFormat.wholeDollars(-84.25), 84);
    });

    test('days and times read as the pilot writes them', () {
      expect(FrostedFormat.day(DateTime(2026, 10, 28, 8), now: now), 'Today');
      expect(FrostedFormat.day(DateTime(2026, 10, 27), now: now), 'Yesterday');
      expect(
        FrostedFormat.day(DateTime(2026, 10, 26), now: now),
        'Mon, Oct 26',
      );
      expect(
        FrostedFormat.day(DateTime(2025, 12, 31), now: now),
        'Wed, Dec 31, 2025',
      );
      expect(FrostedFormat.date(DateTime(2026, 11, 1)), 'Nov 1');
      expect(
        FrostedFormat.date(DateTime(2026, 11, 1), weekday: true),
        'Sun, Nov 1',
      );
      expect(
        FrostedFormat.date(DateTime(2026, 11, 1), year: true),
        'Nov 1, 2026',
      );
      expect(
        FrostedFormat.longDate(DateTime(2026, 10, 28)),
        'Wednesday, October 28, 2026',
      );
      expect(FrostedFormat.month(now), 'October');
      expect(FrostedFormat.month(now, short: true), 'Oct');
      expect(FrostedFormat.month(now, year: true), 'October 2026');
      expect(FrostedFormat.time(DateTime(2026, 10, 28, 8, 12)), '8:12 AM');
      expect(FrostedFormat.time(now), '7:42 PM');
      expect(FrostedFormat.time(DateTime(2026, 10, 28, 0, 5)), '12:05 AM');
      expect(FrostedFormat.time(DateTime(2026, 10, 28, 12)), '12:00 PM');
      expect(FrostedFormat.nowLabel(now), 'Wed, Oct 28 · 7:42 PM');
    });

    test('the days ahead count calendar days', () {
      expect(FrostedFormat.daysUntil(DateTime(2026, 11, 1), now: now), 4);
      expect(
        FrostedFormat.inDays(DateTime(2026, 10, 28, 23), now: now),
        'Today',
      );
      expect(
        FrostedFormat.inDays(DateTime(2026, 10, 29), now: now),
        'Tomorrow',
      );
      expect(
        FrostedFormat.inDays(DateTime(2026, 11, 1), now: now),
        'In 4 days',
      );
    });

    test('the greeting follows the hour', () {
      String at(int hour) =>
          FrostedFormat.greeting('Maren', now: DateTime(2026, 10, 28, hour));
      expect(at(9), 'Good morning, Maren');
      expect(at(13), 'Good afternoon, Maren');
      expect(at(19), 'Good evening, Maren');
    });

    test('monograms, shares and counts', () {
      expect(FrostedFormat.initials('Blue Fern Café'), 'BF');
      expect(FrostedFormat.initials('Cloudbox'), 'CL');
      expect(FrostedFormat.initials('H&M'), 'HM');
      expect(FrostedFormat.initials(''), '');
      expect(FrostedFormat.percent(2840, 4000), 71);
      expect(FrostedFormat.percent(1, 8), 12);
      expect(FrostedFormat.percent(3, 8), 38);
      expect(FrostedFormat.count(14880), '14,880');
      expect(FrostedFormat.count(-1200), '-1,200');
      expect(FrostedFormat.plural(1, 'bill'), '1 bill');
      expect(FrostedFormat.plural(3, 'bill'), '3 bills');
      expect(FrostedFormat.plural(2, 'category', 'categories'), '2 categories');
    });
  });

  group('CSS gradients', () {
    // CSS mixes a gradient's stops premultiplied by alpha; Flutter mixes
    // them straight. A band's sheen lights from nothing to white: halfway,
    // CSS's mix keeps the hue under it far more than a straight mix's.
    test('a span of two alphas follows the premultiplied mix', () {
      const faint = Color(0x667A62FF); // rgba(122, 98, 255, .4)
      const hue = Color(0xFF55BFFF);
      final css = frostedCssStops([faint, hue]);
      expect(css.colors.length, 9);
      expect(css.stops.first, 0);
      expect(css.stops.last, 1);
      expect(css.colors.first, faint);
      expect(css.colors.last, hue);
      final half = css.colors[css.stops.indexOf(0.5)];
      expect(half.a, closeTo(0.7, 1e-9));
      expect(half.r * 255, closeTo(95.6, 0.1)); // straight: 103.5
      expect(half.g * 255, closeTo(164.4, 0.1)); // straight: 144.5
      expect(half.b * 255, closeTo(255, 0.1));
    });

    test('a span of one alpha is left whole, the stops kept', () {
      const a = Color(0xFF7A62FF);
      const b = Color(0xFF55BFFF);
      final css = frostedCssStops([a, b, a], stops: const [0, 0.55, 1]);
      expect(css.colors, [a, b, a]);
      expect(css.stops, [0, 0.55, 1]);
    });
  });
}
