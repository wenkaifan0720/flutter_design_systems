/// Frosted's cards: the pearl credit card with its orbits, glow and frost,
/// the debit card, a card's number for the person alone, a goal's card and
/// row, the new-goal card, and the mosaic of tinted panes.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/css_gradient.dart';
import '../../internal/css_shadow.dart';
import '../../internal/ellipse.dart';
import '../../internal/face.dart';
import '../../internal/measure.dart';
import '../wordmark/wordmark.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../meters/meters.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../structure/structure.dart';
import '../../localizations.dart';

// The geometry the CSS names in place; its whites, the debit card's blue and
// the frost are the theme's sheens (FrostedSheens), so the dark appearance has
// its own.
// metric: the card's specular band at 46% between nothing at 32 and 60%,
// 118deg (`.kcard`); the debit card's at 46% between 30 and 62%; a wide
// pane's at 50% between 34 and 66%, 122deg.
const List<double> _specularStops = [0.32, 0.46, 0.6];
const double _specularAngle = 118;
const List<double> _debitSpecularStops = [0.3, 0.46, 0.62];
const List<double> _paneSpecularStops = [0.34, 0.5, 0.66];
const double _paneSpecularAngle = 122;
// metric: the pearl's base runs at 135deg, its rim and glow at 120deg.
const double _pearlAngle = 135;
const double _rimAngle = 120;
// metric: the blush inside the rings, 90% x 120% at the top end corner,
// gone at 60% (`.kcard` radial).
const double _blushEnd = 0.6;
// metric: the frost's streaks one px wide every 23 at 118deg; its haze at
// the centre, 70% x 90%; its wash at 160deg, stops at 0, 55% and 100%; its
// inner glow 32 in (`.frost`).
const double _frostStreakPeriod = 23;
const double _frostStreakWidth = 1;
const List<double> _frostWashStops = [0, 0.55, 1];
const double _frostWashAngle = 160;
const double _frostGlowBlur = 32;
// metric: the orbits' SVG: a 360 box, rings at 66/104/142/179 round its
// centre, stroke 1 of 8D96EB to E592B6 to 6FBFDC along (40,40)-(320,320),
// at .42/.34/.26/.18 (`.kcard-orbits`).
const double _orbitsBox = 360;
const List<double> _orbitRadii = [66, 104, 142, 179];
const List<double> _orbitOpacities = [0.42, 0.34, 0.26, 0.18];
const List<Color> _orbitStops = [
  Color(0xFF8D96EB),
  Color(0xFFE592B6),
  Color(0xFF6FBFDC),
];
const double _orbitLineFrom = 40;
const double _orbitLineTo = 320;
// metric: the glow stands at .7 (`.kc-glow`).
const double _glowOpacity = 0.7;
// metric: a pane's haze at its top start corner, 120% x 70%, gone at 70%
// (`.cell` radial); its share at .72 and its meta at .8.
const double _paneHazeEnd = 0.7;
const double _paneShareOpacity = 0.72;
const double _paneMetaOpacity = 0.8;

/// The pane head's line (`.cell-n`, `.cell-p`: 12/1.25).
const double _paneHeadLine = 15;
// metric: the new-goal card's inset ring is the CSS's 1.5 drawn 1
// (`.new-goal`).
// metric: the sheet form's gap between the number's well and its facts
// (`.sheet-b--form`).
const double _numberFactsTop = 16;
// metric: the facts' columns, 1 : 1 : 1.6 (`.cnum-3`).
const List<int> _numberFactFlex = [10, 10, 16];
// metric: the width a card lays itself across when its parent sets none.
const double _looseWidth = 320;
// metric: from 600 up (design6 P) a card is at most as wide as on the
// source's desktop Home (`.kc` 464 at 1440 less its 28 each side), rather
// than drawn across a page. 400 stood Facet's Home card 8 short of `.kcard
// { width: 100% }`.
const double _cardWide = 408;

// The narrowest the credit card's face lays its words out in: a phone's
// card (390 less its gutters). On the desktop's 300 stage the face is drawn
// at this size and its picture scaled down.
const double _stageFaceWidth = 358;
const Color _black = Color(0xFF000000);

/// A single line of words that clips instead of wrapping.
Widget _line(String text, TextStyle style, {TextAlign? align}) => Text(
  text,
  style: style,
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.clip,
  textAlign: align,
);

/// A CSS specular band: nothing, [color], nothing at [stops], at [angle].
LinearGradient _band(Color color, List<double> stops, double angle) =>
    LinearGradient(
      colors: [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
      stops: stops,
      transform: FrostedCssAngle(angle),
    );

/// A CSS radial of [color] fading to nothing at [end], [rx] x [ry] of the
/// box round ([cx], [cy]).
RadialGradient _radial(
  Color color, {
  required double rx,
  required double ry,
  required double cx,
  required double cy,
  required double end,
}) {
  final ellipse = FrostedEllipse(rx: rx, ry: ry, cx: cx, cy: cy);
  return RadialGradient(
    center: ellipse.center,
    radius: 1,
    colors: [color, color.withValues(alpha: 0)],
    stops: [0, end],
    transform: ellipse,
  );
}

// ---------------------------------------------------------------------------
// The pearl credit card
// ---------------------------------------------------------------------------

/// A credit card as a pearl: one cool base, a blush inside its
/// orbits, a specular band, the spectrum on its 1px rim, the glass behind
/// it blurred, standing over its glow; the brand and its kind at the top,
/// the balance against the limit in the middle, the last four and the
/// autopay pill at its foot. The desktop turns it 4deg on its stage;
/// [frozen] lays the frost over it. One per page; a link when [onPressed].
///
/// ```dart
/// FrostedCreditCard(balance: 1326.44, limit: 4000, mask: '4821', brand: 'Harbor', note: 'Autopay · due Nov 12', onPressed: openCards)
/// ```
class FrostedCreditCard extends StatelessWidget {
  /// Creates a [FrostedCreditCard].
  const FrostedCreditCard({
    required this.balance,
    required this.limit,
    required this.mask,
    required this.brand,
    this.kind,
    this.balanceLabel,
    this.note,
    this.noteIcon = FrostedGlyphs.zap,
    this.frozen = false,
    this.stage = false,
    this.onPressed,
    this.label,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// What is owed.
  final num balance;

  /// The card's limit.
  final num limit;

  /// The card's last four.
  final String mask;

  /// The brand's word beside the mark.
  final String brand;

  /// The pill at the top end: the card's kind.
  final String? kind;

  /// The caption over the balance.
  final String? balanceLabel;

  /// The pill at the foot: how it is paid and when it is due.
  final String? note;

  /// The foot pill's glyph.
  final IconData noteIcon;

  /// Whether the card is frozen: the frost over it.
  final bool frozen;

  /// Whether the card stands on the Cards page's stage (300 wide on the
  /// desktop) rather than across Home.
  final bool stage;

  /// Opens the card's page; null makes the card inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// What a screen reader says; the card, its balance and limit when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final kind = this.kind ?? FrostedLocalizations.of(context).credit;
    final balanceLabel =
        this.balanceLabel ?? FrostedLocalizations.of(context).balance;
    final wide = FrostedBreakpoints.isWide(context);
    // From 600 up the card keeps a card's size (at most 408 wide).
    final measured = MediaQuery.sizeOf(context).width >= frostedMeasureFrom;
    final radius = wide
        ? FrostedChromeMetrics.cardRadiusWide
        : FrostedChromeMetrics.cardRadius;
    final words =
        label ??
        '${frozen ? 'Frozen card' : 'Card'} ·· $mask, '
            '$balanceLabel ${FrostedFormat.money(balance)} of '
            '${FrostedFormat.money(limit, cents: limit % 1 != 0)} limit'
            '${note == null ? '' : ', $note'}';
    Widget card = LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _looseWidth;
        final width = measured ? math.min(room, _cardWide) : room;
        final face = _CardFace(
          radius: radius,
          frozen: frozen,
          brand: brand,
          kind: kind,
          balanceLabel: balanceLabel,
          balance: balance,
          limit: limit,
          mask: mask,
          note: note,
          noteIcon: noteIcon,
        );
        if (stage && width < _stageFaceWidth) {
          // The stage is narrower than the face can lay its words out in
          // (the balance ran into the brand, the limit into the last four):
          // the card drawn at a phone card's size, its picture scaled down.
          return SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: FrostedChromeMetrics.cardAspect,
              child: FittedBox(
                child: SizedBox(
                  width: _stageFaceWidth,
                  height: _stageFaceWidth / FrostedChromeMetrics.cardAspect,
                  child: face,
                ),
              ),
            ),
          );
        }
        return SizedBox(
          width: width,
          child: AspectRatio(
            aspectRatio: FrostedChromeMetrics.cardAspect,
            child: face,
          ),
        );
      },
    );
    if (wide) {
      card = Transform.rotate(
        angle: FrostedChromeMetrics.cardTurnWide * math.pi / 180,
        child: card,
      );
    }
    Widget body = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: wide
                ? FrostedChromeMetrics.cardGlowWide
                : FrostedChromeMetrics.cardGlow,
            child: const FrostedCardGlow(),
          ),
        ),
        card,
      ],
    );
    if (wide) {
      body = Padding(
        padding: stage
            ? FrostedChromeMetrics.cardStageCards
            : FrostedChromeMetrics.cardStageWide,
        // Across Home, `.kc { display: grid; place-items: center }`: the
        // card in the middle of what its row gives it, not at its top.
        child: stage ? body : Center(child: body),
      );
      if (stage) {
        body = Center(
          child: SizedBox(
            width: FrostedChromeMetrics.cardStageWidth,
            child: body,
          ),
        );
      }
    }
    body = MediaQuery.withNoTextScaling(child: body);
    final Widget shown = onPressed == null
        ? Semantics(label: words, excludeSemantics: true, child: body)
        : FrostedPressable(
            focusNode: focusNode,
            autofocus: autofocus,
            onPressed: onPressed,
            label: words,
            role: FrostedPressRole.link,
            radius: radius,
            child: body,
          );
    // From 600 up, below the desktop, the card, its glow and its press
    // stand at the line's start, a card's size.
    if (wide || !measured) return shown;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: shown,
    );
  }
}

/// The pearl itself: its rim, its fills, its orbits, its words and, when
/// frozen, the frost.
class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.radius,
    required this.frozen,
    required this.brand,
    required this.kind,
    required this.balanceLabel,
    required this.balance,
    required this.limit,
    required this.mask,
    required this.note,
    required this.noteIcon,
  });

  final double radius;
  final bool frozen;
  final String brand;
  final String kind;
  final String balanceLabel;
  final num balance;
  final num limit;
  final String mask;
  final String? note;
  final IconData noteIcon;

  @override
  Widget build(BuildContext context) {
    final page = context.frostedTheme;
    // The face's quieter words, its kind's pill among them, take the
    // pearl's own quiet ink: it reads 4.5:1 on the pearl and its blush.
    final t = page.copyWith(
      colorScheme: page.colorScheme.copyWith(
        textSecondary: page.pearl.textSecondary,
      ),
    );
    return FrostedTheme(
      data: t,
      darkData: FrostedTheme.darkOf(context),
      child: _face(context, t),
    );
  }

  Widget _face(BuildContext context, FrostedThemeData t) {
    final wide = FrostedBreakpoints.isWide(context);
    final inset = wide
        ? FrostedChromeMetrics.cardInsetWide
        : FrostedChromeMetrics.cardInset;
    final outer = BorderRadius.circular(radius);
    final inner = BorderRadius.circular(radius - FrostedChromeMetrics.outline);
    final used = limit > 0 ? (balance / limit).clamp(0.0, 1.0) : 0.0;
    final caption = t.textTheme.titleMedium
        .at(14)
        .line(14)
        .c(t.colorScheme.textSecondary);
    // .kcard { display: flex; flex-direction: column; justify-content:
    // space-between }: see _CardRows.
    final content = CustomMultiChildLayout(
      delegate: _CardRows(Directionality.of(context)),
      children: [
        LayoutId(
          id: _CardRow.top,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: FrostedChromeMetrics.cardBrandGap,
                    children: [
                      const FrostedMark(),
                      Text(
                        brand,
                        style: t.textTheme.headlineSmall.display
                            .at(FrostedChromeMetrics.cardBrandType)
                            .line(FrostedChromeMetrics.cardBrandType)
                            .tracked(-0.035),
                      ),
                    ],
                  ),
                ),
              ),
              FrostedTag(kind, variant: FrostedTagVariant.glass),
            ],
          ),
        ),
        LayoutId(
          id: _CardRow.mid,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.cardMidGap,
              children: [
                Text(balanceLabel, style: caption),
                FrostedMoney(balance, size: FrostedMoneySize.regular),
                SizedBox(
                  width: FrostedChromeMetrics.utilWidth,
                  height: FrostedChromeMetrics.utilHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.pearl.usageTrack,
                      borderRadius: BorderRadius.circular(FrostedCorners.rFull),
                    ),
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: used,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: t.pearl.usage,
                          borderRadius: BorderRadius.circular(
                            FrostedCorners.rFull,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('of ', style: caption),
                    FrostedNumberText(
                      FrostedFormat.money(limit, cents: limit % 1 != 0),
                      style: caption,
                    ),
                    Text(' limit', style: caption),
                  ],
                ),
              ],
            ),
          ),
        ),
        LayoutId(
          id: _CardRow.foot,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: FrostedChromeMetrics.cardBrandGap,
            children: [
              Text(
                '•• $mask',
                // The dots before the last four in any language.
                textDirection: TextDirection.ltr,
                style: t.textTheme.amount
                    .line(16)
                    .tracked(FrostedChromeMetrics.cardNumberTracking)
                    .c(t.colorScheme.textSecondary),
              ),
              if (note != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: FrostedTag(
                      note!,
                      icon: noteIcon,
                      variant: FrostedTagVariant.glass,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    final face = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: outer,
        gradient: LinearGradient(
          colors: t.pearl.rim,
          stops: const [0, 0.35, 0.6, 0.82, 1],
          transform: const FrostedCssAngle(_rimAngle),
        ),
        boxShadow: frozen
            ? [
                frostedShadow(
                  color: t.sheens.frozenShade,
                  y: 18,
                  blur: 36,
                  spread: -22,
                ),
              ]
            : t.shadows.pearl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(FrostedChromeMetrics.outline),
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: inner,
          gradients: [
            LinearGradient(
              colors: [t.pearl.from, t.pearl.to],
              transform: const FrostedCssAngle(_pearlAngle),
            ),
            _radial(
              t.pearl.blush,
              rx: 0.9,
              ry: 1.2,
              cx: 1,
              cy: 0,
              end: _blushEnd,
            ),
            _band(t.sheens.specular, _specularStops, _specularAngle),
          ],
          sheen: t.sheens.cardSheen,
          clipChild: true,
          padding: EdgeInsets.all(inset),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                end: FrostedChromeMetrics.cardOrbitsRight - inset,
                top: FrostedChromeMetrics.cardOrbitsTop - inset,
                width: FrostedChromeMetrics.cardOrbits,
                height: FrostedChromeMetrics.cardOrbits,
                child: const FrostedOrbits(),
              ),
              Positioned.fill(child: content),
            ],
          ),
        ),
      ),
    );
    if (!frozen) return face;
    // A frozen card's face is veiled by the frost on purpose: what reads is
    // the frost's mark and word, and the card's label says the rest. The
    // words under it are not read, as the CSS blurs them.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ExcludeSemantics(child: face),
        Positioned.fill(child: FrostedFrost(radius: radius)),
      ],
    );
  }
}

/// The orbits on the pearl credit card: four rings of the
/// spectrum round one centre, fading outward, drawn at the box's size.
///
/// ```dart
/// FrostedOrbits()
/// ```
class FrostedOrbits extends StatelessWidget {
  /// Creates a [FrostedOrbits].
  const FrostedOrbits({super.key});

  @override
  Widget build(BuildContext context) =>
      const ExcludeSemantics(child: CustomPaint(painter: _OrbitsPainter()));
}

class _OrbitsPainter extends CustomPainter {
  const _OrbitsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _orbitsBox;
    final centre = size.center(Offset.zero);
    final shader = LinearGradient(colors: _orbitStops, stops: const [0, 0.5, 1])
        .createShader(
          Rect.fromLTRB(
            _orbitLineFrom * scale,
            _orbitLineFrom * scale,
            _orbitLineTo * scale,
            _orbitLineTo * scale,
          ),
        );
    for (var i = 0; i < _orbitRadii.length; i++) {
      canvas.drawCircle(
        centre,
        _orbitRadii[i] * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = scale
          ..shader = shader
          ..color = _black.withValues(alpha: _orbitOpacities[i]),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitsPainter oldDelegate) => false;
}

/// The glow under the pearl credit card: a pill of the pearl's three
/// lights blurred 36 (44 on the desktop) at .7; fills the box it is given.
///
/// ```dart
/// FrostedCardGlow()
/// ```
class FrostedCardGlow extends StatelessWidget {
  /// Creates a [FrostedCardGlow].
  const FrostedCardGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final blur = FrostedBreakpoints.isWide(context)
        ? FrostedChromeMetrics.cardGlowBlurWide
        : FrostedChromeMetrics.cardGlowBlur;
    return ExcludeSemantics(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: frostedSigma(blur),
          sigmaY: frostedSigma(blur),
          tileMode: TileMode.decal,
        ),
        child: Opacity(
          opacity: _glowOpacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FrostedCorners.rFull),
              gradient: LinearGradient(
                colors: t.pearl.glow,
                stops: const [0, 0.5, 1],
                transform: const FrostedCssAngle(_rimAngle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The frost over a frozen card (`.frost`): a cold wash under a haze and
/// fine streaks, lit inward along its edge, the snowflake on a white round
/// and the word under it in the cold ink. The CSS also blurs what lies
/// under it 5; the frost draws without that blur (DERIVED).
///
/// ```dart
/// FrostedFrost(radius: 16)
/// ```
class FrostedFrost extends StatelessWidget {
  /// Creates a [FrostedFrost].
  const FrostedFrost({
    this.radius = FrostedChromeMetrics.cardRadius,
    this.word,
    this.glyph = FrostedGlyphs.snowflake,
    super.key,
  });

  /// The card's corners, which the frost shares.
  final double radius;

  /// The word under the mark.
  final String? word;

  /// The mark's glyph.
  final IconData glyph;

  @override
  Widget build(BuildContext context) {
    final word = this.word ?? FrostedLocalizations.of(context).frozen;
    final t = context.frostedTheme;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _FrostPainter(radius: radius, sheens: t.sheens),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedChromeMetrics.frostGap,
              children: [
                SizedBox(
                  width: FrostedChromeMetrics.frostMark,
                  height: FrostedChromeMetrics.frostMark,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.sheens.frostMarkFill,
                      boxShadow: [
                        BoxShadow(
                          color: t.sheens.frostMarkRing,
                          spreadRadius: FrostedChromeMetrics.outline,
                        ),
                        frostedShadow(
                          color: t.sheens.frostMarkShade,
                          y: 8,
                          blur: 18,
                          spread: -10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        glyph,
                        size: FrostedChromeMetrics.frostMarkGlyph,
                        color: t.colorScheme.cold,
                      ),
                    ),
                  ),
                ),
                Text(
                  word,
                  style: t.textTheme.labelLarge.display
                      .tracked(0.02)
                      .c(t.colorScheme.cold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostPainter extends CustomPainter {
  const _FrostPainter({required this.radius, required this.sheens});

  final double radius;
  final FrostedSheens sheens;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    // The wash, then the haze, then the streaks: CSS lists them top first.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          colors: sheens.frostWash,
          stops: _frostWashStops,
          transform: FrostedCssAngle(_frostWashAngle),
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = _radial(
          sheens.frostHaze,
          rx: 0.7,
          ry: 0.9,
          cx: 0.5,
          cy: 0.5,
          end: 1,
        ).createShader(rect),
    );
    final a = _specularAngle * math.pi / 180;
    final along = Offset(math.sin(a), -math.cos(a)) * _frostStreakPeriod;
    final centre = rect.center;
    const clear = Color(0x00FFFFFF);
    final cut = (_frostStreakPeriod - _frostStreakWidth) / _frostStreakPeriod;
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          centre,
          centre + along,
          [clear, clear, sheens.frostStreak, sheens.frostStreak],
          [0, cut, cut, 1],
          TileMode.repeated,
        ),
    );
    // The inward glow: a wide blurred stroke outside the box, clipped to it.
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(
      rrect.inflate(_frostGlowBlur),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _frostGlowBlur * 2
        ..color = sheens.frostGlow
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          frostedSigma(_frostGlowBlur),
        ),
    );
    canvas.restore();
    canvas.drawRRect(
      rrect.deflate(FrostedChromeMetrics.outline / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = FrostedChromeMetrics.outline
        ..color = sheens.frostRing,
    );
  }

  @override
  bool shouldRepaint(_FrostPainter oldDelegate) =>
      radius != oldDelegate.radius || sheens != oldDelegate.sheens;
}

// ---------------------------------------------------------------------------
// The debit card, the card number
// ---------------------------------------------------------------------------

/// A debit card's art (`.dcard`): 92 x 58 of cool glass in a rim of the
/// cyan hue's blues, the ink mark and its kind at the top, its last four at
/// the foot. A picture; its words stand beside it.
///
/// ```dart
/// FrostedDebitCard(mask: '3907')
/// ```
class FrostedDebitCard extends StatelessWidget {
  /// Creates a [FrostedDebitCard].
  const FrostedDebitCard({
    required this.mask,
    this.kind,
    this.label,
    super.key,
  });

  /// The card's last four.
  final String mask;

  /// The card's kind, at the top end.
  final String? kind;

  /// What a screen reader says; the kind and last four when null.
  final String? label;

  @override
  Widget build(BuildContext context) => Directionality(
    // Figures, codes and marks read left to right in any language.
    textDirection: TextDirection.ltr,
    child: Builder(builder: _ltrBuild),
  );

  Widget _ltrBuild(BuildContext context) {
    final kind = this.kind ?? FrostedLocalizations.of(context).debit;
    final t = context.frostedTheme;
    final small = t.textTheme.labelSmall.c(t.colorScheme.textSecondary);
    return Semantics(
      label: label ?? '$kind card ·· $mask',
      image: true,
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: SizedBox.fromSize(
          size: FrostedChromeMetrics.debitCard,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                FrostedChromeMetrics.debitCardRadius,
              ),
              gradient: LinearGradient(
                colors: [t.hues.cyan.a, t.hues.cyan.b, t.hues.iris.a],
                stops: const [0, 0.5, 1],
                transform: const FrostedCssAngle(_rimAngle),
              ),
              boxShadow: [
                frostedShadow(
                  color: t.sheens.debitShade,
                  y: 8,
                  blur: 18,
                  spread: -12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(FrostedChromeMetrics.outline),
              child: FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(
                  FrostedChromeMetrics.debitCardRadius -
                      FrostedChromeMetrics.outline,
                ),
                gradients: [
                  LinearGradient(
                    colors: [t.sheens.debitFrom, t.sheens.debitTo],
                    transform: const FrostedCssAngle(_pearlAngle),
                  ),
                  _band(
                    t.sheens.debitSpecular,
                    _debitSpecularStops,
                    _specularAngle,
                  ),
                ],
                sheen: t.sheens.cardSheen,
                padding: const EdgeInsets.all(
                  FrostedChromeMetrics.debitCardInset,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FrostedMark(
                          size: FrostedChromeMetrics.debitCardMark,
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerEnd,
                            child: _line(kind, small),
                          ),
                        ),
                      ],
                    ),
                    _line(
                      '•• $mask',
                      t.textTheme.labelSmall.display
                          .tracked(FrostedChromeMetrics.cardNumberTracking)
                          .c(t.colorScheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card's number, expiry, CVC and name for the person alone (`.cnum`,
/// `.cnum-3`): the four groups spread across a well, the three facts in
/// their columns under it. In the card's details sheet, never on a page.
///
/// ```dart
/// FrostedCardNumber(number: '4242424242427730', expires: '09/29', cvc: '317', name: 'Maren Holt')
/// ```
class FrostedCardNumber extends StatelessWidget {
  /// Creates a [FrostedCardNumber].
  const FrostedCardNumber({
    required this.number,
    required this.expires,
    required this.cvc,
    required this.name,
    this.numberLabel,
    this.expiresLabel,
    this.cvcLabel,
    this.nameLabel,
    super.key,
  });

  /// The card's digits, with or without spaces.
  final String number;

  /// When the card expires, as printed.
  final String expires;

  /// The card's security code.
  final String cvc;

  /// The name on the card.
  final String name;

  /// The label over the number.
  final String? numberLabel;

  /// The label over the expiry.
  final String? expiresLabel;

  /// The label over the code.
  final String? cvcLabel;

  /// The label over the name.
  final String? nameLabel;

  List<String> get _groups {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    return [
      for (var i = 0; i < digits.length; i += 4)
        digits.substring(i, math.min(i + 4, digits.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final numberLabel =
        this.numberLabel ?? FrostedLocalizations.of(context).cardNumber;
    final expiresLabel =
        this.expiresLabel ?? FrostedLocalizations.of(context).expires;
    final cvcLabel = this.cvcLabel ?? FrostedLocalizations.of(context).cvc;
    final nameLabel = this.nameLabel ?? FrostedLocalizations.of(context).name;
    final t = context.frostedTheme;
    final groups = _groups;
    final fieldLabel = t.textTheme.labelSmall
        .line(15.6)
        .c(t.colorScheme.textSecondary);
    // The face's own figures, not tabular: `.cnum-v` and `.cnum-s` set the
    // `font` shorthand after `.num`, which resets its tabular-nums (a tabular
    // 1 stood the CVC 8.5 wide of the source's, the last four 4.2).
    final digits = t.textTheme.headlineLarge.display.line(28).tracked(0.01);
    // `.cnum-s.num { font-size: 20px }` on `.cnum-s`'s 1.2: a 24 line (the
    // body's own stood the facts 4.6 short, the act under them high), in
    // `.num`'s face, 500 and -.005em.
    final figure = t.textTheme.titleMedium.display.medium
        .at(20)
        .line(20 * 1.2)
        .tracked(-0.005);
    // A figure is never broken ("09/2" over "9"): one wider than its column
    // at large text shrinks to it whole. Expiry and code shrink by one scale
    // (each fits a box as wide as the wider of the two), so "317" never
    // stands larger than "09/29" beside it.
    var resolved = DefaultTextStyle.of(context).style.merge(figure);
    if (MediaQuery.boldTextOf(context)) {
      resolved = resolved.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: resolved),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final widest = math.max(widthOf(expires), widthOf(cvc)).ceilToDouble();
    Widget whole(String text) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: widest,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          heightFactor: 1,
          child: Text(
            text,
            style: figure,
            softWrap: false,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
    Widget fact(String label, Widget value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.numberFactLineGap,
      children: [_line(label, fieldLabel), value],
    );
    return Semantics(
      label:
          '$numberLabel ${groups.join(' ')}, $expiresLabel $expires, '
          '$cvcLabel $cvc, $name',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _numberFactsTop,
        children: [
          FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.numberRadius),
            color: t.glass.well,
            ring: frostedLitEdge(t, t.glass.wellEdge),
            padding: FrostedChromeMetrics.numberInset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedChromeMetrics.numberGap,
              children: [
                _line(numberLabel, fieldLabel),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // At large text the groups shrink before they touch: a
                  // space stays between them, as printed.
                  spacing: FrostedSpacing.s8,
                  // The groups in the order printed on the card, in any
                  // language; the facts under them follow the page.
                  textDirection: TextDirection.ltr,
                  children: [
                    for (final group in groups)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(group, style: digits),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.numberFactsInset,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.numberFactsGap,
              children: [
                Expanded(
                  flex: _numberFactFlex[0],
                  child: fact(expiresLabel, whole(expires)),
                ),
                Expanded(
                  flex: _numberFactFlex[1],
                  child: fact(cvcLabel, whole(cvc)),
                ),
                Expanded(
                  flex: _numberFactFlex[2],
                  child: fact(
                    nameLabel,
                    Text(
                      name,
                      style: t.textTheme.titleMedium.line(19.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goals
// ---------------------------------------------------------------------------

/// Where a goal stands against its date.
enum FrostedGoalStatus {
  /// Saving at pace: "On track" in the money-in green.
  onTrack,

  /// Saving behind pace: "Behind" in the warn amber.
  behind,

  /// No word at all: a goal without a date.
  none;

  String? get _word => switch (this) {
    FrostedGoalStatus.onTrack => 'On track',
    FrostedGoalStatus.behind => 'Behind',
    FrostedGoalStatus.none => null,
  };

  IconData? get _glyph => switch (this) {
    FrostedGoalStatus.onTrack => FrostedGlyphs.check,
    FrostedGoalStatus.behind => FrostedGlyphs.clock,
    FrostedGoalStatus.none => null,
  };

  FrostedTone get _tone => switch (this) {
    FrostedGoalStatus.onTrack => FrostedTone.success,
    FrostedGoalStatus.behind => FrostedTone.warning,
    FrostedGoalStatus.none => FrostedTone.quiet,
  };
}

/// A goal's card (`.goal-card`): its token, name and date with its status
/// chip at the end, the saved figure against the target, and a tube with
/// the percent at its end; the desktop stacks the token over the name. A
/// link to the goal when [onPressed].
///
/// ```dart
/// FrostedGoalCard(name: 'Lisbon in May', subtitle: 'by May 2027', icon: FrostedGlyphs.plane, hue: t.hues.sunset, saved: 2840, target: 4000, status: FrostedGoalStatus.behind, onPressed: open)
/// ```
class FrostedGoalCard extends StatelessWidget {
  /// Creates a [FrostedGoalCard].
  const FrostedGoalCard({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.hue,
    required this.saved,
    required this.target,
    this.status = FrostedGoalStatus.onTrack,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The goal's name.
  final String name;

  /// Its second line: by when, or "No date set".
  final String subtitle;

  /// The goal's glyph.
  final IconData icon;

  /// The goal's hue.
  final FrostedHue hue;

  /// What is saved.
  final num saved;

  /// The target.
  final num target;

  /// Where the goal stands.
  final FrostedGoalStatus status;

  /// Opens the goal; null makes the card inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final pct = target > 0 ? FrostedFormat.percent(saved, target) : 0;
    final of = FrostedFormat.money(target, cents: target % 1 != 0);
    final words = [
      name,
      subtitle,
      if (status._word != null) status._word!,
      '${FrostedFormat.money(saved)} of $of',
      '$pct%',
    ].join(', ');
    final token = FrostedIconMark(icon, hue: hue);
    final chip = status._word == null
        ? null
        : FrostedTag(status._word!, icon: status._glyph, tone: status._tone);
    final names = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedSpacing.s2,
      children: [
        Text(
          name,
          style: t.textTheme.titleMedium.line(20),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // .row-s { font: 400 14px/1.3 }: an 18.2 line.
        Text(
          subtitle,
          style: t.textTheme.bodyMedium
              .c(t.colorScheme.textSecondary)
              .line(18.2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final ofStyle = t.textTheme.bodyMedium
        .line(16.8)
        .c(t.colorScheme.textSecondary);
    final figure = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: FrostedChromeMetrics.goalCardFigureGap,
      children: [
        Flexible(child: FrostedMoney(saved, size: FrostedMoneySize.small)),
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('of ', style: ofStyle),
              FrostedNumberText(of, style: ofStyle),
            ],
          ),
        ),
      ],
    );
    final bar = Row(
      spacing: FrostedChromeMetrics.goalCardBarGap,
      children: [
        Expanded(child: FrostedBar(target > 0 ? saved / target : 0, hue: hue)),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: FrostedChromeMetrics.goalCardShare,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FrostedPercent(pct, size: FrostedPercentSize.small),
          ),
        ),
      ],
    );
    final children = wide
        ? [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [token, ?chip],
            ),
            names,
            figure,
            bar,
          ]
        : [
            Row(
              spacing: FrostedChromeMetrics.goalCardColumnGap,
              children: [
                token,
                Expanded(child: names),
                ?chip,
              ],
            ),
            figure,
            bar,
          ];
    // The account tile's wash on a plain tile's inset (`.tile.goal-card`:
    // `--pad` 16, 20 on the desktop), not the account's 14.
    return FrostedFacedCard(
      focusNode: focusNode,
      autofocus: autofocus,
      face: FrostedCardFace.account,
      hue: hue,
      padding: EdgeInsets.all(
        wide
            ? FrostedChromeMetrics.tileInsetWide
            : FrostedChromeMetrics.tileInset,
      ),
      onPressed: onPressed,
      label: words,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: wide
            ? FrostedChromeMetrics.goalCardRowGapWide
            : FrostedChromeMetrics.goalCardRowGap,
        children: children,
      ),
    );
  }
}

/// A goal in Home's list (`.goal`): its token, name and "saved of target ·
/// by when", the percent and its status at the end, and a tube under them.
/// A link to the goal when [onPressed].
///
/// ```dart
/// FrostedGoalRow(name: 'Lisbon in May', icon: FrostedGlyphs.plane, hue: t.hues.sunset, saved: 2840, target: 4000, by: 'May 2027', status: FrostedGoalStatus.behind, first: true, onPressed: open)
/// ```
class FrostedGoalRow extends StatelessWidget {
  /// Creates a [FrostedGoalRow].
  const FrostedGoalRow({
    required this.name,
    required this.icon,
    required this.hue,
    required this.saved,
    required this.target,
    this.by,
    this.status = FrostedGoalStatus.onTrack,
    this.first = false,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The goal's name.
  final String name;

  /// The goal's glyph.
  final IconData icon;

  /// The goal's hue.
  final FrostedHue hue;

  /// What is saved.
  final num saved;

  /// The target.
  final num target;

  /// By when, as printed ("May 2027"); null for no date.
  final String? by;

  /// Where the goal stands.
  final FrostedGoalStatus status;

  /// Whether the row is the list's first (no room above it).
  final bool first;

  /// Opens the goal; null makes the row inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final pct = target > 0 ? FrostedFormat.percent(saved, target) : 0;
    final savedWord = FrostedFormat.money(saved, cents: saved % 1 != 0);
    final targetWord = FrostedFormat.money(target, cents: target % 1 != 0);
    final sub = t.textTheme.bodyMedium.c(t.colorScheme.textSecondary);
    final num_ = sub.display.tabular.tracked(-0.005);
    final words = [
      name,
      '$savedWord of $targetWord${by == null ? '' : ', by $by'}',
      '$pct%',
      if (status._word != null) status._word!,
    ].join(', ');
    final body = Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : FrostedChromeMetrics.goalInset,
        bottom: FrostedChromeMetrics.goalInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.goalGap,
        children: [
          Row(
            spacing: FrostedChromeMetrics.goalHeadGap,
            children: [
              FrostedIconMark(icon, hue: hue),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: FrostedChromeMetrics.rowLineGap,
                  children: [
                    Text(
                      name,
                      style: t.textTheme.titleMedium.line(20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text.rich(
                      TextSpan(
                        style: sub,
                        children: [
                          TextSpan(text: savedWord, style: num_),
                          const TextSpan(text: ' of '),
                          TextSpan(text: targetWord, style: num_),
                          if (by != null) TextSpan(text: ' · by $by'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                spacing: FrostedChromeMetrics.rowEndGap,
                children: [
                  FrostedPercent(pct),
                  if (status._word != null)
                    Text(
                      status._word!,
                      style: t.textTheme.labelSmall.c(
                        status == FrostedGoalStatus.behind
                            ? t.colorScheme.warning
                            : t.colorScheme.textTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          FrostedBar(target > 0 ? saved / target : 0, hue: hue),
        ],
      ),
    );
    if (onPressed == null) {
      return Semantics(label: words, excludeSemantics: true, child: body);
    }
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: words,
      role: FrostedPressRole.link,
      child: body,
    );
  }
}

/// The card that starts a goal (`.new-goal`): the plus on the ink act, the
/// title in bold over its line, a chevron at the end; the desktop stacks
/// the plus over the words among the goal cards.
///
/// ```dart
/// FrostedNewGoal(onPressed: startGoal)
/// ```
class FrostedNewGoal extends StatelessWidget {
  /// Creates a [FrostedNewGoal].
  const FrostedNewGoal({
    required this.onPressed,
    this.title,
    this.subtitle,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Starts a goal; null makes the card inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The card's title.
  final String? title;

  /// The line under it.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final title = this.title ?? FrostedLocalizations.of(context).newGoal;
    final subtitle =
        this.subtitle ?? FrostedLocalizations.of(context).newGoalNote;
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final plus = SizedBox(
      width: FrostedChromeMetrics.newGoalPlus,
      height: FrostedChromeMetrics.newGoalPlus,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            FrostedChromeMetrics.newGoalPlusRadius,
          ),
          gradient: t.colorScheme.buttonFill,
          boxShadow: t.shadows.button,
        ),
        child: Center(
          child: Icon(
            FrostedGlyphs.add,
            size: FrostedChromeMetrics.newGoalPlusGlyph,
            color: t.colorScheme.onButton,
          ),
        ),
      ),
    );
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedSpacing.s2,
      children: [
        Text(
          title,
          style: t.textTheme.titleMedium.semibold.line(20),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: t.textTheme.bodyMedium
              .c(t.colorScheme.textSecondary)
              .line(18.2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final face = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedChromeMetrics.ghostRadius),
      color: t.sheens.newGoalFill,
      ring: t.sheens.newGoalRing,
      shadows: [
        BoxShadow(
          color: t.sheens.ghostEdge,
          spreadRadius: FrostedChromeMetrics.outline,
        ),
      ],
      // A tile's inset, 20 on the desktop (`.tile` `--pad`); there the
      // plus stands at the top and the words 16 under it however tall the
      // row makes the card: `.new-goal { justify-content: space-between }`
      // has no slack to share, `.row-main { flex: 1 }` takes it all.
      padding: EdgeInsets.all(
        wide
            ? FrostedChromeMetrics.tileInsetWide
            : FrostedChromeMetrics.ghostInset,
      ),
      child: wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.newGoalGapWide,
              children: [plus, words],
            )
          : Row(
              spacing: FrostedChromeMetrics.newGoalGap,
              children: [
                plus,
                Expanded(child: words),
                Icon(
                  FrostedGlyphs.forward,
                  size: FrostedChromeMetrics.newGoalGlyph,
                  color: t.colorScheme.textTertiary,
                ),
              ],
            ),
    );
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: '$title, $subtitle',
      role: FrostedPressRole.link,
      radius: FrostedChromeMetrics.ghostRadius,
      child: face,
    );
  }
}

// ---------------------------------------------------------------------------
// The spend mosaic
// ---------------------------------------------------------------------------

/// What a [FrostedPane] is in the mosaic.
enum FrostedPaneVariant {
  /// The band across the top (`.cell--xl`): the rent, its figure 40 over
  /// its ticket, the due line on its floor.
  wide,

  /// A column's first pane: its figure 28 over a meter.
  featured,

  /// A pane under another: its figure 20 over a meter.
  regular,

  /// A pane in the block of four (`.cell--s`): its figure 16 over a 3 tall
  /// meter, its share hidden on a phone and on the desktop its percent
  /// alone (`head(cid, full=False)`: "72%").
  small,
}

/// One pane of tinted glass in the [FrostedMosaic] (`.cell`): the category's
/// name and its share of budget on one line, the figure under them in ink,
/// and on its floor a meter with a note under it (or the rent's due line).
/// A link to the category when [onPressed].
///
/// ```dart
/// FrostedPane(name: 'Groceries', hue: t.hues.orchid, spent: 412.36, budget: 450, variant: FrostedPaneVariant.featured, meta: '8% less than Sep', onPressed: open)
/// ```
class FrostedPane extends StatelessWidget {
  /// Creates a [FrostedPane].
  const FrostedPane({
    required this.name,
    required this.hue,
    required this.spent,
    required this.budget,
    this.variant = FrostedPaneVariant.regular,
    this.meta,
    this.alert,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : ticket = null,
       paid = null,
       nextDue = null;

  /// The rent band: its one payment as a [ticket] (a FrostedTicket) beside
  /// the figure, and the month between two due days on its floor.
  const FrostedPane.rent({
    required this.name,
    required this.hue,
    required this.spent,
    required this.budget,
    required this.ticket,
    required this.paid,
    required this.nextDue,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : variant = FrostedPaneVariant.wide,
       meta = null,
       alert = null;

  /// The category's name.
  final String name;

  /// The category's hue.
  final FrostedHue hue;

  /// What was spent.
  final num spent;

  /// The category's budget.
  final num budget;

  /// What the pane is in the mosaic.
  final FrostedPaneVariant variant;

  /// The note on the floor ("8% less than Sep").
  final String? meta;

  /// The alert on the floor, in bold ("Over by $36.40"); over [meta].
  final String? alert;

  /// Opens the category; null makes the pane inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// The rent's ticket, beside its figure.
  final Widget? ticket;

  /// The words under the rent's first due dot.
  final String? paid;

  /// The words under the rent's second due dot.
  final String? nextDue;

  /// The pane's share of the whole it is laid by.
  double get weight => math.max(0, spent.toDouble());

  /// The pane's padding (`.cell` 10, 12 on the desktop; `.cell--s` 8, 10 by
  /// 12), also the least a flex slot of the mosaic gives it: a `flex-basis:
  /// 0` box is never smaller than its padding.
  EdgeInsets _inset(bool wide) => variant == FrostedPaneVariant.small
      ? wide
            ? FrostedChromeMetrics.paneSmallInsetWide
            : const EdgeInsets.all(FrostedChromeMetrics.paneSmallInset)
      : EdgeInsets.all(
          wide
              ? FrostedChromeMetrics.paneInsetWide
              : FrostedChromeMetrics.paneInset,
        );

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final small = variant == FrostedPaneVariant.small;
    final over = spent > budget;
    final pct = budget > 0 ? FrostedFormat.percent(spent, budget) : 0;
    final share =
        '$pct% of ${FrostedFormat.money(budget, cents: budget % 1 != 0)}';
    final floorNote = alert ?? meta;
    final words = [
      name,
      FrostedFormat.money(spent),
      share,
      ?floorNote,
      ?paid,
      ?nextDue,
    ].join(', ');
    final inset = _inset(wide);
    final line = t.textTheme.labelSmall.line(_paneHeadLine).c(hue.ink);
    // The name and the share each keep their width (`white-space: nowrap`),
    // spread between the ends; a head wider than the pane runs past its end
    // under the face's clip (`overflow: hidden`), never shrinking a word and
    // never a layout error: the row is laid unbounded, at least the width.
    Widget headOf(double? width) {
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: FrostedSpacing.s8,
        children: [
          _line(name, line),
          if (!small || wide)
            _line(
              small ? '$pct%' : share,
              line.c(hue.ink.withValues(alpha: hue.ink.a * _paneShareOpacity)),
            ),
        ],
      );
      if (width == null) return row;
      return SizedBox(
        height: MediaQuery.textScalerOf(context).scale(_paneHeadLine),
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          minWidth: width,
          maxWidth: double.infinity,
          child: row,
        ),
      );
    }

    final rentMoney = variant == FrostedPaneVariant.wide
        ? FrostedMoney(
            spent,
            size: FrostedMoneySize.regular,
            ink: t.colorScheme.textPrimary,
          )
        : null;
    final Widget figure;
    switch (variant) {
      case FrostedPaneVariant.wide:
        final money = rentMoney!;
        figure = wide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FrostedChromeMetrics.rentGap,
                children: [
                  Flexible(child: money),
                  if (ticket != null)
                    SizedBox(
                      width: FrostedChromeMetrics.rentTicketWide,
                      child: ticket,
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: FrostedChromeMetrics.rentGap,
                children: [money, ?ticket],
              );
      case FrostedPaneVariant.featured:
        figure = FrostedMoney(
          spent,
          size: FrostedMoneySize.small,
          ink: t.colorScheme.textPrimary,
        );
      case FrostedPaneVariant.regular:
        figure = FrostedAmount(
          spent,
          signed: false,
          size: FrostedAmountSize.large,
          // `.cell-amt`: the stat face at -.015em.
          style: t.textTheme.stat.tracked(-0.015),
          ink: t.colorScheme.textPrimary,
          textAlign: TextAlign.start,
        );
      case FrostedPaneVariant.small:
        figure = FrostedAmount(
          spent,
          signed: false,
          size: FrostedAmountSize.large,
          // A small pane's figure: the stat face at 16, -.015em.
          style: t.textTheme.stat.at(16).line(16 * 1.1).tracked(-0.015),
          ink: t.colorScheme.textPrimary,
          textAlign: TextAlign.start,
        );
    }
    final Widget floor;
    if (variant == FrostedPaneVariant.wide) {
      floor = FrostedDueLine(
        hue: hue,
        start: paid ?? '',
        end: nextDue ?? '',
        ink: hue.ink,
      );
    } else {
      floor = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: small ? 0 : FrostedChromeMetrics.paneFloorGap,
        children: [
          FrostedMeter(
            over
                ? (spent > 0 ? budget / spent : 0)
                : (budget > 0 ? spent / budget : 0),
            hue: hue,
            over: over,
            size: small ? FrostedMeterSize.small : FrostedMeterSize.regular,
          ),
          if (!small && floorNote != null)
            _line(
              floorNote,
              alert != null
                  ? t.textTheme.labelSmall.semibold.line(15.6).c(hue.ink)
                  : t.textTheme.labelSmall
                        .line(15.6)
                        .c(
                          hue.ink.withValues(
                            alpha: hue.ink.a * _paneMetaOpacity,
                          ),
                        ),
            ),
        ],
      );
    }
    final gap = small
        ? FrostedChromeMetrics.paneSmallGap
        : FrostedChromeMetrics.paneGap;
    final radius = FrostedBreakpoints.innerRadius(context);
    final face = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(radius),
      color: hue.tint,
      gradients: [
        _radial(
          t.sheens.paneHaze,
          rx: 1.2,
          ry: 0.7,
          cx: 0,
          cy: 0,
          end: _paneHazeEnd,
        ),
        if (variant == FrostedPaneVariant.wide)
          _band(t.sheens.paneSpecular, _paneSpecularStops, _paneSpecularAngle),
      ],
      ring: hue.edge,
      padding: inset,
      clipChild: true,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: hue.ink),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The head and figure at the top, the floor at the bottom; in a
            // slot too short for them the column runs past the floor and
            // the face clips it (the source's `overflow: hidden`), never
            // throwing.
            final head = headOf(
              constraints.hasBoundedWidth ? constraints.maxWidth : null,
            );
            // The rent band on the desktop: `.rent-mid { flex: 1;
            // flex-direction: row; align-items: center }` fills the pane
            // between the head and the floor, the figure at its top start
            // (`.rent-mid .money { align-self: flex-start }`) and the ticket
            // at its end, centred down it.
            if (rentMoney != null &&
                wide &&
                ticket != null &&
                constraints.hasBoundedWidth &&
                constraints.hasBoundedHeight) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomMultiChildLayout(
                  delegate: _RentBand(
                    gap: gap,
                    rtl: Directionality.of(context) == TextDirection.rtl,
                  ),
                  children: [
                    LayoutId(id: _RentPart.head, child: head),
                    LayoutId(id: _RentPart.money, child: rentMoney),
                    LayoutId(id: _RentPart.ticket, child: ticket!),
                    LayoutId(id: _RentPart.floor, child: floor),
                  ],
                ),
              );
            }
            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: gap,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  spacing: gap,
                  children: [head, figure],
                ),
                floor,
              ],
            );
            if (!constraints.hasBoundedHeight) return body;
            return OverflowBox(
              alignment: AlignmentDirectional.topStart,
              minHeight: constraints.maxHeight,
              maxHeight: double.infinity,
              child: body,
            );
          },
        ),
      ),
    );
    if (onPressed == null) {
      return Semantics(label: words, excludeSemantics: true, child: face);
    }
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: words,
      role: FrostedPressRole.link,
      radius: radius,
      child: face,
    );
  }
}

enum _RentPart { head, money, ticket, floor }

/// The rent band's parts on the desktop: the head at the top and the floor
/// at the bottom, [gap] from what lies between them; there the figure at
/// the start of the top and the ticket, 340 wide, at the end, centred down
/// the room (or at its top when the room is shorter than the ticket).
class _RentBand extends MultiChildLayoutDelegate {
  _RentBand({required this.gap, required this.rtl});

  final double gap;
  final bool rtl;

  @override
  void performLayout(Size size) {
    final w = size.width;
    final head = layoutChild(_RentPart.head, BoxConstraints(maxWidth: w));
    final floor = layoutChild(
      _RentPart.floor,
      BoxConstraints.tightFor(width: w),
    );
    final ticketWidth = math.min(FrostedChromeMetrics.rentTicketWide, w);
    final ticket = layoutChild(
      _RentPart.ticket,
      BoxConstraints.tightFor(width: ticketWidth),
    );
    final money = layoutChild(
      _RentPart.money,
      BoxConstraints(
        maxWidth: math.max(0, w - ticketWidth - FrostedChromeMetrics.rentGap),
      ),
    );
    final top = head.height + gap;
    final room = size.height - floor.height - gap - top;
    double x(double width, {required bool end}) => end != rtl ? w - width : 0;
    positionChild(_RentPart.head, Offset(x(head.width, end: false), 0));
    positionChild(_RentPart.money, Offset(x(money.width, end: false), top));
    positionChild(
      _RentPart.ticket,
      Offset(
        x(ticket.width, end: true),
        top + math.max(0, (room - ticket.height) / 2),
      ),
    );
    positionChild(_RentPart.floor, Offset(0, size.height - floor.height));
  }

  @override
  bool shouldRelayout(_RentBand oldDelegate) =>
      oldDelegate.gap != gap || oldDelegate.rtl != rtl;
}

/// A slot of a weighted flex: its share of the free room, the basis it
/// starts from and what fills it.
class _Slot {
  const _Slot(this.weight, this.basis, this.child);

  final double weight;
  final double basis;
  final Widget child;
}

/// CSS flex with a basis: each slot takes its basis, then its weight's
/// share of what is left after the gaps.
class _Weighted extends StatelessWidget {
  const _Weighted({required this.axis, required this.items});

  final Axis axis;
  final List<_Slot> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = axis == Axis.horizontal;
      final extent = horizontal ? constraints.maxWidth : constraints.maxHeight;
      final n = items.length;
      final total = items.fold<double>(0, (s, i) => s + i.weight);
      if (!extent.isFinite) {
        return Flex(
          direction: axis,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0)
                SizedBox(
                  width: horizontal ? FrostedChromeMetrics.mosaicGap : null,
                  height: horizontal ? null : FrostedChromeMetrics.mosaicGap,
                ),
              Expanded(
                flex: total > 0 ? (items[i].weight / total * 1000).round() : 1,
                child: items[i].child,
              ),
            ],
          ],
        );
      }
      final gaps = FrostedChromeMetrics.mosaicGap * math.max(0, n - 1);
      final bases = items.fold<double>(0, (s, i) => s + i.basis);
      final free = math.max(0.0, extent - bases - gaps);
      double sizeOf(int i) =>
          items[i].basis +
          (total > 0 ? free * items[i].weight / total : free / n);
      return Flex(
        direction: axis,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0)
              SizedBox(
                width: horizontal ? FrostedChromeMetrics.mosaicGap : null,
                height: horizontal ? null : FrostedChromeMetrics.mosaicGap,
              ),
            if (i == n - 1)
              Expanded(child: items[i].child)
            else
              SizedBox(
                width: horizontal ? sizeOf(i) : null,
                height: horizontal ? null : sizeOf(i),
                child: items[i].child,
              ),
          ],
        ],
      );
    },
  );
}

/// The spend mosaic (`.mosaic-tile`): panes of tinted glass in a tile,
/// 540 tall, each pane's room its spend. The first pane is the band across
/// the top (the rent); the rest, in falling order, fill two columns: the
/// first and third down the first column, the second over a block of the
/// rest, two across, down the second. Groups start from 24 and a pane from
/// its padding (a `flex-basis: 0` box is never smaller than its padding),
/// then each takes its spend's share of what is left. Frosted's second
/// signature.
///
/// ```dart
/// FrostedMosaic(title: 'October', panes: [FrostedPane.rent(name: 'Rent & home', hue: t.hues.periwinkle, spent: 1150, budget: 1150, ticket: Text('Linden Court'), paid: 'Paid Oct 1', nextDue: 'Due Nov 1'), FrostedPane(name: 'Groceries', hue: t.hues.orchid, spent: 412.36, budget: 450)])
/// ```
class FrostedMosaic extends StatelessWidget {
  /// Creates a [FrostedMosaic].
  const FrostedMosaic({
    required this.panes,
    this.title,
    this.trailing,
    super.key,
  });

  /// The panes in falling order of spend, the rent band first.
  final List<FrostedPane> panes;

  /// The tile's title.
  final String? title;

  /// The tile head's end: a link, a caption.
  final Widget? trailing;

  double _sum(Iterable<FrostedPane> some) =>
      some.fold<double>(0, (s, p) => s + p.weight);

  Widget _tree(bool wide) {
    if (panes.isEmpty) return const SizedBox.shrink();
    const basis = FrostedChromeMetrics.mosaicBasis;
    _Slot down(FrostedPane p) => _Slot(p.weight, p._inset(wide).vertical, p);
    _Slot across(FrostedPane p) =>
        _Slot(p.weight, p._inset(wide).horizontal, p);
    final first = panes.first;
    final rest = panes.sublist(1);
    if (rest.isEmpty) return first;
    final colA = <FrostedPane>[rest[0], if (rest.length > 2) rest[2]];
    final colB = <FrostedPane>[if (rest.length > 1) rest[1]];
    final block = rest.length > 3 ? rest.sublist(3) : const <FrostedPane>[];
    final rows = <List<FrostedPane>>[
      for (var i = 0; i < block.length; i += 2)
        block.sublist(i, math.min(i + 2, block.length)),
    ];
    final columnA = _Weighted(
      axis: Axis.vertical,
      items: [for (final p in colA) down(p)],
    );
    final blockTree = rows.isEmpty
        ? null
        : _Weighted(
            axis: Axis.vertical,
            items: [
              for (final row in rows)
                _Slot(
                  _sum(row),
                  basis,
                  _Weighted(
                    axis: Axis.horizontal,
                    items: [for (final p in row) across(p)],
                  ),
                ),
            ],
          );
    final columnB = _Weighted(
      axis: Axis.vertical,
      items: [
        for (final p in colB) down(p),
        if (blockTree != null) _Slot(_sum(block), basis, blockTree),
      ],
    );
    final columns = _Weighted(
      axis: Axis.horizontal,
      items: [
        _Slot(_sum(colA), basis, columnA),
        if (colB.isNotEmpty || blockTree != null)
          _Slot(_sum(colB) + _sum(block), basis, columnB),
      ],
    );
    return _Weighted(
      axis: Axis.vertical,
      items: [down(first), _Slot(_sum(rest), basis, columns)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = FrostedBreakpoints.isWide(context);
    final height = wide
        ? FrostedChromeMetrics.mosaicHeightWide
        : FrostedChromeMetrics.mosaicHeight;
    final headInset = wide
        ? FrostedChromeMetrics.mosaicHeadInsetWide
        : FrostedChromeMetrics.mosaicHeadInset;
    return FrostedCard(
      padding: const EdgeInsets.all(FrostedChromeMetrics.mosaicTileInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                headInset,
                headInset,
                headInset,
                0,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: wide
                      ? FrostedChromeMetrics.mosaicHeadWide
                      : FrostedChromeMetrics.mosaicHead,
                ),
                child: FrostedCardHeader(title!, trailing: trailing),
              ),
            ),
          MediaQuery.withNoTextScaling(
            child: SizedBox(height: height, child: _tree(wide)),
          ),
        ],
      ),
    );
  }
}

enum _CardRow { top, mid, foot }

/// A card's three rows (`.kcard { display: flex; flex-direction: column;
/// justify-content: space-between }`): the brand row at the top, the foot
/// on the floor and the balance in the middle of what is left. Where the
/// three do not fit (the Cards stage's 284 card on the desktop) they stack
/// from the top at their own heights and the foot runs into the inset, as a
/// flex column's negative free space packs its items at its start; the
/// balance is never scaled to make room (only a figure wider than the card
/// narrows).
class _CardRows extends MultiChildLayoutDelegate {
  _CardRows(this.direction);

  final TextDirection direction;

  @override
  void performLayout(Size size) {
    final across = BoxConstraints.tightFor(width: size.width);
    final top = layoutChild(_CardRow.top, across);
    final mid = layoutChild(_CardRow.mid, BoxConstraints(maxWidth: size.width));
    final foot = layoutChild(_CardRow.foot, across);
    final slack = size.height - top.height - mid.height - foot.height;
    final gap = slack > 0 ? slack / 2 : 0.0;
    positionChild(_CardRow.top, Offset.zero);
    positionChild(
      _CardRow.mid,
      Offset(
        direction == TextDirection.rtl ? size.width - mid.width : 0,
        top.height + gap,
      ),
    );
    positionChild(
      _CardRow.foot,
      Offset(0, top.height + gap + mid.height + gap),
    );
  }

  @override
  bool shouldRelayout(_CardRows oldDelegate) =>
      direction != oldDelegate.direction;
}
