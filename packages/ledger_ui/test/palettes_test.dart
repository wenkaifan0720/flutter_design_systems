// Ledger's palettes: six presets, each read by day and by lamplight, and an app's own colours through
// LedgerThemeData.from, whose night is the same book turned (a dark paper in the paper's hue, its cream for the ink, the
// accent at the nearest tone that reads), with any of the three given instead.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _paper = Color(0xFFF4EFE6);
const _ink = Color(0xFF1F2A2E);
const _accent = Color(0xFF2F6B4F);

LedgerThemeData _from(
  Brightness? b, {
  Color? nightPaper,
  Color? nightInk,
  Color? nightAccent,
}) => LedgerThemeData.from(
  paper: _paper,
  ink: _ink,
  accent: _accent,
  brightness: b,
  nightPaper: nightPaper,
  nightInk: nightInk,
  nightAccent: nightAccent,
);

/// Every ink that sets words, on every paper it is set on, at 4.5:1: the third ink (the meta lines) on the page and
/// its slips, the others on the sunken paper too.
void _expectReads(LedgerThemeData t) {
  for (final ground in [t.background, t.surface, t.surfaceAlt]) {
    for (final (name, ink) in [
      ('textPrimary', t.textPrimary),
      ('textSecondary', t.textSecondary),
      if (ground != t.surfaceAlt) ('textTertiary', t.textTertiary),
      ('accentText', t.accentText),
      ('moneyIn', t.moneyIn),
      ('over', t.over),
    ]) {
      expect(
        RawPalette.contrastRatio(ink, ground),
        greaterThanOrEqualTo(4.5),
        reason: '${t.id} ${t.brightness.name} $name on $ground',
      );
    }
  }
  for (final (name, ink, ground) in [
    ('onAccent on accent', t.onAccent, t.accent),
    ('onToast on toast', t.onToast, t.toast),
    ('onToastAction on toast', t.onToastAction, t.toast),
  ]) {
    expect(
      RawPalette.contrastRatio(ink, ground),
      greaterThanOrEqualTo(4.5),
      reason: '${t.id} ${t.brightness.name} $name',
    );
  }
}

void main() {
  test('six presets, the source first', () {
    expect(LedgerThemeData.presets, hasLength(6));
    expect(LedgerThemeData.presets.first, 'quire');
    expect(LedgerThemeData.presets.toSet(), hasLength(6));
    for (final id in LedgerThemeData.presets) {
      for (final b in Brightness.values) {
        final t = LedgerThemeData.preset(id, b);
        expect(t.brightness, b);
        expect(
          t.background.computeLuminance() < t.textPrimary.computeLuminance(),
          b == Brightness.dark,
          reason: '$id ${b.name}: a night paper under a light ink',
        );
        _expectReads(t);
      }
    }
  });

  test(
    "from()'s night is a dark paper in the paper's hue, its words reading",
    () {
      final day = _from(Brightness.light);
      final night = _from(Brightness.dark);
      expect(night.brightness, Brightness.dark);
      expect(night.background.computeLuminance(), lessThan(.02));
      expect(night.textPrimary.computeLuminance(), greaterThan(.7));
      // The paper's hue, its chroma held low: a cream page's night is a warm charcoal.
      final paperHue = RawHct.fromColor(_paper).hue;
      final nightHue = RawHct.fromColor(night.background).hue;
      final apart = ((paperHue - nightHue + 540) % 360) - 180;
      expect(apart.abs(), lessThan(25));
      // The accent's own hue, at a tone that reads on the night papers.
      final accentApart =
          ((RawHct.fromColor(_accent).hue -
                  RawHct.fromColor(night.accentText).hue +
                  540) %
              360) -
          180;
      expect(accentApart.abs(), lessThan(12));
      _expectReads(day);
      _expectReads(night);
    },
  );

  test('a night book given as such stays as given, and turns to its day', () {
    final night = LedgerThemeData.from(
      paper: const Color(0xFF1A1815),
      ink: const Color(0xFFEEE8DC),
      accent: const Color(0xFF6FAA8C),
    );
    expect(night.brightness, Brightness.dark);
    expect(night.background, const Color(0xFF1A1815));
    final day = LedgerThemeData.from(
      paper: const Color(0xFF1A1815),
      ink: const Color(0xFFEEE8DC),
      accent: const Color(0xFF6FAA8C),
      brightness: Brightness.light,
    );
    expect(day.brightness, Brightness.light);
    expect(day.background.computeLuminance(), greaterThan(.8));
    _expectReads(night);
    _expectReads(day);
  });

  test(
    'a night paper, ink or accent given takes the place of the derived one',
    () {
      const navy = Color(0xFF131A23);
      const ivory = Color(0xFFEAE6DC);
      const sea = Color(0xFF8DC6A8);
      final night = _from(
        Brightness.dark,
        nightPaper: navy,
        nightInk: ivory,
        nightAccent: sea,
      );
      expect(night.background, navy);
      expect(night.textPrimary, ivory);
      expect(night.accent, sea);
      // By day they are not read.
      expect(_from(Brightness.light, nightPaper: navy).background, _paper);
    },
  );

  test("an ink that doesn't stand off its paper takes the book's own ink in its hue", () {
    // A brand's black paper with the house's slate ink (1.07:1), and a white
    // paper with a pale grey ink, in both appearances.
    for (final (paper, ink) in const [
      (Color(0xFF111111), Color(0xFF141A1F)),
      (Color(0xFFFFFFFF), Color(0xFFE6E6E6)),
    ]) {
      for (final b in Brightness.values) {
        final t = LedgerThemeData.from(
          paper: paper,
          ink: ink,
          accent: const Color(0xFFC9A227),
          brightness: b,
        );
        expect(
          RawPalette.contrastRatio(t.textPrimary, t.background),
          greaterThanOrEqualTo(7),
          reason: '$paper, $ink, $b',
        );
        _expectReads(t);
      }
    }
    // An ink that reads is the given one.
    expect(_from(Brightness.light).textPrimary, _ink);
  });

  test("from()'s raised paper stands half way to white by day, as the quire's does", () {
    final day = _from(Brightness.light);
    expect(day.surface, Color.lerp(_paper, const Color(0xFFFFFFFF), .5));
    // By lamplight it is the paper a step toward the ink.
    final night = _from(Brightness.dark);
    expect(night.surface, Color.lerp(night.background, night.textPrimary, .06));
  });

  test("from()'s second ink stands darker than its third by day, lighter by lamplight", () {
    final day = _from(Brightness.light);
    final night = _from(Brightness.dark);
    double lum(Color c) => c.computeLuminance();
    expect(lum(day.textSecondary), lessThan(lum(day.textTertiary)));
    expect(lum(night.textSecondary), greaterThan(lum(night.textTertiary)));
  });
}
