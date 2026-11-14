import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/src/ledger/internal/themes/paper.g.dart';

void main() {
  group('LedgerThemeData.preset', () {
    for (final id in LedgerThemeData.presets) {
      for (final brightness in Brightness.values) {
        test('$id ${brightness.name} builds its own appearance', () {
          final t = LedgerThemeData.preset(id, brightness);
          expect(t.id, id);
          expect(t.isDark, brightness == Brightness.dark);
          // The same preset is the same value, so the scope does not notify
          // on every host rebuild.
          expect(identical(t, LedgerThemeData.preset(id, brightness)), isTrue);
          expect(t.body.fontFamily, ledgerFontFamily('InterTight'));
          expect(t.figure.fontFamily, ledgerFontFamily('InstrumentSerif'));
          expect(t.monogram.fontStyle, FontStyle.italic);
          expect(t.amount.fontFamily, ledgerFontFamily('PlexMono'));
        });

        test('$id ${brightness.name}: words read on the papers', () {
          final t = LedgerThemeData.preset(id, brightness);
          final words = <String, Color>{
            'textPrimary': t.textPrimary,
            'textSecondary': t.textSecondary,
            'accentText': t.accentText,
            'moneyIn': t.moneyIn,
          };
          for (final ground in [t.background, t.surface, t.surfaceAlt]) {
            words.forEach((name, ink) {
              expect(
                LedgerThemeData.contrast(ink, ground),
                greaterThanOrEqualTo(4.5),
                reason: '$id ${brightness.name} $name on $ground',
              );
            });
          }
          // The third ink sets the meta lines on the page and its slips.
          for (final ground in [t.background, t.surface]) {
            expect(
              LedgerThemeData.contrast(t.textTertiary, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$id ${brightness.name} textTertiary on $ground',
            );
          }
          final pairs = <String, (Color, Color)>{
            'onAccent on accent': (t.onAccent, t.accent),
            'textInverse on surfaceInverse': (t.textInverse, t.surfaceInverse),
            'onToast on toast': (t.onToast, t.toast),
            'onToastAction on toast': (t.onToastAction, t.toast),
            'onAvatar on avatar': (t.onAvatar, t.avatar),
          };
          pairs.forEach((name, pair) {
            expect(
              LedgerThemeData.contrast(pair.$1, pair.$2),
              greaterThanOrEqualTo(4.5),
              reason: '$id ${brightness.name} $name',
            );
          });
        });

        test('$id ${brightness.name}: glyphs read on the papers', () {
          final t = LedgerThemeData.preset(id, brightness);
          final glyphs = <String, Color>{
            'textTertiary': t.textTertiary,
            'accent': t.accent,
            'success': t.success,
            'danger': t.danger,
            'over': t.over,
            'warning': t.warning,
          };
          for (final ground in [t.background, t.surface, t.surfaceAlt]) {
            glyphs.forEach((name, ink) {
              expect(
                LedgerThemeData.contrast(ink, ground),
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
        () => LedgerThemeData.preset('neon', Brightness.light),
        throwsArgumentError,
      );
    });

    test('quire light is the source palette, role for role', () {
      final t = LedgerThemeData.preset('quire', Brightness.light);
      expect(t.background, const Color(0xFFF2EDE3)); // --paper
      expect(t.surface, const Color(0xFFF9F6F0)); // --paper-hi
      expect(t.surfaceAlt, const Color(0xFFEAE4D8)); // --paper-lo
      expect(t.textPrimary, const Color(0xFF141A1F)); // --ink
      expect(t.textSecondary, const Color(0xFF4A5055)); // --ink-2
      expect(t.textTertiary, const Color(0xFF686B6D)); // --ink-3
      expect(t.textFaint, const Color(0xFFA9A69F)); // --ink-4
      expect(t.accent, const Color(0xFF1E5A44)); // --green
      expect(t.moneyIn, const Color(0xFF1E5A44));
      expect(t.accentSubtle, const Color(0xFFDEE7DD)); // --green-wash
      expect(t.danger, const Color(0xFFC9402A)); // --red
      // The vermilion as words: --red three twentieths toward the ink, to
      // 4.5:1 on the day paper (the raw red reads 4.2:1 there).
      expect(
        t.over,
        Color.lerp(const Color(0xFFC9402A), const Color(0xFF141A1F), 3 / 20),
      );
      expect(t.dangerSubtle, const Color(0xFFF6DFD6)); // --red-wash
      expect(t.border, const Color.fromRGBO(20, 26, 31, .14)); // --rule
      expect(t.hairline, const Color.fromRGBO(20, 26, 31, .08)); // --rule-2
      expect(t.accentRule, const Color.fromRGBO(30, 90, 68, .35));
      expect(t.headRule, t.textPrimary);
      // The source frosts them at 82% and 84%; Ledger lays them opaque.
      expect(t.topBarFill, const Color.fromRGBO(242, 237, 227, 1));
      expect(t.tabBarFill, const Color.fromRGBO(249, 246, 240, 1));
      expect(t.overlay, const Color.fromRGBO(20, 26, 31, .44));
      expect(t.moneyInCents, t.moneyIn.withValues(alpha: .72));
      expect(t.overCents, t.over.withValues(alpha: .72));
      expect(t.move, t.textTertiary);
      expect(t.moveCents, t.textFaint);
      expect(t.sheetRadius, 6); // --r-sheet
    });

    test('quire dark is designed: the book by lamplight', () {
      final light = LedgerThemeData.preset('quire', Brightness.light);
      final t = LedgerThemeData.preset('quire', Brightness.dark);
      // The papers stay warm paper, not the day's cool ink.
      expect(t.background, const Color(0xFF1A1815));
      expect(t.surface, const Color(0xFF22201C));
      expect(t.surfaceAlt, const Color(0xFF13120F));
      expect(t.textPrimary, const Color(0xFFEEE8DC));
      for (final paper in [t.background, t.surface, t.surfaceAlt]) {
        expect(paper.r, greaterThan(paper.b), reason: 'a warm paper');
      }
      expect(t.background, isNot(light.textPrimary));
      // One jade for the act, the seal and money in, with the paper's ink
      // on the act.
      expect(t.accent, const Color(0xFF6FAA8C));
      expect(t.seal, t.accent);
      expect(t.moneyIn, t.accent);
      expect(t.onAccent, t.surfaceAlt);
      // The toast is a raised slip, never a bright inverse slab.
      expect(t.toast, isNot(t.surfaceInverse));
      expect(
        t.toast.computeLuminance(),
        lessThan(t.textPrimary.computeLuminance()),
      );
      // The rules keep their alphas in the night ink.
      expect(t.border.a, closeTo(light.border.a, 1e-9));
      expect(t.hairline.a, closeTo(light.hairline.a, 1e-9));
      // The cents veil is the source's.
      expect(t.moneyInCents.a, closeTo(.72, 1e-9));
    });

    test('quire carries the source size and line of every step', () {
      final t = LedgerThemeData.preset('quire', Brightness.light);
      double line(TextStyle s) => s.fontSize! * s.height!;
      final steps = <String, (TextStyle, double, double)>{
        'figure': (t.figure, 88, 88 * .84), // .fig 88px/.84
        'figureMedium': (t.figureMedium, 44, 44 * .84), // .fig-m
        'figureSmall': (t.figureSmall, 28, 30), // .fig-s 28px/30px
        'title': (t.title, 30, 33), // .title-l 30px/1.1
        'barTitle': (t.barTitle, 24, 24), // .topbar-title 24px/1
        'sheetTitle': (t.sheetTitle, 28, 30), // .sheet-title 28px/30px
        'wordmark': (t.wordmark, 28, 28), // .brand-word 28px/1
        'body': (t.body, 15, 15 * 1.45), // body 15px/1.45
        'rowTitle': (t.rowTitle, 15, 20), // .title 500 15px/20px
        'bodySmall': (t.bodySmall, 13, 18), // .body-2 13px/18px
        'label': (t.label, 11, 16), // .label 600 11px/16px
        'meta': (t.meta, 11, 16), // .meta 400 11px/16px mono
        'amount': (t.amount, 14, 20), // .amt 500 14px/20px mono
        'tab': (t.tab, 11, 12), // .tab 500 11px/12px
        'toastText': (t.toastText, 15, 20), // .toast-t 500 15px/20px
      };
      steps.forEach((name, step) {
        expect(step.$1.fontSize, step.$2, reason: '$name size');
        expect(line(step.$1), closeTo(step.$3, 0.001), reason: '$name line');
      });
      expect(t.label.fontWeight, FontWeight.w600);
      expect(t.amount.fontWeight, FontWeight.w500);
      expect(t.figure.fontWeight, FontWeight.w400);
      // Tracking in em of each step's size.
      expect(t.figure.letterSpacing, closeTo(88 * -.012, 1e-9));
      expect(t.label.letterSpacing, closeTo(11 * .14, 1e-9));
      expect(t.meta.letterSpacing, closeTo(11 * .04, 1e-9));
      expect(t.amount.letterSpacing, closeTo(14 * -.02, 1e-9));
      // The source sets no tabular figures: the mono is tabular by nature
      // and the serif keeps its own.
      expect(t.amount.fontFeatures, isNull);
      expect(t.figure.fontFeatures, isNull);
      // CSS's half-leading: the line's room splits evenly over and under.
      expect(t.figure.leadingDistribution, TextLeadingDistribution.even);
    });

    test("terracotta is Cody's paper, baked, through the same roles", () {
      final fromTokens = LedgerThemeData.fromTokens(
        'terracotta',
        paperTokens,
        Brightness.light,
      );
      final preset = LedgerThemeData.preset('terracotta', Brightness.light);
      expect(preset.background, fromTokens.background);
      expect(preset.background, paperTokens.light.background);
      expect(preset.accent, fromTokens.accent);
      expect(preset.cardRadius, fromTokens.cardRadius);
      expect(
        preset.background,
        isNot(LedgerThemeData.preset('quire', Brightness.light).background),
      );
      // The figure follows the tokens' giant step; the faces stay Ledger's.
      expect(preset.figure.fontSize, paperTokens.giant.size);
      expect(preset.figure.fontFamily, ledgerFontFamily('InstrumentSerif'));
    });

    test('terracotta keeps its steps in order, largest first', () {
      final t = LedgerThemeData.preset('terracotta', Brightness.light);
      final sizes = [
        t.figure, t.figureMedium, t.title, t.rowTitle, t.amount, t.label, //
      ].map((s) => s.fontSize!).toList();
      expect(sizes, [...sizes]..sort((a, b) => b.compareTo(a)));
    });

    test('a tone inks an amount and its cents', () {
      final t = LedgerThemeData.preset('quire', Brightness.light);
      expect(t.inks(LedgerTone.plain), (
        ink: t.textPrimary,
        cents: t.textTertiary,
      ));
      expect(t.inks(LedgerTone.moneyIn), (
        ink: t.moneyIn,
        cents: t.moneyInCents,
      ));
      expect(t.inks(LedgerTone.over), (ink: t.over, cents: t.overCents));
      expect(t.inks(LedgerTone.move), (ink: t.move, cents: t.moveCents));
    });
  });

  group('LedgerFormat', () {
    final now = DateTime(2026, 10, 28, 19, 40);

    test('money reads as the pilot writes it', () {
      final parts = LedgerFormat.moneyParts(-1326.44);
      expect(parts.sign, '−');
      expect(parts.whole, '1,326');
      expect(parts.cents, '44');
      expect(LedgerFormat.moneyParts(3412.5, showSign: true).sign, '+');
      expect(LedgerFormat.money(6248.30), '\$6,248.30');
      expect(LedgerFormat.money(-1326.44), '−\$1,326.44');
      expect(LedgerFormat.money(3412.5, showSign: true), '+\$3,412.50');
      expect(LedgerFormat.money(2700.4, showCents: false), '\$2,700');
      // A zero carries no sign.
      expect(LedgerFormat.money(0, showSign: true), '\$0.00');
      expect(LedgerFormat.money(-0.001), '\$0.00');
    });

    test('whole dollars round half to even', () {
      expect(LedgerFormat.wholeDollars(2.5), 2);
      expect(LedgerFormat.wholeDollars(3.5), 4);
      expect(LedgerFormat.wholeDollars(2.51), 3);
      expect(LedgerFormat.wholeDollars(-84.25), 84);
    });

    test('days and times read as the pilot writes them', () {
      expect(LedgerFormat.day(DateTime(2026, 10, 28, 8), now: now), 'Today');
      expect(LedgerFormat.day(DateTime(2026, 10, 27), now: now), 'Yesterday');
      expect(LedgerFormat.day(DateTime(2026, 10, 26), now: now), 'Mon, Oct 26');
      expect(
        LedgerFormat.day(DateTime(2025, 12, 31), now: now),
        'Wed, Dec 31, 2025',
      );
      expect(LedgerFormat.date(DateTime(2026, 11, 1)), 'Nov 1');
      expect(
        LedgerFormat.date(DateTime(2026, 11, 1), showWeekday: true),
        'Sun, Nov 1',
      );
      expect(
        LedgerFormat.date(DateTime(2026, 11, 1), showYear: true),
        'Nov 1, 2026',
      );
      expect(
        LedgerFormat.longDate(DateTime(2026, 10, 28)),
        'Wednesday, October 28, 2026',
      );
      expect(LedgerFormat.month(now), 'October');
      expect(LedgerFormat.month(now, short: true), 'Oct');
      expect(LedgerFormat.month(now, showYear: true), 'October 2026');
      expect(LedgerFormat.time(DateTime(2026, 10, 28, 8, 12)), '8:12 AM');
      expect(LedgerFormat.time(now), '7:40 PM');
      expect(LedgerFormat.time(DateTime(2026, 10, 28, 0, 5)), '12:05 AM');
      expect(LedgerFormat.time(DateTime(2026, 10, 28, 12)), '12:00 PM');
    });

    test("the masthead's date lines", () {
      // today_meta and now_meta.
      expect(LedgerFormat.today(now), 'Wednesday, October 28');
      expect(LedgerFormat.nowLabel(now), 'Wednesday, October 28 · 7:40 PM');
    });

    test('the days ahead count calendar days', () {
      expect(LedgerFormat.daysUntil(DateTime(2026, 11, 1), now: now), 4);
      expect(
        LedgerFormat.inDays(DateTime(2026, 10, 28, 23), now: now),
        'Today',
      );
      expect(LedgerFormat.inDays(DateTime(2026, 10, 29), now: now), 'Tomorrow');
      expect(LedgerFormat.inDays(DateTime(2026, 11, 1), now: now), 'In 4 days');
    });

    test('the greeting follows the hour', () {
      String at(int hour) =>
          LedgerFormat.greeting('Maren', now: DateTime(2026, 10, 28, hour));
      expect(at(9), 'Good morning, Maren');
      expect(at(13), 'Good afternoon, Maren');
      expect(at(19), 'Good evening, Maren');
    });

    test('monograms, shares and counts', () {
      expect(LedgerFormat.initials('Blue Fern Café'), 'BF');
      expect(LedgerFormat.initials('Cloudbox'), 'CL');
      expect(LedgerFormat.initials('H&M'), 'HM');
      expect(LedgerFormat.initials(''), '');
      expect(LedgerFormat.percent(2840, 4000), 71);
      expect(LedgerFormat.count(14880), '14,880');
      expect(LedgerFormat.plural(1, 'bill'), '1 bill');
      expect(LedgerFormat.plural(3, 'bill'), '3 bills');
      expect(LedgerFormat.plural(2, 'category', 'categories'), '2 categories');
    });
  });

  // An app with no Material words (a WidgetsApp, a CupertinoApp) gets
  // Ledger's own Localizations, which set the direction from their locale:
  // the app's right to left reset to left to right on every page.
  testWidgets('keeps the right to left it stands in under its own words', (
    t,
  ) async {
    late TextDirection seen;
    await t.pumpWidget(
      Localizations(
        locale: const Locale('en', 'US'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LedgerTheme(
            data: LedgerThemeData.light(),
            child: Builder(
              builder: (context) {
                seen = Directionality.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    expect(seen, TextDirection.rtl);
  });

  // Ledger supplies English Material words only where the app has none: a
  // translation the app gives stands under it.
  testWidgets("keeps an app's own Material words; gives English ones where "
      'there are none', (t) async {
    MaterialLocalizations? seen;
    Widget app(Key key, List<LocalizationsDelegate<dynamic>> delegates) =>
        Localizations(
          key: key,
          locale: const Locale('en', 'US'),
          delegates: delegates,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LedgerTheme(
              data: LedgerThemeData.light(),
              child: Builder(
                builder: (context) {
                  seen = Localizations.of<MaterialLocalizations>(
                    context,
                    MaterialLocalizations,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
    await t.pumpWidget(
      app(const ValueKey('own'), const [
        DefaultWidgetsLocalizations.delegate,
        _OwnWords.delegate,
      ]),
    );
    expect(seen, isA<_OwnWords>());
    await t.pumpWidget(
      app(const ValueKey('none'), const [DefaultWidgetsLocalizations.delegate]),
    );
    expect(seen, isA<DefaultMaterialLocalizations>());
    expect(seen, isNot(isA<_OwnWords>()));
  });
}

/// An app's own Material words: a translated Cancel.
class _OwnWords extends DefaultMaterialLocalizations {
  const _OwnWords();

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _OwnWordsDelegate();

  @override
  String get cancelButtonLabel => 'Abbrechen';
}

class _OwnWordsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _OwnWordsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(const _OwnWords());

  @override
  bool shouldReload(_OwnWordsDelegate old) => false;
}
