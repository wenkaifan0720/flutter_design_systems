import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';

/// Which ink a [LedgerSeal] is pressed in.
enum LedgerSealTone {
  /// Green, 7° off square: a goal met, a payment made.
  success,

  /// Vermilion, 6° the other way, its middle line larger: over budget.
  over,

  /// The second ink, 5° off square, its middle line larger: a blank page.
  plain,
}

/// How large a [LedgerSeal] is pressed, on a phone and on the desktop, as
/// the source sizes `.seal` where it stands.
enum LedgerSealSize {
  /// 112, 120 on the desktop: a section's verdict, an empty page's.
  regular(LedgerChromeMetrics.seal, 120),

  /// 104, 132 on the desktop: a receipt's, beside its figure.
  receipt(104, 132),

  /// 92: a memo slip's.
  memo(92, 92),

  /// 128, 150 on the desktop, its middle line larger: a sent transfer's
  /// stamp across its page.
  stamp(128, 150),

  /// 96, 112 on the desktop: the member's card on the profile.
  member(96, 112);

  const LedgerSealSize(this.phone, this.desk);

  /// Its round on a phone.
  final double phone;

  /// Its round from 1024.
  final double desk;
}

/// The seal: a milled-edge stamp pressed slightly off square, as the
/// source's `seal` draws it, 112 round: a fine ring, 96 milled ticks, two
/// rings inside (the inner one dotted), a wash of its ink fading to the
/// rim, and three lines stamped in it: the [kicker] in tracked capitals,
/// the [value] in the italic serif (a line break allowed), the [foot] in
/// the mono. Pressed into the paper (multiplied), so the paper's grain
/// shows through. [size] presses it larger or smaller (its art scales, its
/// lines keep their type). Read aloud as its three lines.
///
/// ```dart
/// LedgerSeal(kicker: 'Search', value: 'No\nentries', foot: 'October', tone: LedgerSealTone.plain)
/// ```
class LedgerSeal extends StatelessWidget {
  /// A seal stamped [kicker], [value] and [foot].
  const LedgerSeal({
    required this.kicker,
    required this.value,
    required this.foot,
    this.tone = LedgerSealTone.success,
    this.size = LedgerSealSize.regular,
    super.key,
  });

  /// The top line, in tracked capitals.
  final String kicker;

  /// The middle line, in the italic serif; may break once.
  final String value;

  /// The bottom line, in the mono.
  final String foot;

  /// Its ink.
  final LedgerSealTone tone;

  /// How large it is pressed.
  final LedgerSealSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final (ink, turn, wash) = switch (tone) {
      LedgerSealTone.success => (
        t.seal,
        LedgerChromeMetrics.sealTurn,
        _greenWash,
      ),
      LedgerSealTone.over => (
        t.sealOver,
        LedgerChromeMetrics.sealTurnOver,
        _greenWash,
      ),
      LedgerSealTone.plain => (
        t.sealInk,
        LedgerChromeMetrics.sealTurnInk,
        _inkWash,
      ),
    };
    // Pressed into the paper: each line laid over what is under it in the
    // paper's own press ([LedgerThemeData.pressBlend]). A copy, so the face
    // keeps its package: a style rebuilt from `fontFamily` alone, merged
    // onto the host's, took the package a second time
    // (`packages/ledger_ui/packages/ledger_ui/InterTight`) and fell back.
    TextStyle pressed(TextStyle s) => s.copyWith(
      foreground: Paint()
        ..color = ink
        ..blendMode = t.pressBlend,
    );
    // The over and ink seals set their middle line larger, as the stamp
    // does (`.seal-big`); the desktop's green seal sets it 21 on 19.
    final wide = LedgerLayout.isWide(context);
    final stamp = size == LedgerSealSize.stamp;
    final big = tone != LedgerSealTone.success || stamp;
    final valueStyle = pressed(
      t.figureSmall
          .sized(big ? _valueBig : (wide ? _valueWide : _value))
          .line(switch (tone) {
            LedgerSealTone.success when stamp => _valueLineInk,
            LedgerSealTone.success => wide ? _valueLineWide : _valueLine,
            LedgerSealTone.over => _valueLineOver,
            LedgerSealTone.plain => _valueLineInk,
          })
          .tracked(0)
          .italic,
    );
    final kickerStyle = pressed(
      t.label.sized(_kicker).line(_smallLine).tracked(_kickerTracking),
    );
    final footStyle = pressed(
      t.amount.sized(_foot).line(_smallLine).tracked(_footTracking),
    );
    return Semantics(
      label: '$kicker, ${value.replaceAll('\n', ' ')}, $foot',
      excludeSemantics: true,
      child: Transform.rotate(
        angle: turn * math.pi / 180,
        child: SizedBox.square(
          dimension: wide ? size.desk : size.phone,
          child: CustomPaint(
            painter: _SealPainter(ink, wash, t.pressBlend),
            // The lettering is cut into the engraving at its size, as a
            // monogram's is: the reader's text size would run it into the
            // rim. A screen reader reads it whole, and its page says it in
            // words too.
            child: MediaQuery.withNoTextScaling(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kicker.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: kickerStyle,
                  ),
                  const SizedBox(height: _valueTop),
                  Text(value, textAlign: TextAlign.center, style: valueStyle),
                  const SizedBox(height: _valueFoot),
                  // Its foot is a figure or a date: left to right in any
                  // page ("+$36.40"), as a card face's printing is.
                  Text(
                    foot,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: footStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // `.seal-k`: 600 7.5/10, .2em; `.seal-v`: italic 19/17, margin 4 0 3
  // (24/20 over, 24/21 ink); `.seal-s`: 500 8.5/10 mono, .04em.
  static const double _kicker = 7.5;
  static const double _kickerTracking = .2;
  static const double _smallLine = 10;
  static const double _value = 19;
  static const double _valueBig = 24;
  static const double _valueLine = 17;
  static const double _valueWide = 21;
  static const double _valueLineWide = 19;
  static const double _valueLineOver = 20;
  static const double _valueLineInk = 21;
  static const double _valueTop = 4;
  static const double _valueFoot = 3;
  static const double _foot = 8.5;
  static const double _footTracking = .04;

  // The wash: radial-gradient(circle, ink .12 0%, ink .05 72%, ink 0 73%)
  // (the ink seal's .08 and .03).
  static const (double, double) _greenWash = (.12, .05);
  static const (double, double) _inkWash = (.08, .03);
}

/// The seal's engraving (`seal_art`, on its 120 grid) and its wash.
class _SealPainter extends CustomPainter {
  _SealPainter(this.ink, this.wash, this.press);

  final Color ink;
  final (double, double) wash;
  final BlendMode press;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);
    // CSS sizes a circle gradient to the farthest corner of its box.
    final reach = r * math.sqrt2;
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..blendMode = press
        ..shader = RadialGradient(
          colors: [
            ink.withValues(alpha: wash.$1),
            ink.withValues(alpha: wash.$2),
            ink.withValues(alpha: 0),
          ],
          stops: const [0, .72, .73],
        ).createShader(Rect.fromCircle(center: centre, radius: reach)),
    );
    canvas.save();
    canvas.scale(size.width / 120);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink
      ..blendMode = press;
    const c = Offset(60, 60);
    canvas.drawCircle(c, 58.5, line..strokeWidth = 1.3);
    final ticks = Path();
    for (var k = 0; k < 96; k++) {
      final a = 2 * math.pi * k / 96;
      final d = Offset(math.cos(a), math.sin(a));
      ticks
        ..moveTo(60 + 51.5 * d.dx, 60 + 51.5 * d.dy)
        ..lineTo(60 + 56 * d.dx, 60 + 56 * d.dy);
    }
    canvas.drawPath(ticks, line..strokeWidth = .7);
    canvas.drawCircle(c, 49, line..strokeWidth = .9);
    // The dotted ring: dashes of 1 every 3.2 round from its east point.
    const ring = 45.5;
    final dots = Path();
    final around = 2 * math.pi * ring;
    for (var d = 0.0; d < around; d += 3.2) {
      dots.addArc(
        Rect.fromCircle(center: c, radius: ring),
        d / ring,
        math.min(1, around - d) / ring,
      );
    }
    canvas.drawPath(dots, line..strokeWidth = .5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SealPainter old) =>
      old.ink != ink || old.wash != wash || old.press != press;
}
