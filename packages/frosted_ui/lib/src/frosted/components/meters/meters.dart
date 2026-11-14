/// Frosted's meters: the prism track of bands with its labels, pace tick and
/// scale and the legend under it, bars and tubes, a pane's meter, the over
/// bar, compare and merchant bars, in against out, a split's shares, the
/// statement's timeline, the visit strip, the due line, balance changes,
/// the route beam and the done mark.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/cap.dart';
import '../../internal/face.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../../localizations.dart';

import 'package:ui_core/ui_core.dart';

// The source's inks and hues the CSS names in place, which the theme has no
// role for; its whites and its ink's hairlines are the theme's sheens
// (FrostedSheens), so the dark appearance has its own.
// metric: the kept band's far stop, the money-in green at .22, and its ring
// at .16 (`.seg--kept`).
const Color _keptTo = Color(0x3840A874);
const Color _keptRing = Color(0x2940A874);
// metric: the done mark's glow (#6BD1D2 at .34 to nothing) and its rings'
// stops (#7FD2B0, #A9AEF0, #6BD1D2: the SVG's own) at .75/.52/.32/.18
// (`.done-rings`); the check's halo is the sheens' (`.done-check`).
const Color _doneGlow = Color(0x576BD1D2);
const List<Color> _doneRingStops = [
  Color(0xFF7FD2B0),
  Color(0xFFA9AEF0),
  Color(0xFF6BD1D2),
];
const List<double> _doneRingRadii = [58, 78, 98, 118];
const List<double> _doneRingOpacities = [0.75, 0.52, 0.32, 0.18];
const double _doneRingsBox = 240;
const double _doneRingStroke = 1.5;
// metric: the due line's rule, the pane's ink at .28, and its words at .8
// (`.due-line::before`, `.due-l`).
const double _dueRuleOpacity = 0.28;
const double _dueWordsOpacity = 0.8;
// metric: the width a track lays itself across when its parent sets none
// (a Wrap); in a column it fills the width it is given.
const double _looseWidth = 320;
// metric: a legend's fixed rows per column (`.legend` repeat(4, auto)) and
// a three-across legend's entries per row (`.legend--3`).
const int _legendRows = 4;

/// metric: `.pa-legend .lg { padding: 10px 0 }` on the desktop.
const double _allocationRowInset = 10;

/// metric: `.pa-legend .lg .nm { font-size: 14px }` (500 14/1.2).
const double _allocationName = 14;
const int _legendAcross = 3;
// metric: merchant cards across on the desktop (`.a-tm .merchants`).
const int _merchantsAcross = 4;
// metric: compare rows 16 apart, a row's head 8 over its tube, the head's
// name and amount 12 apart (`.cmp`, `.cmp-r`, `.cmp-h`).
const double _compareGap = 16;
const double _compareRowGap = 8;
const double _compareHeadGap = 12;
// metric: merchant rows 2 apart on a phone (`.merchants`).
const double _merchantsGap = 2;
// metric: the statement's closed bead ring 2.5, its due bead ring 1.5
// (`.stl-n--closed`, `.stl-n--due`).
const double _statementClosedRing = 2.5;
const double _statementDueRing = 1.5;
// metric: the due line's second bead ring, 1.5 of the hue (`.due-line i + i`).
const double _dueBeadRing = 1.5;
// metric: a frozen card's limit stands at .45 (`.lim--off`).
const double _limitOffOpacity = 0.45;

/// A top-down sheen: [color] at the top fading to nothing at [stop].
LinearGradient _topSheen(Color color, double stop) => LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [color, color.withValues(alpha: 0)],
  stops: [0, stop],
);

/// A single line of words that clips instead of wrapping.
Widget _line(
  String text,
  TextStyle style, {
  TextAlign? align,
  TextDirection? direction,
}) => Text(
  text,
  style: style,
  maxLines: 1,
  softWrap: false,
  overflow: TextOverflow.clip,
  textAlign: align,
  textDirection: direction,
);

/// The width [constraints] give, or the loose width when they give none.
double _widthOf(BoxConstraints constraints) =>
    constraints.hasBoundedWidth ? constraints.maxWidth : _looseWidth;

// ---------------------------------------------------------------------------
// The prism track
// ---------------------------------------------------------------------------

/// How tall a [FrostedTrack] stands.
enum FrostedTrackSize {
  /// 40 tall, 56 on the desktop (`.prism-lg`): a page's own track, its
  /// bands wide enough for a [FrostedSegmentLabel].
  large,

  /// 16 tall (`.prism-sm`): a tile's track under its figures.
  small,

  /// 10 tall (`.prism-xs`): a balance change's.
  extraSmall;

  /// The track's height at [context].
  double heightIn(BuildContext context) => switch (this) {
    FrostedTrackSize.large =>
      FrostedBreakpoints.isWide(context)
          ? FrostedChromeMetrics.frostedTrackWide
          : FrostedChromeMetrics.frostedTrack,
    FrostedTrackSize.small => FrostedChromeMetrics.frostedTrackSmall,
    FrostedTrackSize.extraSmall => FrostedChromeMetrics.frostedTrackLeast,
  };

  /// How far the pace tick reaches past the track's edges.
  double get reach => this == FrostedTrackSize.large
      ? FrostedChromeMetrics.paceReach
      : FrostedChromeMetrics.paceReachSmall;
}

/// What a band of a [FrostedTrack] is made of.
enum FrostedBandVariant {
  /// The hue's own band (`.seg`): its a to b under a top sheen.
  hue,

  /// A part of the hue in its tint (`.seg--part`): the rest of a category
  /// beside the record's merchant.
  part,

  /// What is left of a whole, in the wash (`.seg--left`): a goal's room.
  left,

  /// What came in and stayed, in the money-in tint (`.seg--kept`).
  kept,

  /// Money leaving an account, white over the hue's edge (`.seg--leave`).
  leave,

  /// Money arriving, the hue's b to a under a brighter sheen
  /// (`.seg--arrive`).
  arrive,
}

/// Where a [FrostedSegmentLabel] sits in its band.
enum FrostedSegmentAlign {
  /// At the band's start, 10 in (16 in the first band).
  start,

  /// At the band's end, 16 in: a split's second share.
  end,
}

/// One band of a [FrostedTrack]: its [weight] (the amount it stands for, the
/// track dividing its width by the weights), its [hue], what it is made of
/// and the words a screen reader says for it.
///
/// ```dart
/// FrostedBand(412.36, hue: t.hues.orchid, name: 'Groceries')
/// ```
@immutable
final class FrostedBand {
  /// Creates a [FrostedBand].
  const FrostedBand(
    this.weight, {
    this.hue,
    this.variant = FrostedBandVariant.hue,
    this.name,
    this.label,
    this.key,
  });

  /// The amount the band stands for; its share of the track's width.
  final num weight;

  /// The band's hue; the prism's when none (a left or kept band needs
  /// none).
  final FrostedHue? hue;

  /// What the band is made of.
  final FrostedBandVariant variant;

  /// What the band is called, for the track's semantics.
  final String? name;

  /// Words laid inside the band: a [FrostedSegmentLabel].
  final Widget? label;

  /// A key for the band's box, so a test or an animation can find it.
  final Key? key;
}

/// The words inside a band of a [FrostedTrack] (`.seg-l`): a name 500 12
/// over an amount 600 14 in the display face, in the band's deep ink.
///
/// ```dart
/// FrostedSegmentLabel('You', '\$14.00')
/// ```
class FrostedSegmentLabel extends StatelessWidget {
  /// Creates a [FrostedSegmentLabel].
  const FrostedSegmentLabel(
    this.name,
    this.amount, {
    this.align = FrostedSegmentAlign.start,
    this.ink,
    super.key,
  });

  /// The share's name.
  final String name;

  /// The share's amount, already formatted.
  final String amount;

  /// Which end of the band the words sit at.
  final FrostedSegmentAlign align;

  /// The words' ink; the band's deep ink when null.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final color =
        ink ??
        DefaultTextStyle.of(context).style.color ??
        t.colorScheme.textPrimary;
    final start = align == FrostedSegmentAlign.start;
    final lines = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      spacing: FrostedChromeMetrics.frostedLabelGap,
      children: [
        _line(name, t.textTheme.labelSmall.c(color)),
        _line(
          amount,
          t.textTheme.labelLarge.display.tabular.tracked(-0.01).c(color),
        ),
      ],
    );
    // The band is as tall as its track: at large text the two lines shrink
    // to fit its height rather than run past its foot. Their width stays the
    // band's, so a narrow band still clips them at its end, as the source.
    return LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: start
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.centerEnd,
        child: box.hasBoundedWidth
            ? SizedBox(width: box.maxWidth, child: lines)
            : lines,
      ),
    );
  }
}

/// The pace tick across a track or a tube (`.pace`, `.tube-tick`): a 1.5
/// wide line of the pace ink in a 1.5 ring of the track's white, reaching
/// past both edges.
///
/// ```dart
/// FrostedPaceTick(height: 20)
/// ```
class FrostedPaceTick extends StatelessWidget {
  /// Creates a [FrostedPaceTick].
  const FrostedPaceTick({this.height, super.key});

  /// The tick's height; null fills what its parent gives.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return SizedBox(
      width: FrostedChromeMetrics.paceTick,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorScheme.paceTick,
          borderRadius: BorderRadius.circular(FrostedCorners.rFull),
          boxShadow: [
            BoxShadow(
              color: t.colorScheme.paceTickRing,
              spreadRadius: FrostedChromeMetrics.paceRing,
            ),
          ],
        ),
      ),
    );
  }
}

/// The captions under a track (`.prism-scale`): one at each end in the
/// caption's type (`.cap`) unless they set their own, each its own width
/// while both fit and both narrowed in proportion when they do not (the
/// flex row's shrink, so a long start keeps the line a short end leaves
/// it), 16 tall at least, and the pace's label anchored 8 before its tick
/// (`.pace-l`).
///
/// ```dart
/// FrostedScale(start: Text('\$0'), paceAt: 212, paceLabel: 'Budget \$250')
/// ```
class FrostedScale extends StatelessWidget {
  /// Creates a [FrostedScale].
  const FrostedScale({
    this.start,
    this.trailing,
    this.paceAt,
    this.paceLabel,
    super.key,
  });

  /// The caption at the start.
  final Widget? start;

  /// The caption at the end.
  final Widget? trailing;

  /// Where the pace tick stands, in logical px from the start.
  final double? paceAt;

  /// The pace's words, their end 8 before the tick.
  final String? paceLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FrostedChromeMetrics.frostedScaleHeight,
          ),
          child: DefaultTextStyle.merge(
            style: t.textTheme.labelMedium,
            child: _ScaleEnds(
              children: [
                start ?? const SizedBox.shrink(),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ),
        if (paceAt != null && paceLabel != null)
          PositionedDirectional(
            start: paceAt! - FrostedChromeMetrics.paceLabelGap,
            top: 0,
            child: FractionalTranslation(
              translation: Offset(rtl ? 1 : -1, 0),
              child: _line(
                paceLabel!,
                t.textTheme.labelMedium.c(t.colorScheme.textPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

/// A scale's two ends across its width as `.prism-scale { display: flex;
/// justify-content: space-between }` sets them: each its own width while
/// both fit, the first at the start and the last at the end, both at the
/// top; when they do not fit, both narrowed in proportion to their own
/// widths (`flex-shrink: 1` weighs by the basis). Unbounded, each keeps
/// its own width.
class _ScaleEnds extends MultiChildRenderObjectWidget {
  const _ScaleEnds({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderScaleEnds(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderScaleEnds renderObject,
  ) => renderObject.direction = Directionality.of(context);
}

class _ScaleEndsData extends ContainerBoxParentData<RenderBox> {}

class _RenderScaleEnds extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ScaleEndsData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ScaleEndsData> {
  _RenderScaleEnds(this._direction);

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ScaleEndsData) {
      child.parentData = _ScaleEndsData();
    }
  }

  /// Each end's width in [width]: its own while all fit, else its share of
  /// [width] in proportion to its own.
  List<double> _widths(double width) {
    final own = [
      for (final c in getChildrenAsList())
        c.getMaxIntrinsicWidth(double.infinity),
    ];
    final total = own.fold(0.0, (a, b) => a + b);
    if (!width.isFinite || total <= width) return own;
    return [for (final w in own) width * w / total];
  }

  double _extent(BoxConstraints c, List<double> widths) =>
      c.hasBoundedWidth ? c.maxWidth : widths.fold(0.0, (a, b) => a + b);

  @override
  double computeMinIntrinsicWidth(double height) {
    var sum = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      sum += c.getMinIntrinsicWidth(height);
    }
    return sum;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var sum = 0.0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      sum += c.getMaxIntrinsicWidth(height);
    }
    return sum;
  }

  double _tallest(double width, double Function(RenderBox, double) measure) {
    final widths = _widths(width);
    var h = 0.0;
    var i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      h = math.max(h, measure(c, widths[i++]));
    }
    return h;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final widths = _widths(constraints.maxWidth);
    final h = _tallest(
      constraints.maxWidth,
      (c, w) => c.getDryLayout(BoxConstraints(maxWidth: w)).height,
    );
    return constraints.constrain(Size(_extent(constraints, widths), h));
  }

  @override
  void performLayout() {
    final widths = _widths(constraints.maxWidth);
    final extent = _extent(constraints, widths);
    var h = 0.0;
    var i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      c.layout(BoxConstraints(maxWidth: widths[i++]), parentUsesSize: true);
      h = math.max(h, c.size.height);
    }
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final w = c.size.width;
      // The first at the start; the last (when there are two) at the end.
      final x = c == firstChild ? 0.0 : extent - w;
      (c.parentData! as _ScaleEndsData).offset = Offset(
        _direction == TextDirection.rtl ? extent - x - w : x,
        0,
      );
    }
    size = constraints.constrain(Size(extent, h));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// The prism track (`.prism-track`): one glass tube of bands joined by white
/// hairlines, each band's width its weight's share of the whole, a pace
/// tick where a budget stands and captions under it. Frosted's signature.
///
/// ```dart
/// FrostedTrack(bands: [FrostedBand(20860, hue: t.hues.azure, name: 'Emergency fund'), FrostedBand(5460, variant: FrostedBandVariant.left, name: 'to go')])
/// ```
class FrostedTrack extends StatelessWidget {
  /// Creates a [FrostedTrack].
  const FrostedTrack({
    required this.bands,
    this.size = FrostedTrackSize.large,
    this.pace,
    this.paceLabel,
    this.scaleStart,
    this.scaleEnd,
    this.scaleGap = FrostedChromeMetrics.frostedScaleGap,
    this.label,
    super.key,
  });

  /// The bands, start to end.
  final List<FrostedBand> bands;

  /// How tall the track is.
  final FrostedTrackSize size;

  /// Where the pace tick stands, as a fraction of the bands' whole; null
  /// draws none.
  final double? pace;

  /// The pace's caption under the track, its end before the tick.
  final String? paceLabel;

  /// The caption at the scale's start.
  final Widget? scaleStart;

  /// The caption at the scale's end.
  final Widget? scaleEnd;

  /// The room between the track and its scale: 10 (`.prism-scale {
  /// margin-top: 10px }`), 8 in Activity's flow (`.flow .prism-scale`).
  final double scaleGap;

  /// What a screen reader says; the named bands and their shares when
  /// null.
  final String? label;

  double get _total => bands.fold<double>(
    0,
    (sum, band) => sum + math.max(0, band.weight.toDouble()),
  );

  String _words() {
    final total = _total;
    final parts = <String>[
      for (final band in bands)
        if (band.name != null)
          total > 0
              ? '${band.name} ${FrostedFormat.percent(math.max(0, band.weight), total)}%'
              : band.name!,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final height = size.heightIn(context);
    final total = _total;
    final hasScale =
        scaleStart != null || scaleEnd != null || paceLabel != null;
    return Semantics(
      label: label ?? _words(),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = _widthOf(constraints);
          final n = bands.length;
          final gaps = FrostedChromeMetrics.frostedGap * math.max(0, n - 1);
          final room = math.max(0.0, width - gaps);
          final shares = [
            for (final band in bands)
              total > 0
                  ? math.max(0, band.weight.toDouble()) / total
                  : (n == 0 ? 0.0 : 1 / n),
          ];
          double? tickX;
          if (pace != null && n > 0) {
            final f = pace!.clamp(0.0, 1.0);
            var before = 0;
            var reached = 0.0;
            for (var i = 0; i < n - 1; i++) {
              reached += shares[i];
              if (reached < f) {
                before++;
              } else {
                break;
              }
            }
            tickX = room * f + before * FrostedChromeMetrics.frostedGap;
          }
          final track = SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.glass.track,
                      borderRadius: BorderRadius.circular(FrostedCorners.rFull),
                      boxShadow: [
                        BoxShadow(
                          color: t.glass.trackEdge,
                          spreadRadius: FrostedChromeMetrics.outline,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < n; i++) ...[
                        if (i > 0)
                          const SizedBox(
                            width: FrostedChromeMetrics.frostedGap,
                          ),
                        if (i == n - 1)
                          Expanded(
                            child: _BandBox(
                              key: bands[i].key,
                              band: bands[i],
                              first: i == 0,
                              last: true,
                            ),
                          )
                        else
                          SizedBox(
                            width: room * shares[i],
                            child: _BandBox(
                              key: bands[i].key,
                              band: bands[i],
                              first: i == 0,
                              last: false,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (tickX != null)
                  PositionedDirectional(
                    start: tickX - FrostedChromeMetrics.paceTick / 2,
                    top: -size.reach,
                    bottom: -size.reach,
                    child: const FrostedPaceTick(),
                  ),
              ],
            ),
          );
          if (!hasScale) return track;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: scaleGap,
            children: [
              track,
              FrostedScale(
                start: scaleStart,
                trailing: scaleEnd,
                paceAt: tickX,
                paceLabel: paceLabel,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One band's box: its fill by its style, its corners at the track's ends,
/// its label inset and clipped.
class _BandBox extends StatelessWidget {
  const _BandBox({
    required this.band,
    required this.first,
    required this.last,
    super.key,
  });

  final FrostedBand band;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final hue = band.hue ?? t.hues.iris;
    const full = Radius.circular(FrostedCorners.rFull);
    final radius = BorderRadiusDirectional.horizontal(
      start: first ? full : Radius.zero,
      end: last ? full : Radius.zero,
    ).resolve(Directionality.of(context));
    Widget? child;
    if (band.label != null) {
      final atEnd =
          band.label is FrostedSegmentLabel &&
          (band.label! as FrostedSegmentLabel).align == FrostedSegmentAlign.end;
      child = Padding(
        padding: EdgeInsetsDirectional.only(
          start: first
              ? FrostedChromeMetrics.frostedLabelInsetEnd
              : FrostedChromeMetrics.frostedLabelInset,
          end: atEnd
              ? FrostedChromeMetrics.frostedLabelInsetEnd
              : FrostedChromeMetrics.frostedLabelInset,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: hue.inkDeep),
          child: band.label!,
        ),
      );
    }
    return switch (band.variant) {
      FrostedBandVariant.hue => FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        gradients: [hue.band, _topSheen(t.sheens.bandSheen, 0.55)],
        sheen: t.sheens.bandLight,
        edge: t.sheens.bandShade,
        edges: const EdgeInsets.only(bottom: FrostedChromeMetrics.outline),
        clipChild: true,
        child: child,
      ),
      FrostedBandVariant.part => FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        color: hue.tintSolid,
        ring: hue.edge,
        clipChild: true,
        child: child,
      ),
      FrostedBandVariant.left => FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        color: t.glass.wash,
        clipChild: true,
        child: child,
      ),
      FrostedBandVariant.kept => FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        gradients: [
          LinearGradient(colors: [t.colorScheme.moneyInTint, _keptTo]),
        ],
        ring: _keptRing,
        clipChild: true,
        child: child,
      ),
      FrostedBandVariant.leave => FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        color: t.sheens.leaveFill,
        ring: hue.edge,
        clipChild: true,
        child: child,
      ),
      FrostedBandVariant.arrive => FrostedFace(
        material: FrostedMaterial.paint,
        radius: radius,
        gradients: [
          LinearGradient(colors: [hue.b, hue.a]),
          _topSheen(t.sheens.arriveSheen, 0.7),
        ],
        ring: t.sheens.arriveRing,
        clipChild: true,
        child: child,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// The legend
// ---------------------------------------------------------------------------

/// How a [FrostedLegend] lays its entries.
enum FrostedLegendVariant {
  /// Two columns filled top to bottom, four rows each (`.legend`): Home's
  /// eight categories.
  columns,

  /// Three across, spread between the ends (`.legend--3`): the goals.
  threeColumns,

  /// Rows of swatch, name, share and amount (`.parts`): an allocation's
  /// kinds, where an account's month went.
  rows,

  /// Three across on a phone; on the desktop, rows with hairlines between
  /// in a side column, the name in the page ink and the amount at the end
  /// (`.legend--3.pa-legend`): where the year's saving went.
  allocation,
}

class _LegendScope extends InheritedWidget {
  const _LegendScope({required this.variant, required super.child});

  final FrostedLegendVariant variant;

  static FrostedLegendVariant of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LegendScope>()?.variant ??
      FrostedLegendVariant.columns;

  @override
  bool updateShouldNotify(_LegendScope oldWidget) =>
      variant != oldWidget.variant;
}

/// `.part`'s line: 14px at 1.3.
const double _partLine = 18.2;

/// One entry of a [FrostedLegend] (`.lg`, `.part`): the hue's swatch, the
/// name and, under or after it, the amount and the share.
///
/// ```dart
/// FrostedLegendEntry('Emergency fund', hue: t.hues.azure, amount: 20860)
/// ```
class FrostedLegendEntry extends StatelessWidget {
  /// Creates a [FrostedLegendEntry].
  const FrostedLegendEntry(
    this.name, {
    required this.hue,
    this.amount,
    this.share,
    this.part = false,
    this.current = false,
    super.key,
  });

  /// The entry's name.
  final String name;

  /// The entry's hue.
  final FrostedHue hue;

  /// The entry's amount, unsigned.
  final num? amount;

  /// The entry's share of the whole, as a percent (a row's `.part-p`).
  final int? share;

  /// Whether the swatch is the part tint (`.sw--part`).
  final bool part;

  /// Whether the entry is the record's own (`.part.this`): its words in
  /// the primary ink.
  final bool current;

  String get _words => [
    name,
    if (share != null) '$share%',
    if (amount != null) FrostedFormat.money(amount!),
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final style = _LegendScope.of(context);
    final allocationRows =
        style == FrostedLegendVariant.allocation &&
        FrostedBreakpoints.isWide(context);
    final Widget entry;
    if (style == FrostedLegendVariant.rows || allocationRows) {
      final words = allocationRows
          ? t.textTheme.labelSmall
                .at(_allocationName)
                .line(_allocationName * 1.2)
                .c(t.colorScheme.textPrimary)
          // .part { font: 400 14px/1.3 }: an 18.2 line, the row's height.
          : current
          ? t.textTheme.bodyMedium.medium
                .c(t.colorScheme.textPrimary)
                .line(_partLine)
          : t.textTheme.bodyMedium
                .c(t.colorScheme.textSecondary)
                .line(_partLine);
      // `.part { gap: 10px }`; an allocation's row is `.lg`'s grid, its
      // columns 8 apart (`.lg { column-gap: 8px }`: at 10 its names stood 2
      // right).
      entry = Row(
        spacing: allocationRows
            ? FrostedChromeMetrics.legendSwatchGap
            : FrostedChromeMetrics.partGap,
        children: [
          FrostedSwatch(hue, part: part),
          Expanded(
            child: Text(
              name,
              style: words,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (share != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: FrostedChromeMetrics.partShareGap,
              ),
              child: Text('$share%', style: t.textTheme.labelMedium),
            ),
          if (amount != null)
            FrostedAmount(
              amount!,
              signed: false,
              size: allocationRows
                  ? FrostedAmountSize.regular
                  : FrostedAmountSize.small,
              ink: t.colorScheme.textPrimary,
            ),
        ],
      );
    } else {
      final nameStyle = t.textTheme.labelSmall
          .c(t.colorScheme.textSecondary)
          .line(14.4);
      // As wide as its words: the three-across legend spreads entries by
      // their own widths; a column of the grid gives a tight width anyway.
      entry = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedChromeMetrics.legendSwatchGap,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: (14.4 - FrostedChromeMetrics.swatch) / 2,
            ),
            child: FrostedSwatch(hue, part: part),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedChromeMetrics.legendLineGap,
              children: [
                Text(
                  name,
                  style: nameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (amount != null)
                  FrostedAmount(
                    amount!,
                    signed: false,
                    textAlign: TextAlign.start,
                  ),
              ],
            ),
          ),
        ],
      );
    }
    return Semantics(label: _words, excludeSemantics: true, child: entry);
  }
}

/// The legend under a [FrostedTrack] (`.legend`, `.parts`): what each band
/// is, as the track's hues, names and amounts.
///
/// ```dart
/// FrostedLegend(variant: FrostedLegendVariant.threeColumns, children: [FrostedLegendEntry('Emergency fund', hue: t.hues.azure, amount: 20860)])
/// ```
class FrostedLegend extends StatelessWidget {
  /// Creates a [FrostedLegend].
  const FrostedLegend({
    required this.children,
    this.variant = FrostedLegendVariant.columns,
    super.key,
  });

  /// The entries, in the bands' order.
  final List<FrostedLegendEntry> children;

  /// How the entries lie.
  final FrostedLegendVariant variant;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    switch (variant) {
      case FrostedLegendVariant.columns:
        final columns = <List<Widget>>[];
        for (var i = 0; i < children.length; i += _legendRows) {
          columns.add(
            children.sublist(i, math.min(i + _legendRows, children.length)),
          );
        }
        if (columns.length < 2) columns.add(const <Widget>[]);
        body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FrostedChromeMetrics.legendColumnGap,
          children: [
            for (final column in columns)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: FrostedChromeMetrics.legendRowGap,
                  children: column,
                ),
              ),
          ],
        );
      case FrostedLegendVariant.threeColumns:
        body = _three();
      case FrostedLegendVariant.allocation:
        if (!FrostedBreakpoints.isWide(context)) {
          body = _three();
        } else {
          final t = context.frostedTheme;
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // `.lg { padding: 10px 0 } .lg + .lg { border-top: 1px }`: the
              // rule is the lower row's own, over its 10 (a decoration
              // alone takes no room: every row stood 1 short).
              for (var i = 0; i < children.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(
                              color: t.colorScheme.border,
                              width: FrostedChromeMetrics.outline,
                            ),
                          ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: _allocationRowInset,
                  ),
                  child: children[i],
                ),
            ],
          );
        }
      case FrostedLegendVariant.rows:
        body = Padding(
          padding: const EdgeInsets.only(top: FrostedChromeMetrics.partsTop),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedChromeMetrics.partsGap,
            children: children,
          ),
        );
    }
    return _LegendScope(variant: variant, child: body);
  }

  /// Three across, spread between the ends (`.legend--3`: `repeat(3, auto)`
  /// tracks, `justify-content: space-between`): each entry at its own width
  /// and the free room shared between them, never under
  /// [FrostedChromeMetrics.legendColumnGap]. Three that cannot fit in a row
  /// break onto the next (the source's names would wrap in place); every
  /// row of three is 12 under the one before.
  Widget _three() {
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += _legendAcross) {
      rows.add(
        children.sublist(i, math.min(i + _legendAcross, children.length)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FrostedChromeMetrics.legendRowGap,
      children: [
        for (final row in rows)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: FrostedChromeMetrics.legendColumnGap,
            runSpacing: FrostedChromeMetrics.legendRowGap,
            children: row,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bars, tubes and meters
// ---------------------------------------------------------------------------

/// What a [FrostedBar] is drawn as.
enum FrostedBarVariant {
  /// 6 tall on the wash (`.bar`): a merchant's share.
  bar,

  /// 4 tall on the wash (`.bar--thin`): a merchant's share in a row.
  thin,

  /// 8 tall, the track's glass with a lit top edge (`.tube`): a goal's, a
  /// month's against the one before.
  tube,

  /// 12 tall (`.tube--lg`): a card's limit.
  tubeLarge;

  double get _height => switch (this) {
    FrostedBarVariant.bar => FrostedChromeMetrics.bar,
    FrostedBarVariant.thin => FrostedChromeMetrics.barThin,
    FrostedBarVariant.tube => FrostedChromeMetrics.tube,
    FrostedBarVariant.tubeLarge => FrostedChromeMetrics.tubeLarge,
  };

  bool get _glass =>
      this == FrostedBarVariant.tube || this == FrostedBarVariant.tubeLarge;
}

/// A share of a whole as one bar of the hue (`.bar`, `.tube`): a goal's
/// saved, a card's used limit, a merchant's share of a category; a tick
/// where a budget stands and a caption at each end when asked.
///
/// ```dart
/// FrostedBar(0.71, hue: t.hues.sunset)
/// ```
class FrostedBar extends StatelessWidget {
  /// Creates a [FrostedBar].
  const FrostedBar(
    this.fraction, {
    required this.hue,
    this.variant = FrostedBarVariant.tube,
    this.tick,
    this.scaleStart,
    this.scaleEnd,
    this.dimmed = false,
    this.label,
    super.key,
  });

  /// The share filled, 0 to 1.
  final double fraction;

  /// The fill's hue.
  final FrostedHue hue;

  /// What the bar is drawn as.
  final FrostedBarVariant variant;

  /// Where the tick stands, 0 to 1; null draws none.
  final double? tick;

  /// The caption at the scale's start (`.ob-scale`), 8 under the bar.
  final String? scaleStart;

  /// The caption at the scale's end.
  final String? scaleEnd;

  /// Whether the whole stands at .45 (`.lim--off`): a frozen card's limit.
  final bool dimmed;

  /// What a screen reader says; the percent when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final f = fraction.clamp(0.0, 1.0);
    final height = variant._height;
    final reach =
        (FrostedChromeMetrics.tubeTickHeight - FrostedChromeMetrics.tubeLarge) /
        2;
    final full = BorderRadius.circular(FrostedCorners.rFull);
    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: variant._glass ? t.glass.track : t.glass.wash,
        borderRadius: full,
        boxShadow: variant._glass
            ? [
                BoxShadow(
                  color: t.sheens.tubeRing,
                  spreadRadius: FrostedChromeMetrics.outline,
                ),
              ]
            : null,
      ),
    );
    final fill = FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: f,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: full,
        gradients: [
          hue.band,
          if (variant._glass) _topSheen(t.sheens.tubeSheen, 0.6),
        ],
        sheen: variant._glass ? t.sheens.tubeLight : null,
      ),
    );
    Widget bar = LayoutBuilder(
      builder: (context, constraints) {
        final width = _widthOf(constraints);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: track),
              Positioned.fill(child: fill),
              if (tick != null)
                PositionedDirectional(
                  start:
                      width * tick!.clamp(0.0, 1.0) -
                      FrostedChromeMetrics.paceTick / 2,
                  top: -reach,
                  bottom: -reach,
                  child: const FrostedPaceTick(),
                ),
            ],
          ),
        );
      },
    );
    if (scaleStart != null || scaleEnd != null) {
      final caption = t.textTheme.labelMedium.line(
        FrostedChromeMetrics.overBarScale,
      );
      bar = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.overBarScaleGap,
        children: [
          bar,
          SizedBox(
            // Grown with large text: a 14 row cut 200% words in half.
            height: frostedGrownHeight(
              context,
              FrostedChromeMetrics.overBarScale,
              caption,
            ),
            child: Stack(
              children: [
                if (scaleStart != null)
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    child: _line(scaleStart!, caption),
                  ),
                if (scaleEnd != null)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    child: _line(scaleEnd!, caption),
                  ),
              ],
            ),
          ),
        ],
      );
    }
    if (dimmed) {
      bar = Opacity(opacity: _limitOffOpacity, child: bar);
    }
    return Semantics(
      label: label ?? '${(f * 100).round()}%',
      excludeSemantics: true,
      child: bar,
    );
  }
}

/// How tall a [FrostedMeter] stands.
enum FrostedMeterSize {
  /// 4 tall: a meter under a tile's figures.
  regular,

  /// 3 tall: a small pane's meter.
  small,
}

/// A pane's meter (`.meter`): 4 tall (3 in a small pane) on a white track,
/// the hue's band filling its share; over its budget, the budget's share
/// in the hue and the rest in the over red, 1 apart.
///
/// ```dart
/// FrostedMeter(0.92, hue: t.hues.orchid)
/// ```
class FrostedMeter extends StatelessWidget {
  /// Creates a [FrostedMeter].
  const FrostedMeter(
    this.fraction, {
    required this.hue,
    this.over = false,
    this.size = FrostedMeterSize.regular,
    this.label,
    super.key,
  });

  /// The share filled, 0 to 1: spent over budget, or over its budget the
  /// budget over what was spent.
  final double fraction;

  /// The fill's hue.
  final FrostedHue hue;

  /// Whether the pane is over its budget (`.meter--over`): no track, the
  /// rest in the over red.
  final bool over;

  /// How tall the meter stands: 4, or a small pane's 3.
  final FrostedMeterSize size;

  /// What a screen reader says; the percent when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final f = fraction.clamp(0.0, 1.0);
    final height = size == FrostedMeterSize.small
        ? FrostedChromeMetrics.meterSmall
        : FrostedChromeMetrics.meter;
    const full = Radius.circular(FrostedCorners.rFull);
    final Widget meter;
    if (over) {
      meter = LayoutBuilder(
        builder: (context, constraints) {
          final width = _widthOf(constraints);
          final room = math.max(0.0, width - FrostedChromeMetrics.meterGap);
          return SizedBox(
            width: width,
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: room * f,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: hue.band,
                      borderRadius: const BorderRadiusDirectional.horizontal(
                        start: full,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FrostedChromeMetrics.meterGap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.colorScheme.over,
                      borderRadius: const BorderRadiusDirectional.horizontal(
                        end: full,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      meter = SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.colorScheme.meterTrack,
            borderRadius: BorderRadius.circular(FrostedCorners.rFull),
          ),
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: f,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: hue.band,
                borderRadius: BorderRadius.circular(FrostedCorners.rFull),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: label ?? (over ? 'Over budget' : '${(f * 100).round()}%'),
      excludeSemantics: true,
      child: meter,
    );
  }
}

/// How tall a [FrostedBudgetBar] stands.
enum FrostedBudgetBarSize {
  /// 6 tall: a budget's bar in a row or a tile.
  regular,

  /// 10 tall (`.overbar--lg`): a category page's own bar.
  large,
}

/// A category over its budget as one bar (`.overbar`): the budget's share
/// of what was spent in the hue, the rest in the over red, 2 apart, and
/// under it the budget at the start and the amount over at the end.
///
/// ```dart
/// FrostedBudgetBar(spent: 286.40, budget: 250, hue: t.hues.coral)
/// ```
class FrostedBudgetBar extends StatelessWidget {
  /// Creates a [FrostedBudgetBar].
  const FrostedBudgetBar({
    required this.spent,
    required this.budget,
    required this.hue,
    this.size = FrostedBudgetBarSize.regular,
    this.scaleStart,
    this.scaleEnd,
    this.ink,
    this.label,
    super.key,
  });

  /// What was spent.
  final num spent;

  /// The budget.
  final num budget;

  /// The budget's hue.
  final FrostedHue hue;

  /// How tall the bar stands: 6, or a category page's 10 (`.overbar--lg`).
  final FrostedBudgetBarSize size;

  /// The budget caption's ink (`.ob-scale` inherits: the hero's ink, a
  /// card's quiet ink); the surrounding text's, else the page ink, when
  /// null. The amount over is always in the over ink.
  final Color? ink;

  /// The caption at the start; "Budget $250" when null.
  final String? scaleStart;

  /// The caption at the end; "+$36.40 over" when null and over.
  final String? scaleEnd;

  /// What a screen reader says.
  final String? label;

  bool get _over => spent > budget;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final over = _over;
    final f = over && spent > 0 ? (budget / spent).clamp(0.0, 1.0) : 1.0;
    final height = size == FrostedBudgetBarSize.large
        ? FrostedChromeMetrics.overBarLarge
        : FrostedChromeMetrics.overBar;
    const full = Radius.circular(FrostedCorners.rFull);
    const nick = Radius.circular(FrostedCorners.r2);
    final start =
        scaleStart ??
        'Budget ${FrostedFormat.money(budget, cents: budget % 1 != 0)}';
    final end =
        scaleEnd ??
        (over ? '+${FrostedFormat.money(spent - budget)} over' : null);
    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final width = _widthOf(constraints);
        final room = over
            ? math.max(0.0, width - FrostedChromeMetrics.overBarGap)
            : width;
        return SizedBox(
          width: width,
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: room * f,
                child: FrostedFace(
                  material: FrostedMaterial.paint,
                  radius: BorderRadiusDirectional.horizontal(
                    start: full,
                    end: over ? nick : full,
                  ).resolve(Directionality.of(context)),
                  gradients: [hue.band],
                ),
              ),
              if (over) ...[
                const SizedBox(width: FrostedChromeMetrics.overBarGap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.colorScheme.over,
                      borderRadius: const BorderRadiusDirectional.horizontal(
                        start: nick,
                        end: full,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
    final caption = t.textTheme.labelMedium
        .line(FrostedChromeMetrics.overBarScale)
        .c(
          ink ??
              DefaultTextStyle.of(context).style.color ??
              t.colorScheme.textPrimary,
        );
    return Semantics(
      label:
          label ??
          (over
              ? 'Over by ${FrostedFormat.money(spent - budget)}'
              : '${FrostedFormat.percent(spent, budget)}% of the budget'),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.overBarScaleGap,
        children: [
          bar,
          SizedBox(
            // Grown with large text: a 14 row cut 200% words in half.
            height: frostedGrownHeight(
              context,
              FrostedChromeMetrics.overBarScale,
              caption,
            ),
            child: Stack(
              children: [
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  child: _line(start, caption),
                ),
                if (end != null)
                  PositionedDirectional(
                    end: 0,
                    top: 0,
                    child: _line(
                      end,
                      caption.semibold.c(t.colorScheme.over),
                      // Its own "+$12.00 over" keeps the sign before the
                      // figure on a right-to-left page; given words keep
                      // the page's direction.
                      direction: scaleEnd == null ? TextDirection.ltr : null,
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
// Compare and merchant bars
// ---------------------------------------------------------------------------

/// One month of a [FrostedCompareBars] (`.cmp-r`): its name and amount on a
/// baseline over a tube, the budget's tick across it.
///
/// ```dart
/// FrostedCompareRow(name: 'September', amount: 263.10, fraction: 0.92, hue: t.hues.coral, tick: 0.87)
/// ```
class FrostedCompareRow extends StatelessWidget {
  /// Creates a [FrostedCompareRow].
  const FrostedCompareRow({
    required this.name,
    required this.amount,
    required this.fraction,
    required this.hue,
    this.tick,
    super.key,
  });

  /// The month's name.
  final String name;

  /// What the month spent.
  final num amount;

  /// The month's share of the larger month, 0 to 1.
  final double fraction;

  /// The category's hue.
  final FrostedHue hue;

  /// Where the budget stands, 0 to 1; null draws no tick.
  final double? tick;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      label: '$name, ${FrostedFormat.money(amount)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _compareRowGap,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: _compareHeadGap,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: t.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              FrostedAmount(amount, signed: false),
            ],
          ),
          FrostedBar(fraction, hue: hue, tick: tick),
        ],
      ),
    );
  }
}

/// A month against the month before (`.cmp`): each a [FrostedCompareRow] on
/// one scale, 16 apart, the budget's tick across both.
///
/// ```dart
/// FrostedCompareBars(children: [FrostedCompareRow(name: 'September', amount: 263.10, fraction: 263.10 / 286.40, hue: hue), FrostedCompareRow(name: 'October so far', amount: 241.80, fraction: 241.80 / 286.40, hue: hue)])
/// ```
class FrostedCompareBars extends StatelessWidget {
  /// Creates a [FrostedCompareBars].
  const FrostedCompareBars({required this.children, super.key});

  /// The months, the earlier first.
  final List<FrostedCompareRow> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: _compareGap,
    children: children,
  );
}

/// One merchant of a [FrostedMerchantBars] (`.merch`): its monogram, name
/// and visits, its amount at the end and its share as a thin bar under
/// them; a card of its own on the desktop. A link when [onPressed] is given.
///
/// ```dart
/// FrostedMerchant(name: 'Blue Fern Café', subtitle: '13 visits', amount: 84.25, fraction: 1, hue: t.hues.coral, onPressed: open)
/// ```
class FrostedMerchant extends StatelessWidget {
  /// Creates a [FrostedMerchant].
  const FrostedMerchant({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.fraction,
    required this.hue,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The merchant's name.
  final String name;

  /// Its second line: how many visits.
  final String subtitle;

  /// What was spent there.
  final num amount;

  /// Its share of the top merchant, 0 to 1.
  final double fraction;

  /// The category's hue.
  final FrostedHue hue;

  /// Opens the merchant's transactions; null makes the row inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final words = '$name, $subtitle, ${FrostedFormat.money(amount)}';
    final title = Text(
      name,
      style: t.textTheme.titleMedium.line(20),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    // .row-s { font: 400 14px/1.3 }: an 18.2 line.
    final second = Text(
      subtitle,
      style: t.textTheme.bodyMedium
          .c(t.colorScheme.textSecondary)
          .line(_partLine),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final bar = FrostedBar(fraction, hue: hue, variant: FrostedBarVariant.thin);
    final Widget body;
    if (wide) {
      body = FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(FrostedBreakpoints.innerRadius(context)),
        color: t.sheens.merchantCard,
        ring: frostedLitEdge(t, t.colorScheme.border),
        padding: const EdgeInsets.all(FrostedChromeMetrics.merchantCardInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedChromeMetrics.merchantCardGap,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FrostedMonogram(name, hue: hue),
                FrostedAmount(
                  amount,
                  signed: false,
                  size: FrostedAmountSize.large,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedChromeMetrics.rowLineGap,
              children: [title, second],
            ),
            bar,
          ],
        ),
      );
    } else {
      body = Padding(
        padding: const EdgeInsets.symmetric(
          vertical: FrostedChromeMetrics.merchantInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedChromeMetrics.merchantBarGap,
          children: [
            Row(
              spacing: FrostedChromeMetrics.merchantGap,
              children: [
                FrostedMonogram(name, hue: hue),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: FrostedChromeMetrics.rowLineGap,
                    children: [title, second],
                  ),
                ),
                FrostedAmount(amount, signed: false),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start:
                    FrostedChromeMetrics.mark +
                    FrostedChromeMetrics.merchantGap,
              ),
              child: bar,
            ),
          ],
        ),
      );
    }
    if (onPressed == null) {
      return Semantics(label: words, excludeSemantics: true, child: body);
    }
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: words,
      role: FrostedPressRole.link,
      radius: wide ? FrostedBreakpoints.innerRadius(context) : 0,
      child: body,
    );
  }
}

/// A category's merchants as bars (`.merchants`): each a [FrostedMerchant]
/// in falling order, rows 2 apart on a phone, cards four across on the
/// desktop.
///
/// ```dart
/// FrostedMerchantBars(children: [FrostedMerchant(name: 'Blue Fern Café', subtitle: '13 visits', amount: 84.25, fraction: 1, hue: hue), FrostedMerchant(name: 'Northside Market', subtitle: '6 visits', amount: 52.40, fraction: .62, hue: hue)])
/// ```
class FrostedMerchantBars extends StatelessWidget {
  /// Creates a [FrostedMerchantBars].
  const FrostedMerchantBars({required this.children, super.key});

  /// The merchants, the largest first.
  final List<FrostedMerchant> children;

  @override
  Widget build(BuildContext context) {
    if (!FrostedBreakpoints.isWide(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _merchantsGap,
        children: children,
      );
    }
    final gap = FrostedBreakpoints.gap(context);
    final rows = <List<Widget>>[];
    for (var i = 0; i < children.length; i += _merchantsAcross) {
      final row = children.sublist(
        i,
        math.min(i + _merchantsAcross, children.length),
      );
      rows.add([
        for (final merchant in row) Expanded(child: merchant),
        for (var k = row.length; k < _merchantsAcross; k++)
          const Expanded(child: SizedBox.shrink()),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        for (final row in rows)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: gap,
            children: row,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// In against out, the split
// ---------------------------------------------------------------------------

/// A month's money in against what went out (`.flow`): the two figures in
/// their columns, under them a small track of where the money went with
/// what was kept as its last band, and a line of captions under that.
///
/// ```dart
/// FrostedInOut(moneyIn: 6825, spent: 2486.12, bands: [FrostedBand(1150, hue: t.hues.periwinkle, name: 'Rent'), FrostedBand(412.36, hue: t.hues.orchid, name: 'Groceries')])
/// ```
class FrostedInOut extends StatelessWidget {
  /// Creates a [FrostedInOut].
  const FrostedInOut({
    required this.moneyIn,
    required this.spent,
    required this.bands,
    this.inCaption,
    this.outCaption,
    this.outSigned = false,
    this.note,
    this.keptWord,
    this.label,
    this.scaleGap = FrostedChromeMetrics.flowScaleGap,
    super.key,
  });

  /// What came in.
  final num moneyIn;

  /// What went out.
  final num spent;

  /// Where it went, each band's weight an amount; the kept band is added.
  final List<FrostedBand> bands;

  /// The caption over the money in.
  final String? inCaption;

  /// The caption over what went out.
  final String? outCaption;

  /// Whether the out figure carries a minus (an account's "Money out").
  final bool outSigned;

  /// The caption at the scale's start; "N% of what came in went to
  /// spending" when null.
  final String? note;

  /// The word before the kept amount at the scale's end: "Net", "Kept".
  final String? keptWord;

  /// What a screen reader says.
  final String? label;

  /// The room between the track and its captions: 8 inside a `.flow`, the
  /// scale's own 10 ([FrostedChromeMetrics.frostedScaleGap]) where the track
  /// stands loose in its tile (an account's `.flow-bar`).
  final double scaleGap;

  @override
  Widget build(BuildContext context) {
    final inCaption =
        this.inCaption ?? FrostedLocalizations.of(context).moneyIn;
    final outCaption =
        this.outCaption ?? FrostedLocalizations.of(context).spent;
    final keptWord = this.keptWord ?? FrostedLocalizations.of(context).net;
    final t = context.frostedTheme;
    final kept = moneyIn - spent;
    final share = moneyIn > 0 ? FrostedFormat.percent(spent, moneyIn) : 0;
    final words = note ?? '$share% of what came in went to spending';
    final net = '$keptWord ${FrostedFormat.money(kept, sign: true)}';
    return Semantics(
      label:
          label ??
          '$inCaption ${FrostedFormat.money(moneyIn, sign: true)}, '
              '$outCaption ${FrostedFormat.money(spent)}, $net',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.flowGap,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostedChromeMetrics.flowFiguresGap,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.flowFigureGap,
                  children: [
                    Text(inCaption, style: t.textTheme.labelMedium),
                    FrostedMoney(
                      moneyIn,
                      size: FrostedMoneySize.small,
                      flow: FrostedMoneyFlow.inflow,
                      sign: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.flowFigureGap,
                  children: [
                    Text(outCaption, style: t.textTheme.labelMedium),
                    FrostedMoney(
                      outSigned ? -spent : spent,
                      size: FrostedMoneySize.small,
                      flow: outSigned
                          ? FrostedMoneyFlow.outflow
                          : FrostedMoneyFlow.balance,
                      sign: outSigned,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: scaleGap,
            children: [
              FrostedTrack(
                size: FrostedTrackSize.small,
                bands: [
                  ...bands,
                  if (kept > 0)
                    FrostedBand(
                      kept,
                      variant: FrostedBandVariant.kept,
                      name: FrostedLocalizations.of(context).kept,
                    ),
                ],
              ),
              // From 1.2 the net stands under the words: across from them
              // its figure lost its tail ("Net +$4,3", self-review round 3).
              if (MediaQuery.textScalerOf(context).scale(1) >=
                  FrostedChromeMetrics.actionBarStackScale)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.statementLabelsGap,
                  children: [
                    Text(words, style: t.textTheme.labelMedium),
                    Text(
                      net,
                      style: t.textTheme.labelMedium.c(t.colorScheme.moneyIn),
                    ),
                  ],
                )
              else
                FrostedScale(
                  start: Text(words, style: t.textTheme.labelMedium),
                  trailing: _line(
                    net,
                    t.textTheme.labelMedium.c(t.colorScheme.moneyIn),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One share of a [FrostedSplitBar]: whose and how much.
///
/// ```dart
/// FrostedShare('Jonah', 14)
/// ```
@immutable
final class FrostedShare {
  /// Creates a [FrostedShare].
  const FrostedShare(this.name, this.amount);

  /// Whose share it is.
  final String name;

  /// The share's amount.
  final num amount;
}

/// A split's shares as one track of the purchase's hue (`.prism-split`),
/// each share's name and amount inside its band, the first at its start
/// and the others at their ends.
///
/// ```dart
/// FrostedSplitBar(hue: t.hues.lemon, shares: [FrostedShare('You', 14), FrostedShare('Jonah', 14)])
/// ```
class FrostedSplitBar extends StatelessWidget {
  /// Creates a [FrostedSplitBar].
  const FrostedSplitBar({
    required this.hue,
    required this.shares,
    this.label,
    super.key,
  });

  /// The purchase's hue.
  final FrostedHue hue;

  /// The shares, the owner's first.
  final List<FrostedShare> shares;

  /// What a screen reader says; the shares when null.
  final String? label;

  @override
  Widget build(BuildContext context) => FrostedTrack(
    label:
        label ??
        shares
            .map((s) => '${s.name} ${FrostedFormat.money(s.amount)}')
            .join(', '),
    bands: [
      for (var i = 0; i < shares.length; i++)
        FrostedBand(
          shares[i].amount,
          hue: hue,
          name: shares[i].name,
          label: FrostedSegmentLabel(
            shares[i].name,
            FrostedFormat.money(shares[i].amount),
            align: i == 0 ? FrostedSegmentAlign.start : FrostedSegmentAlign.end,
          ),
        ),
    ],
  );
}

// ---------------------------------------------------------------------------
// The statement timeline, the visit strip, the due line
// ---------------------------------------------------------------------------

/// A statement's last payment, closing and due day on one rule (`.stl`),
/// spaced by their dates: a pearl bead where it was paid, an ink ring where
/// it closed, a faint ring where it is due; each with its caption and
/// amount under it.
///
/// ```dart
/// FrostedStatementTimeline(paid: DateTime(2026, 10, 12), closed: DateTime(2026, 10, 28), due: DateTime(2026, 11, 12), paidAmount: 1180.22, closedAmount: 1326.44)
/// ```
class FrostedStatementTimeline extends StatelessWidget {
  /// Creates a [FrostedStatementTimeline].
  const FrostedStatementTimeline({
    required this.paid,
    required this.closed,
    required this.due,
    required this.paidAmount,
    required this.closedAmount,
    this.dueLabel,
    this.label,
    super.key,
  });

  /// When the last payment went.
  final DateTime paid;

  /// When the statement closed.
  final DateTime closed;

  /// When it is due.
  final DateTime due;

  /// What was paid.
  final num paidAmount;

  /// The statement's balance.
  final num closedAmount;

  /// The word under the due day: how it will be paid.
  final String? dueLabel;

  /// What a screen reader says.
  final String? label;

  double get _closedAt {
    final span = due.difference(paid).inDays;
    if (span <= 0) return 0.5;
    return (closed.difference(paid).inDays / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = this.dueLabel ?? FrostedLocalizations.of(context).autopay;
    final t = context.frostedTheme;
    final at = _closedAt;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const bead = FrostedChromeMetrics.statementBead;
    Widget beadAt(double f, double width, Widget dot) => PositionedDirectional(
      start: width * f - bead / 2,
      top: 0,
      child: SizedBox(width: bead, height: bead, child: dot),
    );
    final paidDot = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: t.hues.iris.dot,
      ),
    );
    final closedDot = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.sheens.bead,
        border: Border.all(
          color: t.colorScheme.textPrimary,
          width: _statementClosedRing,
        ),
      ),
    );
    final dueDot = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.sheens.bead,
        border: Border.fromBorderSide(
          BorderSide(color: t.sheens.beadRing, width: _statementDueRing),
        ),
      ),
    );
    Widget words(String cap, Widget amount, CrossAxisAlignment align) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      spacing: FrostedChromeMetrics.statementLabelLineGap,
      children: [
        Text(cap, style: t.textTheme.labelMedium),
        amount,
      ],
    );
    final paidWords = words(
      'Paid ${FrostedFormat.date(paid)}',
      FrostedAmount(paidAmount, signed: false, textAlign: TextAlign.start),
      CrossAxisAlignment.start,
    );
    final closedWords = words(
      'Closed ${FrostedFormat.date(closed)}',
      FrostedAmount(closedAmount, signed: false, textAlign: TextAlign.center),
      CrossAxisAlignment.center,
    );
    final dueWords = words(
      'Due ${FrostedFormat.date(due)}',
      Text(dueLabel, style: t.textTheme.amount),
      CrossAxisAlignment.end,
    );
    // Large text stands the three one under another: side by side at 200%
    // they ran into each other (self-review round 2).
    final stack =
        MediaQuery.textScalerOf(context).scale(1) >=
        FrostedChromeMetrics.actionBarStackScale;
    final stacked = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostedChromeMetrics.statementLabelsGap,
      children: [
        paidWords,
        words(
          'Closed ${FrostedFormat.date(closed)}',
          FrostedAmount(
            closedAmount,
            signed: false,
            textAlign: TextAlign.start,
          ),
          CrossAxisAlignment.start,
        ),
        words(
          'Due ${FrostedFormat.date(due)}',
          Text(dueLabel, style: t.textTheme.amount),
          CrossAxisAlignment.start,
        ),
      ],
    );
    return Semantics(
      label:
          label ??
          'Paid ${FrostedFormat.money(paidAmount)} on '
              '${FrostedFormat.date(paid)}, closed ${FrostedFormat.date(closed)} '
              'at ${FrostedFormat.money(closedAmount)}, due '
              '${FrostedFormat.date(due)}, $dueLabel',
      excludeSemantics: true,
      // .stl-x { margin: 10px 0 10px }: the words 10 under the line and 10
      // over what follows. The line's own 2 over (`.stl { margin-top: 2px
      // }`) collapses into the head's 12 in the source's block flow, so it
      // adds nothing under a tile's head.
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: FrostedChromeMetrics.statementLabelsGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FrostedChromeMetrics.statementLabelsGap,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedChromeMetrics.statementLineInset,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = _widthOf(constraints);
                  return SizedBox(
                    width: width,
                    height: FrostedChromeMetrics.statementLine,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          top: FrostedChromeMetrics.statementRuleTop,
                          height: FrostedChromeMetrics.outline,
                          child: ColoredBox(color: t.sheens.rule),
                        ),
                        beadAt(0, width, paidDot),
                        beadAt(at, width, closedDot),
                        beadAt(1, width, dueDot),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (stack)
              stacked
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = _widthOf(constraints);
                  return SizedBox(
                    width: width,
                    height: FrostedChromeMetrics.statementLabels,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PositionedDirectional(
                          start: 0,
                          top: 0,
                          child: paidWords,
                        ),
                        PositionedDirectional(
                          start: width * at,
                          top: 0,
                          child: FractionalTranslation(
                            translation: Offset(rtl ? 0.5 : -0.5, 0),
                            child: closedWords,
                          ),
                        ),
                        PositionedDirectional(end: 0, top: 0, child: dueWords),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A merchant's visits across a month (`.strip`): a rule with a tick for
/// each day, a dot of the hue on each day visited (stacked when more than
/// one), the record's own visit a white dot ringed in the hue, and the
/// month's first, middle and last day under it (Today in the last's place
/// while the month runs).
///
/// ```dart
/// FrostedVisitStrip(month: DateTime(2026, 9), visits: [DateTime(2026, 9, 29)], current: DateTime(2026, 9, 29), hue: t.hues.coral)
/// ```
class FrostedVisitStrip extends StatelessWidget {
  /// Creates a [FrostedVisitStrip].
  const FrostedVisitStrip({
    required this.month,
    required this.visits,
    required this.hue,
    this.current,
    this.now,
    this.label,
    super.key,
  });

  /// Any day of the month shown.
  final DateTime month;

  /// The days visited.
  final List<DateTime> visits;

  /// The merchant's hue.
  final FrostedHue hue;

  /// The record's own visit, drawn as the white dot.
  final DateTime? current;

  /// Today, labelled in the month end's place when it falls in the month.
  final DateTime? now;

  /// What a screen reader says.
  final String? label;

  int get _days => DateTime(month.year, month.month + 1, 0).day;

  bool _inMonth(DateTime d) => d.year == month.year && d.month == month.month;

  @override
  Widget build(BuildContext context) => Directionality(
    // A month's days run left to right in any language, as every chart's
    // time axis does.
    textDirection: TextDirection.ltr,
    child: Builder(builder: _ltrBuild),
  );

  Widget _ltrBuild(BuildContext context) {
    final t = context.frostedTheme;
    final days = _days;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final counts = <int, int>{};
    for (final v in visits) {
      if (_inMonth(v)) counts[v.day] = (counts[v.day] ?? 0) + 1;
    }
    final thisDay = current != null && _inMonth(current!) ? current!.day : null;
    final short = FrostedFormat.month(month, short: true);
    final captions = t.textTheme.labelMedium.line(
      FrostedChromeMetrics.stripLabels,
    );
    double at(num day) => (day - 0.5) / days;
    Widget dot(bool own) => own
        ? SizedBox(
            width: FrostedChromeMetrics.stripDotThis,
            height: FrostedChromeMetrics.stripDotThis,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.sheens.bead,
                border: Border.all(
                  color: hue.b,
                  width: FrostedChromeMetrics.stripDotRing,
                ),
              ),
            ),
          )
        : SizedBox(
            width: FrostedChromeMetrics.stripDot,
            height: FrostedChromeMetrics.stripDot,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hue.dot,
              ),
            ),
          );
    Widget centred(double f, double width, Widget child) =>
        PositionedDirectional(
          start: width * f,
          top: 0,
          child: FractionalTranslation(
            translation: Offset(rtl ? 0.5 : -0.5, 0),
            child: child,
          ),
        );
    return Semantics(
      label:
          label ??
          '${FrostedFormat.plural(visits.length, 'visit')} in '
              '${FrostedFormat.month(month)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.stripLabelsGap,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = _widthOf(constraints);
              return SizedBox(
                width: width,
                height: FrostedChromeMetrics.strip,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: FrostedChromeMetrics.stripRuleBottom,
                      height: FrostedChromeMetrics.outline,
                      child: ColoredBox(color: t.sheens.stripRule),
                    ),
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      height: FrostedChromeMetrics.stripTick,
                      child: Row(
                        children: [
                          for (var d = 0; d < days; d++)
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  width: FrostedChromeMetrics.outline,
                                  height: FrostedChromeMetrics.stripTick,
                                  child: ColoredBox(color: t.sheens.stripTick),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final entry in counts.entries)
                      PositionedDirectional(
                        start:
                            width * at(entry.key) -
                            FrostedChromeMetrics.stripDotThis / 2,
                        bottom: FrostedChromeMetrics.stripDotBottom,
                        width: FrostedChromeMetrics.stripDotThis,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          verticalDirection: VerticalDirection.up,
                          spacing: FrostedChromeMetrics.stripDotGap,
                          children: [
                            for (var i = 0; i < entry.value; i++)
                              dot(i == 0 && entry.key == thisDay),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = _widthOf(constraints);
              return SizedBox(
                width: width,
                height: FrostedChromeMetrics.stripLabels,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      child: _line('$short 1', captions),
                    ),
                    centred(at(15), width, _line('15', captions)),
                    // screens.py visit_strip(): the month's last day, or
                    // Today in its place in the month that is running (both
                    // drew over each other at a month's end).
                    if (now == null || !_inMonth(now!))
                      PositionedDirectional(
                        end: 0,
                        top: 0,
                        child: _line('$short $days', captions),
                      )
                    else
                      centred(
                        at(now!.day),
                        width,
                        _line(
                          DesignLocalizations.of(context).currentDateLabel,
                          captions.semibold.c(t.colorScheme.textPrimary),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The month between two due days on a pane's floor (`.due-line`): a rule
/// in the pane's ink from a dot of the hue (paid) to a white dot ringed in
/// it (due next), their words under each end.
///
/// ```dart
/// FrostedDueLine(hue: t.hues.periwinkle, start: 'Paid Oct 1', end: 'Next due Nov 1')
/// ```
class FrostedDueLine extends StatelessWidget {
  /// Creates a [FrostedDueLine].
  const FrostedDueLine({
    required this.hue,
    required this.start,
    required this.end,
    this.ink,
    super.key,
  });

  /// The pane's hue.
  final FrostedHue hue;

  /// The words under the first dot.
  final String start;

  /// The words under the second dot.
  final String end;

  /// The rule's and the words' ink; the surrounding text's, else the
  /// hue's ink, when null.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final color = ink ?? DefaultTextStyle.of(context).style.color ?? hue.ink;
    final words = t.textTheme.labelSmall
        .line(15)
        .c(color.withValues(alpha: color.a * _dueWordsOpacity));
    const bead = FrostedChromeMetrics.dueBead;
    return Semantics(
      label: '$start, $end',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.paneFloorGap,
        children: [
          SizedBox(
            height: FrostedChromeMetrics.dueLine,
            child: Stack(
              children: [
                PositionedDirectional(
                  start: FrostedChromeMetrics.dueInset,
                  end: FrostedChromeMetrics.dueInset,
                  top:
                      (FrostedChromeMetrics.dueLine -
                          FrostedChromeMetrics.outline) /
                      2,
                  height: FrostedChromeMetrics.outline,
                  child: ColoredBox(
                    color: color.withValues(alpha: color.a * _dueRuleOpacity),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: bead,
                      height: bead,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hue.dot,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: bead,
                      height: bead,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.sheens.arriveRing,
                          border: Border.all(color: hue.a, width: _dueBeadRing),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: FrostedChromeMetrics.dueLabelGap,
            children: [
              Flexible(child: _line(start, words)),
              Flexible(child: _line(end, words, align: TextAlign.end)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance changes
// ---------------------------------------------------------------------------

/// One account a move touches (`.chg`): its token, name and the amount
/// moved, its balance after over the one before struck through, and a
/// least track of the balance with the part leaving faint or the part
/// arriving bright at its end.
///
/// ```dart
/// FrostedBalanceChange(name: 'Everyday', icon: FrostedGlyphs.wallet, hue: t.hues.cyan, before: 6248.30, after: 5748.30)
/// ```
class FrostedBalanceChange extends StatelessWidget {
  /// Creates a [FrostedBalanceChange].
  const FrostedBalanceChange({
    required this.name,
    required this.icon,
    required this.hue,
    required this.before,
    required this.after,
    super.key,
  });

  /// The account's name.
  final String name;

  /// The account's glyph.
  final IconData icon;

  /// The account's hue.
  final FrostedHue hue;

  /// Its balance before the move.
  final num before;

  /// Its balance after.
  final num after;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final delta = after - before;
    final leaving = delta < 0;
    final moved = delta.abs();
    return Semantics(
      label:
          '$name, ${FrostedFormat.money(delta, sign: true)}, from '
          '${FrostedFormat.money(before)} to ${FrostedFormat.money(after)}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FrostedChromeMetrics.changeGap,
        children: [
          Row(
            spacing: FrostedChromeMetrics.changeHeadGap,
            children: [
              FrostedIconMark(icon, hue: hue),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.rowLineGap,
                  children: [
                    Text(
                      name,
                      style: t.textTheme.titleMedium.line(20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      FrostedFormat.money(delta, sign: true),
                      // "+$12.00", never "$12.00+".
                      textDirection: TextDirection.ltr,
                      style: t.textTheme.bodyMedium.c(
                        t.colorScheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: FrostedChromeMetrics.changeValueGap,
                children: [
                  Text(
                    FrostedFormat.money(before),
                    style: t.textTheme.labelMedium.copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: t.sheens.struck,
                    ),
                  ),
                  FrostedAmount(after, signed: false),
                ],
              ),
            ],
          ),
          FrostedTrack(
            size: FrostedTrackSize.extraSmall,
            label: leaving
                ? '${FrostedFormat.money(moved)} leaving'
                : '${FrostedFormat.money(moved)} arriving',
            bands: leaving
                ? [
                    FrostedBand(after, hue: hue, name: name),
                    FrostedBand(
                      moved,
                      hue: hue,
                      variant: FrostedBandVariant.leave,
                      name: 'leaving',
                    ),
                  ]
                : [
                    FrostedBand(before, hue: hue, name: name),
                    FrostedBand(
                      moved,
                      hue: hue,
                      variant: FrostedBandVariant.arrive,
                      name: 'arriving',
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}

/// The accounts a move touches, each a [FrostedBalanceChange], a hairline
/// between them (`.chg + .chg`): a review's or a receipt's Balances now.
///
/// ```dart
/// FrostedBalanceChanges(children: [FrostedBalanceChange(name: 'Everyday', icon: FrostedGlyphs.wallet, hue: t.hues.cyan, before: 6248.30, after: 5748.30), FrostedBalanceChange(name: 'Savings', icon: FrostedGlyphs.wallet, hue: t.hues.mint, before: 12400, after: 12900)])
/// ```
class FrostedBalanceChanges extends StatelessWidget {
  /// Creates a [FrostedBalanceChanges].
  const FrostedBalanceChanges({required this.children, super.key});

  /// The accounts, the one the money left first.
  final List<FrostedBalanceChange> children;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i == 0
                  ? null
                  : Border(
                      top: BorderSide(
                        color: t.colorScheme.border,
                        width: FrostedChromeMetrics.outline,
                      ),
                    ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: i == 0
                    ? FrostedChromeMetrics.changeTop
                    : FrostedChromeMetrics.changeBottom,
                bottom: i == 0 ? FrostedChromeMetrics.changeBottom : 0,
              ),
              child: children[i],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The route beam, the done mark
// ---------------------------------------------------------------------------

/// A move's route at the head of its review (`.route`): the source's
/// large token, a beam from its hue through the prism's lavender to the
/// destination's with an arrow in the middle, and the destination's token.
///
/// ```dart
/// FrostedRoute(fromName: 'Everyday', fromIcon: FrostedGlyphs.wallet, fromHue: t.hues.cyan, toName: 'Savings', toIcon: FrostedGlyphs.landmark, toHue: t.hues.seafoam)
/// ```
class FrostedRoute extends StatelessWidget {
  /// Creates a [FrostedRoute].
  const FrostedRoute({
    required this.fromName,
    required this.fromIcon,
    required this.fromHue,
    required this.toName,
    required this.toIcon,
    required this.toHue,
    this.glyph = FrostedGlyphs.arrowRight,
    this.label,
    super.key,
  });

  /// Where the money comes from.
  final String fromName;

  /// The source's glyph.
  final IconData fromIcon;

  /// The source's hue.
  final FrostedHue fromHue;

  /// Where the money goes.
  final String toName;

  /// The destination's glyph.
  final IconData toIcon;

  /// The destination's hue.
  final FrostedHue toHue;

  /// The glyph between the beams.
  final IconData glyph;

  /// What a screen reader says; "From X to Y" when null.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final mid = t.hues.iris.a;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget beam(Color from, Color to) => SizedBox(
      width: FrostedChromeMetrics.routeBeam.width,
      height: FrostedChromeMetrics.routeBeam.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FrostedCorners.r2),
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [from, to],
          ),
        ),
      ),
    );
    return Semantics(
      label: label ?? FrostedLocalizations.of(context).fromTo(fromName, toName),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: FrostedChromeMetrics.routeBottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: FrostedChromeMetrics.routeGap,
          children: [
            FrostedIconMark(
              fromIcon,
              hue: fromHue,
              size: FrostedMarkSize.large,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: FrostedChromeMetrics.routeLineGap,
              children: [
                beam(fromHue.b, mid),
                // Points the way of the move: a glyph that mirrors itself
                // (the default arrow) was turned back by a second flip.
                Transform.flip(
                  flipX: rtl && !glyph.matchTextDirection,
                  child: Icon(
                    glyph,
                    size: FrostedChromeMetrics.routeGlyph,
                    color: t.colorScheme.textSecondary,
                  ),
                ),
                beam(mid, toHue.a),
              ],
            ),
            FrostedIconMark(toIcon, hue: toHue, size: FrostedMarkSize.large),
          ],
        ),
      ),
    );
  }
}

/// The mark at the head of a finished flow's page (`.done-art`): four rings
/// of the spectrum fading outward over a soft glow, the check on the ink
/// act in a white halo in the middle; 200 across, pulled 12 into the head
/// above and 4 into the words below.
///
/// ```dart
/// FrostedDoneMark()
/// ```
class FrostedDoneMark extends StatelessWidget {
  /// Creates a [FrostedDoneMark].
  const FrostedDoneMark({
    this.glyph = FrostedGlyphs.check,
    this.label,
    super.key,
  });

  /// The glyph on the act.
  final IconData glyph;

  /// What a screen reader says.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final label = this.label ?? FrostedLocalizations.of(context).done;
    final t = context.frostedTheme;
    const art = FrostedChromeMetrics.doneArt;
    const pull =
        FrostedChromeMetrics.doneArtPullTop +
        FrostedChromeMetrics.doneArtPullBottom;
    // The art stands 200 tall but takes 16 less in the column: its top 12
    // above the box and its foot 4 below.
    final alignY =
        (-FrostedChromeMetrics.doneArtPullTop * 2) / (art - pull - art) - 1;
    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: art - pull,
        child: OverflowBox(
          alignment: Alignment(0, alignY),
          minHeight: art,
          maxHeight: art,
          minWidth: art,
          maxWidth: art,
          child: SizedBox(
            width: art,
            height: art,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _DoneRings()),
                Center(
                  child: SizedBox(
                    width: FrostedChromeMetrics.doneCheck,
                    height: FrostedChromeMetrics.doneCheck,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: t.colorScheme.buttonFill,
                        boxShadow: [
                          BoxShadow(
                            color: t.sheens.halo,
                            spreadRadius: FrostedChromeMetrics.doneCheckRing,
                          ),
                          ...t.shadows.button,
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          glyph,
                          size: FrostedChromeMetrics.doneCheckGlyph,
                          color: t.colorScheme.onButton,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The done mark's rings (`.done-rings`): the SVG's glow and its four
/// strokes of the spectrum, drawn at the box's size.
class _DoneRings extends CustomPainter {
  const _DoneRings();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _doneRingsBox;
    final centre = size.center(Offset.zero);
    final half = _doneRingsBox / 2 * scale;
    canvas.drawCircle(
      centre,
      half,
      Paint()
        ..shader = RadialGradient(
          colors: [_doneGlow, _doneGlow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: half)),
    );
    final shader =
        LinearGradient(
          colors: _doneRingStops,
          stops: const [0, 0.5, 1],
        ).createShader(
          Rect.fromLTWH(20 * scale, 20 * scale, 200 * scale, 200 * scale),
        );
    for (var i = 0; i < _doneRingRadii.length; i++) {
      canvas.drawCircle(
        centre,
        _doneRingRadii[i] * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _doneRingStroke * scale
          ..shader = shader
          ..color = const Color(0xFF000000)
              .withValues(alpha: _doneRingOpacities[i]),
      );
    }
  }

  @override
  bool shouldRepaint(_DoneRings oldDelegate) => false;
}
