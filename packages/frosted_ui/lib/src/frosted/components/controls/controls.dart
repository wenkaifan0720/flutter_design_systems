import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/bleed.dart';
import '../../internal/css_shadow.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/key_focus.dart';
import '../../internal/measure.dart';
import '../../internal/own_size.dart';
import '../../internal/press_face.dart';
import '../../internal/sliding_pill.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../structure/structure.dart';
import '../../localizations.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';
import '../../internal/chosen_plate.dart';

import 'package:ui_core/ui_core.dart';

// metric: `.switch .arr.off { opacity: .6 }`, the month switch's arrow with
// nowhere to go (no FrostedChromeMetrics constant names it).
const double _monthArrowOffOpacity = 0.6;

// metric: `.field .seg-ctl span { font-size: 14px }`, the filled segmented
// control's word (FrostedChromeMetrics names its height, not its size).
const double _segmentFillWord = 14;

// metric: `.qamts { grid-template-columns: repeat(3, minmax(0, 1fr)) }`,
// the quick amounts' columns (FrostedChromeMetrics names the gap, not the
// count).
const int _quickAmountColumns = 3;

// metric: from 600 up a quick amount stands at least 112 wide,
// about what a phone's three take of a 358 column; the cells stay equal, as
// wide as the widest amount and its line.
const double _quickAmountWide = 112;

// metric: from 600 up an icon well is 52 wide, about square on its 44
// height, as a phone's six share a 358 column.
const double _iconWellWide = 52;

// metric: from 600 up a quick action is at least 84 wide, as a phone's four
// share a 358 column.
const double _quickActionWide = 84;

// metric: from 600 up a way to move money is at least 240 wide; the two of
// a row equal, as wide as the widest word and line.
const double _moveActWide = 240;

/// From 600 up a group of choices or actions keeps to its
/// content: its cells as wide as the widest of them, the group at the
/// line's start rather than drawn across the column. Below 600 it is
/// [child] as it is, its cells sharing the width.
Widget _ownWidth(BuildContext context, Widget child) =>
    MediaQuery.sizeOf(context).width < frostedMeasureFrom
    ? child
    : Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: IntrinsicWidth(child: child),
      );

/// A hairline ring just outside a white or glass face, taking no room, as the tiles draw it; [color] in
/// place of the glass edge, at the theme's regular stroke.
BoxShadow _edge(FrostedThemeData t, [Color? color]) =>
    frostedShadow(color: color ?? t.glass.edge, spread: FrostedStrokes.regular);

/// A field's label over a choice group a form labels (12 point medium in
/// the secondary ink), 8 over it.
class _Labelled extends StatelessWidget {
  const _Labelled(this.label, {required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: FrostedChromeMetrics.fieldLabelGap,
    children: [
      ExcludeSemantics(
        child: Text(
          label,
          style: context.frostedTheme.textTheme.labelSmall.line(15.6),
        ),
      ),
      child,
    ],
  );
}

// ---------------------------------------------------------------------------
// Filter chips
// ---------------------------------------------------------------------------

/// One chip of a [FrostedFilterChipGroup]: the [value] it stands for, its [label],
/// and the walkthrough [key] set on its hit target.
@immutable
class FrostedFilterOption<T> {
  /// Creates a [FrostedFilterOption].
  const FrostedFilterOption(this.value, this.label, {this.key});

  /// What choosing it sets.
  final T value;

  /// The chip's words.
  final String label;

  /// The walkthrough key set on the chip's hit target.
  final Key? key;
}

/// One choice among a row of pill chips that scopes the list under it (All,
/// Unread, Starred, Archived): each 32 tall on the faint glass with its
/// hairline ring, 4 apart; the chosen one on thicker, brighter glass of its
/// own, which fades in where the chip stands (nothing slides between the
/// chips). On a phone the row runs on under the page's gutters and scrolls; on the
/// desktop it takes its own width. The page
/// owns [value]; a null [onChanged] leaves the row inert. A screen reader hears
/// a group named [semanticLabel] of buttons, the chosen one selected.
///
/// ```dart
/// FrostedFilterChipGroup(options: const [FrostedFilterOption('all', 'All'), FrostedFilterOption('in', 'Money in'), FrostedFilterOption('out', 'Money out')], value: scope, onChanged: (v) => setState(() => scope = v))
/// ```
class FrostedFilterChipGroup<T> extends StatelessWidget {
  /// Creates a [FrostedFilterChipGroup].
  const FrostedFilterChipGroup({
    required this.options,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  /// The chips, in order.
  final List<FrostedFilterOption<T>> options;

  /// The chosen chip's value.
  final T value;

  /// Called with the chip chosen; null leaves the chips inert.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls the row.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? FrostedLocalizations.of(context).filters;
    final t = context.frostedTheme;
    // The chips' words grow with the reader's text, the pill by their extra
    // line, so they never fill it to the rim.
    final height = frostedGrownHeight(
      context,
      FrostedChromeMetrics.filterChip,
      t.textTheme.labelSmall,
    );
    Widget chip(FrostedFilterOption<T> item) {
      final on = item.value == value;
      // .fchip { height: 32px; padding: 0 10px; border-radius: 999px;
      //   background: rgba(255,255,255,.62);
      //   box-shadow: inset 0 0 0 1px rgba(21,21,45,.07);  (--line)
      //   font: 500 12px/1 var(--font-t); color: var(--ink-2) }
      // .fchip.on { background: var(--ink-fill); color: #fff;
      //   box-shadow: var(--ink-lift); font-weight: 600 }
      //   (--ink-lift: inset 0 1px 0 rgba(255,255,255,.14), the act's sheen,
      //   over 0 8px 18px -12px rgba(21,21,29,.7))
      // Each chip is a capsule of glass of its own and carries its own
      // chosen face: the chips are separate things, so nothing travels
      // between them. Choosing one fades its chosen glass in where it
      // stands (the thicker, brighter glass, raised off the row: no
      // outline) while the chip left fades back to its faint glass.
      final round = BorderRadius.circular(height / 2);
      // A chip is at least its touch target wide (the floor, 40), its
      // words centred: a short one ("All") in a wider target stood 6 past
      // the line's keyline, and its neighbours 12 further off.
      final face = Container(
        height: height,
        constraints: BoxConstraints(
          minWidth: FrostedBreakpoints.hitTargetOf(context),
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: FrostedFade(
                opacity: on ? 0 : 1,
                child: FrostedFace(
                  material: FrostedMaterial.pane,
                  radius: round,
                  ring: frostedLitEdge(t, t.colorScheme.border),
                ),
              ),
            ),
            Positioned.fill(
              child: FrostedFade(
                opacity: on ? 1 : 0,
                child: FrostedChosenPlate(radius: round),
              ),
            ),
            // The chip's box, as the alignment checks read it: the words
            // on its middle.
            FrostedFace(
              material: FrostedMaterial.paint,
              radius: round,
              padding: const EdgeInsets.symmetric(
                horizontal: FrostedChromeMetrics.filterChipInset,
              ),
              child: Center(
                widthFactor: 1,
                child: FrostedEase<TextStyle>(
                  value: on
                      ? t.textTheme.labelSmall.semibold.c(
                          t.colorScheme.textPrimary,
                        )
                      : t.textTheme.labelSmall.c(t.colorScheme.textSecondary),
                  lerp: FrostedEase.words,
                  builder: (context, words) => frostedCapCentredSnapped(
                    Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      style: words,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return FrostedPressable(
        key: item.key,
        onPressed: onChanged == null ? null : () => onChanged!(item.value),
        semanticLabel: item.label,
        selected: on,
        radius: height / 2,
        child: face,
      );
    }

    final chips = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: FrostedChromeMetrics.filterChipGap,
      children: [for (final item in options) chip(item)],
    );
    // The row scrolls within its line, but a chip's glow, the chosen chip's
    // lift and a focus ring reach past it: its viewport stands
    // [FrostedChromeMetrics.stripReach] out above and below (and at its ends
    // on a desk), so it clips only what scrolls away, never a chip's shadow.
    const reach = FrostedChromeMetrics.stripReach;
    final Widget row;
    if (FrostedBreakpoints.isWide(context)) {
      row = LayoutBuilder(
        builder: (context, box) => box.hasBoundedWidth
            ? FrostedBleed(
                reach: reach,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(reach),
                  child: chips,
                ),
              )
            : chips,
      );
    } else {
      final gutter = FrostedBreakpoints.gutter(context);
      // The line stands as tall as a chip's touch target (the floor, 40),
      // the 32 chips centred in it; the viewport reaches past the
      // line only as far as the shadows reach past the targets.
      final lane = math.max(height, FrostedBreakpoints.hitTargetOf(context));
      final past = math.max(0.0, reach - (lane - height) / 2);
      // The row runs on under the page's gutters to the screen's edges, as
      // the source's does, the gutter its own padding: the first chip stands
      // on the keyline at rest, and one scrolled under a gutter is drawn,
      // tapped and outlined there.
      row = FrostedBleed(
        reach: past,
        across: gutter,
        child: SizedBox(
          height: lane + 2 * past,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter, vertical: past),
            child: chips,
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: FrostedDim(off: onChanged == null, child: row),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedFilterOption<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

// ---------------------------------------------------------------------------
// Segmented control
// ---------------------------------------------------------------------------

/// One segment of a [FrostedSegmentedButton]: the [value] it stands for, its
/// [label], and the walkthrough [key] set on its hit target.
@immutable
class FrostedButtonSegment<T> {
  /// Creates a [FrostedButtonSegment].
  const FrostedButtonSegment(this.value, this.label, {this.key});

  /// What choosing it sets.
  final T value;

  /// The segment's words.
  final String label;

  /// The walkthrough key set on the segment's hit target.
  final Key? key;
}

/// One choice among a few words in a pill of the wash (1M, 3M, 1Y, All; Today,
/// Tomorrow, Choose a date): each segment 26 tall and at least 36 wide, the
/// chosen one raised on a white face with its hairline edge and soft shadow;
/// [fill] is a form field's, the segments 36 tall and, below 600
/// wide, sharing the field's width (from 600 up every strip keeps to its
/// segments, at the line's start), and [labelled] writes [label] over it as the
/// field's label. The page owns [value]; a null [onChanged] leaves it inert. A
/// screen reader hears a group named [label] of buttons, the chosen one
/// selected.
///
/// ```dart
/// FrostedSegmentedButton(segments: const [FrostedButtonSegment('1m', '1M'), FrostedButtonSegment('3m', '3M'), FrostedButtonSegment('1y', '1Y'), FrostedButtonSegment('all', 'All')], value: range, onChanged: (v) => setState(() => range = v), label: 'Range')
/// ```
class FrostedSegmentedButton<T> extends StatelessWidget {
  /// Creates a [FrostedSegmentedButton].
  const FrostedSegmentedButton({
    required this.segments,
    required this.value,
    required this.onChanged,
    required this.label,
    this.fill = false,
    this.labelled = false,
    this.style,
    super.key,
  });

  /// The segments, in order.
  final List<FrostedButtonSegment<T>> segments;

  /// The chosen segment's value.
  final T value;

  /// Called with the segment chosen; null leaves it inert.
  final ValueChanged<T>? onChanged;

  /// What a screen reader calls the control (Range, When, Split).
  final String label;

  /// Whether the pill is a form field: its segments 36 tall, and the pill
  /// takes the field's width at every size, as a form's other fields do.
  /// The segments share it equally while each label fits its share, else
  /// each gets its label's width and an equal share of the rest; the
  /// choices stack when their labels need more room. Without it the pill
  /// keeps to its segments.
  final bool fill;

  /// Whether [label] is written over the pill as a field's label (When,
  /// Split).
  final bool labelled;

  /// This control's own style, over
  /// `FrostedThemeData.components.segmentedButton`: each segment's fill
  /// (selected for the chosen one), foreground, edge or side, overlay,
  /// shape (the strip round them follows it), padding, minimum width and
  /// text style, each per state.
  ///
  /// ```dart
  /// FrostedSegmentedButton(
  ///   segments: segments,
  ///   value: range,
  ///   onChanged: setRange,
  ///   label: 'Range',
  ///   style: const FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(
  ///         borderRadius: BorderRadius.all(Radius.circular(8)),
  ///       ),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // A filled strip shares its field's width among its segments at every
    // size, as a form's other fields take it; an unfilled one keeps to its
    // segments.
    final share = fill;
    final base = fill
        ? t.textTheme.labelSmall.at(_segmentFillWord)
        : t.textTheme.labelSmall;
    // The words grow with the reader's text, each segment by their extra
    // line.
    final height = frostedGrownHeight(
      context,
      t.density.height(
        fill
            ? FrostedChromeMetrics.segmentFillHeight
            : FrostedChromeMetrics.segmentHeight,
      ),
      base,
    );
    final layers = FrostedStyleLayers(style, t.components.segmentedButton);
    final cut = layers.cut(FrostedCorners.full);
    final plateRadius = FrostedStyleLayers.radiusOf(cut, height, height / 2);
    Widget segment(FrostedButtonSegment<T> item) {
      final on = item.value == value;
      Widget draw(Set<WidgetState> states) {
        final s = layers.at(states);
        // .seg-ctl span { height: 26px; min-width: 36px; padding: 0 10px;
        //   font: 500 12px/1 var(--font-t); color: var(--ink-2) }
        // .seg-ctl .on { background: #fff; color: var(--ink); font-weight: 600;
        //   box-shadow: var(--edge), 0 2px 6px -2px rgba(42,36,100,.18) }
        // .field .seg-ctl span { flex: 1 1 auto; height: 36px; font-size: 14px }
        var words = base;
        if (on) words = words.semibold.c(t.colorScheme.textPrimary);
        final word = Center(
          widthFactor: share ? null : 1,
          child: FrostedEase<TextStyle>(
            value: s.words(words),
            lerp: FrostedEase.words,
            builder: (context, drawn) => frostedCapCentredSnapped(
              Text(item.label, textAlign: TextAlign.center, style: drawn),
            ),
          ),
        );
        final side = s.side;
        final (edge, edges) = side == null
            ? (null, EdgeInsets.zero)
            : s.edgeOf(null, FrostedStrokes.regular);
        final least = s.minimumSize;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: least?.width ?? FrostedChromeMetrics.segmentMinWidth,
            minHeight: height,
            maxHeight: height,
          ),
          // The chosen segment's face is the pill sliding under it.
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(plateRadius),
            shape: cut,
            color: s.fill,
            wash: s.overlay,
            edge: edge,
            edges: edges,
            padding:
                s.padding?.resolve(Directionality.of(context)) ??
                t.density.padding(
                  const EdgeInsets.symmetric(
                    horizontal: FrostedChromeMetrics.segmentInset,
                  ),
                ),
            child: word,
          ),
        );
      }

      return FrostedPressable(
        key: item.key,
        onPressed: onChanged == null ? null : () => onChanged!(item.value),
        semanticLabel: item.label,
        selected: on,
        radius: plateRadius,
        shape: cut,
        builder: (context, states, _) => draw(states),
      );
    }

    // .seg-ctl { display: inline-flex; padding: 3px; gap: 2px;
    //   border-radius: 999px; background: var(--wash) }
    // A strip of recessed glass, the chosen word on a brighter pill that
    // slides to the next choice.
    final chosen = segments.indexWhere((item) => item.value == value);
    // Each segment stands in its touch target (the floor, 40) round its
    // face, as Material pads a segmented button's: the strip is drawn as a
    // band behind the faces at their height and the inset round them, and
    // the targets reach past it above and below.
    const inset = FrostedChromeMetrics.segmentsInset;
    final reach =
        math.max(0.0, FrostedBreakpoints.hitTargetOf(context) - height) / 2;
    final pill = _Band(
      reach: reach,
      inset: inset,
      band: FrostedFace(
        material: FrostedMaterial.well,
        radius: BorderRadius.circular(plateRadius + inset),
        shape: FrostedStyleLayers.around(cut, inset),
      ),
      child: FrostedSlidingPill(
        count: segments.length,
        selected: chosen < 0 ? null : chosen,
        inset: EdgeInsets.symmetric(vertical: reach),
        // The chosen word's pill: the thickest, brightest glass on the
        // strip, raised off its well.
        pill: FrostedChosenPlate(
          radius: BorderRadius.circular(plateRadius),
          shape: cut,
        ),
        // Use the same moving plate when the choices need several rows.
        builder: (context, keys) => _SegmentShares(
          fill: share,
          children: [
            for (final (i, item) in segments.indexed)
              KeyedSubtree(key: keys[i], child: segment(item)),
          ],
        ),
      ),
    );
    // A strip keeps its own height in a taller row and stands at the row's
    // centre, so its rim never grows away from the chosen plate; in a box
    // of any height it stays as tall as itself. It is as wide as its
    // segments, at the line's start (in a wrap or a row it takes only that
    // room), and a screen reader's box is the strip's; filled below 600 it
    // takes the width it is given.
    final group = Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: share ? null : 1,
      heightFactor: 1,
      child: Semantics(
        container: true,
        label: label,
        explicitChildNodes: true,
        child: FrostedDim(off: onChanged == null, child: pill),
      ),
    );
    return labelled ? _Labelled(label, child: group) : group;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedButtonSegment<T>>('segments', segments))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('label', label))
      ..add(FlagProperty('fill', value: fill, ifTrue: 'fill'))
      ..add(FlagProperty('labelled', value: labelled, ifTrue: 'labelled'))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

/// Arranges segments with a two-point gap. Each segment keeps its label's
/// natural width; [fill] shares the room equally while every label fits its
/// share, else shares the extra room equally. When the row would clip a
/// label, the segments stack and fill the available width.
class _SegmentShares extends MultiChildRenderObjectWidget {
  const _SegmentShares({required this.fill, required super.children});

  final bool fill;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSegmentShares(Directionality.of(context), fill);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSegmentShares renderObject,
  ) => renderObject
    ..direction = Directionality.of(context)
    ..fill = fill;
}

class _SharesData extends ContainerBoxParentData<RenderBox> {}

class _RenderSegmentShares extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SharesData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SharesData> {
  _RenderSegmentShares(this._direction, this._fill);

  static const double _gap = FrostedChromeMetrics.segmentsGap;

  bool _fill;
  set fill(bool value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SharesData) child.parentData = _SharesData();
  }

  double _gaps(int n) => _gap * math.max(0, n - 1);

  /// Uses one row while every label fits. In a narrow field, each option
  /// receives the width of the field and the active plate moves vertically.
  ({List<double> widths, bool stacked}) _layoutFor(double width) {
    final own = [
      for (var c = firstChild; c != null; c = childAfter(c))
        c.getMaxIntrinsicWidth(double.infinity),
    ];
    if (own.isEmpty || !width.isFinite) return (widths: own, stacked: false);
    final room = math.max(0.0, width - _gaps(own.length));
    final total = own.fold(0.0, (a, b) => a + b);
    if (total > room + .01) {
      return (widths: List.filled(own.length, width), stacked: true);
    }
    // Filled, the segments share the room equally, as Material's segmented
    // button's do, while each label fits its share.
    if (_fill) {
      final even = room / own.length;
      if (own.every((w) => w <= even + .01)) {
        return (widths: List.filled(own.length, even), stacked: false);
      }
    }
    final extra = _fill ? (room - total) / own.length : 0.0;
    return (widths: [for (final w in own) w + extra], stacked: false);
  }

  double _extent(BoxConstraints bounds, List<double> widths, bool stacked) =>
      (_fill || stacked) && bounds.hasBoundedWidth
      ? bounds.maxWidth
      : widths.fold(0.0, (a, b) => a + b) + _gaps(widths.length);

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) {
    var sum = 0.0;
    var n = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      sum += c.getMaxIntrinsicWidth(height);
      n++;
    }
    return sum + _gaps(n);
  }

  double _tallest(double width, double Function(RenderBox, double) measure) {
    final (:widths, :stacked) = _layoutFor(width);
    var h = 0.0;
    var i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final cell = measure(c, widths[i++]);
      h = stacked ? h + cell : math.max(h, cell);
    }
    return stacked ? h + _gaps(widths.length) : h;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _tallest(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _tallest(width, (c, w) => c.getMaxIntrinsicHeight(w));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final (:widths, :stacked) = _layoutFor(constraints.maxWidth);
    final h = _tallest(
      constraints.maxWidth,
      (c, w) => c.getDryLayout(BoxConstraints.tightFor(width: w)).height,
    );
    return constraints.constrain(
      Size(_extent(constraints, widths, stacked), h),
    );
  }

  @override
  void performLayout() {
    final (:widths, :stacked) = _layoutFor(constraints.maxWidth);
    final extent = _extent(constraints, widths, stacked);
    var h = 0.0;
    var i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      c.layout(
        BoxConstraints.tightFor(width: widths[i++]),
        parentUsesSize: true,
      );
      h = stacked ? h + c.size.height : math.max(h, c.size.height);
    }
    if (stacked) h += _gaps(widths.length);
    var offset = 0.0;
    i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final w = widths[i++];
      (c.parentData! as _SharesData).offset = stacked
          ? Offset(0, offset)
          : Offset(
              _direction == TextDirection.rtl ? extent - offset - w : offset,
              (h - c.size.height) / 2,
            );
      offset += (stacked ? c.size.height : w) + _gap;
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

// ---------------------------------------------------------------------------
// Switch
// ---------------------------------------------------------------------------

/// A settings toggle: a 44 by 26 pill, the faint ink track with a white 22 knob
/// at its start, the ink act under the knob at its end when on. The page owns
/// [value]; a null [onChanged] draws it at the disabled share and inert, unless
/// [readOnly] keeps it at full strength as a setting reported, not taken. Lays
/// out at its own size and answers taps over the target floor round it, and
/// Enter and Space from the keyboard. A screen reader hears a switch named
/// [semanticLabel], on or off.
///
/// ```dart
/// FrostedSwitch(value: faceId, onChanged: (v) => setState(() => faceId = v), semanticLabel: 'Face ID')
/// ```
class FrostedSwitch extends StatelessWidget {
  /// Creates a [FrostedSwitch].
  const FrostedSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.readOnly = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         !readOnly || onChanged == null,
         'A read-only switch takes no onChanged.',
       );

  /// Whether it is on.
  final bool value;

  /// Called with the new state; null leaves it inert.
  final ValueChanged<bool>? onChanged;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// What a screen reader calls the switch.
  final String semanticLabel;

  /// Draws [value] as a live switch does but takes no tap, key or focus,
  /// and says it is read only: a setting its page shows on. Takes a null
  /// [onChanged].
  final bool readOnly;

  /// This switch's own style, over
  /// `FrostedThemeData.components.switchTheme`: the track's fill (selected
  /// while on), the knob's colour (foreground), the track's edge or side,
  /// overlay and shape (the knob follows it), each per state.
  ///
  /// ```dart
  /// FrostedSwitch(
  ///   value: on,
  ///   onChanged: setOn,
  ///   semanticLabel: 'Face ID',
  ///   style: FrostedStyle(
  ///     fill: WidgetStateProperty.resolveWith(
  ///       (states) => states.contains(WidgetState.selected)
  ///           ? const Color(0xFF2F7D5B)
  ///           : null,
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final live = onChanged != null;
    // Drawn at full strength: taking input, or reporting a setting.
    final shown = live || readOnly;
    void flip() => onChanged?.call(!value);
    final motion = FrostedMotion.of(context);
    final duration = motion.fast;
    const height = FrostedChromeMetrics.toggleHeight;
    final s = FrostedStyleLayers(style, t.components.switchTheme, {
      if (value) WidgetState.selected,
      if (!shown) WidgetState.disabled,
    });
    final cut = s.cut(FrostedCorners.full);
    final radius = FrostedStyleLayers.radiusOf(cut, height, height / 2);
    final fill = s.fill;
    final side = s.side;
    final (edge, edges) = side == null
        ? (s.edge, const EdgeInsets.all(FrostedStrokes.regular))
        : s.edgeOf(null, FrostedStrokes.regular);
    // A token theme by night draws a dark knob (made for a light track); on
    // the dark glass track it would vanish, so it takes the ink there. A
    // light knob stands as it is.
    final knob =
        s.foreground ??
        (t.colorScheme.toggleKnob.computeLuminance() > .5
            ? t.colorScheme.toggleKnob
            : t.colorScheme.textPrimary);
    // The track is recessed glass, on or off. On, the knob stands at the end,
    // a check is printed in the room it left and the glass is tinted with the
    // act, so on reads at a glance and the track stays glass (light under
    // it, never filled); the knob is a disc of glass with the glass's own
    // light rim.
    final dark = t.brightness == Brightness.dark;
    final onWash = t.colorScheme.accent.withValues(alpha: dark ? .2 : .32);
    final slide = Padding(
      padding: const EdgeInsets.all(FrostedChromeMetrics.toggleInset),
      child: AnimatedAlign(
        duration: duration,
        curve: motion.curve,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: SizedBox.square(
          dimension: FrostedChromeMetrics.toggleKnob,
          child: FrostedFace(
            material: FrostedMaterial.pane,
            radius: BorderRadius.circular(FrostedChromeMetrics.toggleKnob / 2),
            shape: cut == null
                ? null
                : FrostedStyleLayers.around(
                    cut,
                    -FrostedChromeMetrics.toggleInset,
                  ),
            color: knob.withValues(alpha: knob.a * .62),
            ring: t.glass.rim,
            shadows: t.shadows.toggleKnob,
          ),
        ),
      ),
    );
    const room =
        FrostedChromeMetrics.toggleWidth -
        FrostedChromeMetrics.toggleKnob -
        2 * FrostedChromeMetrics.toggleInset;
    // The act's tint lies on the glass inside the rim, so the lit hairline
    // round the track is the same on and off.
    final tint = s.overlay == null
        ? Positioned.fill(
            child: Padding(
              padding: fill != null || edge != null
                  ? edges
                  : const EdgeInsets.all(FrostedChromeMetrics.outline),
              child: AnimatedOpacity(
                opacity: value ? 1 : 0,
                duration: duration,
                curve: motion.curve,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: onWash,
                    shape:
                        FrostedStyleLayers.around(
                          cut,
                          -FrostedChromeMetrics.outline,
                        ) ??
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            math.max(0, radius - FrostedChromeMetrics.outline),
                          ),
                        ),
                  ),
                ),
              ),
            ),
          )
        : null;
    final inside = Stack(
      fit: StackFit.expand,
      children: [
        ?tint,
        PositionedDirectional(
          start: FrostedChromeMetrics.toggleInset,
          top: 0,
          bottom: 0,
          width: room,
          child: AnimatedOpacity(
            opacity: value ? 1 : 0,
            duration: duration,
            curve: motion.curve,
            child: Icon(
              FrostedGlyphs.check,
              size: 12,
              color: s.foreground ?? t.colorScheme.textPrimary,
            ),
          ),
        ),
        slide,
      ],
    );
    final Widget track;
    if (fill != null || edge != null) {
      // A style's own fill or edge: drawn as it sets them.
      track = FrostedFace(
        material: fill != null ? FrostedMaterial.paint : FrostedMaterial.well,
        radius: BorderRadius.circular(radius),
        shape: cut,
        color: fill,
        wash: s.overlay,
        edge: edge,
        edges: edges,
        child: inside,
      );
    } else {
      // The track is a recess in a field's language: a well a step deeper
      // than the glass it stands on, its rim the lit hairline by day and the
      // night glass's rim by night, never a dark line.
      track = FrostedFace(
        material: FrostedMaterial.well,
        radius: BorderRadius.circular(radius),
        shape: cut,
        wash: s.overlay,
        ring: frostedLitEdge(t, t.controlEdge),
        child: inside,
      );
    }
    Widget control = SizedBox(
      width: FrostedChromeMetrics.toggleWidth,
      height: FrostedChromeMetrics.toggleHeight,
      child: track,
    );
    control = FrostedDim(off: !shown, child: control);
    // The track stands in the target, laid out round it (as Material pads
    // a switch): the node, the press and the pointer span it; the focus ring
    // hugs the track. One that takes no press stands in the same target, so
    // turning it off moves nothing round it.
    return FrostedOwnSize(
      child: Semantics(
        container: true,
        label: semanticLabel,
        toggled: value,
        enabled: shown,
        readOnly: readOnly,
        focusable: live,
        onTap: live ? flip : null,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: live ? flip : null,
          child: FrostedPressArea(
            enabled: live,
            child: MouseRegion(
              cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
              child: FrostedHitSlop(
                // A bare one starts on its column's keyline.
                alignment: AlignmentDirectional.centerStart,

                child: FrostedKeyFocus(
                  focusNode: focusNode,
                  autofocus: autofocus,
                  enabled: live,
                  radius: radius,
                  keys: {
                    if (live) ...{
                      LogicalKeyboardKey.enter: flip,
                      LogicalKeyboardKey.space: flip,
                    },
                  },
                  child: FrostedPressedFace(child: control),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(FlagProperty('readOnly', value: readOnly, ifTrue: 'readOnly'))
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

// ---------------------------------------------------------------------------
// Month switch
// ---------------------------------------------------------------------------

/// Spending's month switch: a pill of the wash, 3 inside, with a 32 white round
/// arrow at each end (one with nowhere to go drawn quiet at .6 and skipped by a
/// screen reader), the month before as a 12 word after the first arrow, and the
/// current month as a 600 14 display word with a 14 chevron that opens the
/// months. It fills the line on a phone and takes its own width from 600 up.
/// The page keeps the month and hands [onOpen] the switch's own context, to
/// hang a Stage T FrostedMenu of months from the whole pill. A screen reader
/// hears a group named [semanticLabel] of three buttons: Previous month, Choose month
/// with the month as its value, and Next month.
///
/// ```dart
/// FrostedMonthSwitch(month: 'October 2026', previous: 'September', onEarlier: back, onLater: null, onOpen: (anchor) => FrostedMenu.show<int>(anchor, items: months, title: 'Spent each month', anchor: anchor))
/// ```
class FrostedMonthSwitch extends StatelessWidget {
  /// Creates a [FrostedMonthSwitch].
  const FrostedMonthSwitch({
    required this.month,
    required this.onOpen,
    this.previous,
    this.onEarlier,
    this.onLater,
    this.semanticLabel,
    this.openKey,
    super.key,
  });

  /// The month shown (October 2026).
  final String month;

  /// The month before, as a word after the first arrow (September).
  final String? previous;

  /// Opens the months, handed the switch's context to hang the menu from.
  final void Function(BuildContext anchor) onOpen;

  /// Steps a month back; null draws the arrow quiet and inert.
  final VoidCallback? onEarlier;

  /// Steps a month on; null draws the arrow quiet and inert.
  final VoidCallback? onLater;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  /// The walkthrough key set on the month's own hit target.
  final Key? openKey;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? FrostedLocalizations.of(context).month;
    final t = context.frostedTheme;
    // From 600 up the switch keeps to its arrows and month, at
    // the line's start, as the desktop's does; below 600 it runs the line.
    final wide = MediaQuery.sizeOf(context).width >= frostedMeasureFrom;
    const arrow = FrostedChromeMetrics.monthArrow;
    final target = FrostedBreakpoints.hitTargetOf(context);
    // An arrow keeps its target's room when it goes off at an end, its face
    // on [side], so the month never shifts.
    Widget step(
      IconData icon,
      VoidCallback? onTap,
      String name,
      AlignmentDirectional side,
    ) => SizedBox(
      width: target,
      child: Align(
        alignment: side,
        child: FrostedTargetSide(
          alignment: side,
          child: _monthStep(t, arrow, icon, onTap, name),
        ),
      ),
    );

    Widget pill(BuildContext anchor) {
      // .switch .cur-m { flex: 1; gap: 4px; height: 32px;
      //   font: 600 14px/1 var(--font-d); letter-spacing: -.01em }
      // .spent .switch .cur-m { padding: 0 8px }  (the desktop)
      final current = FrostedPressable(
        key: openKey,
        onPressed: () => onOpen(anchor),
        semanticLabel: FrostedLocalizations.of(context).chooseMonth,
        value: month,
        radius: FrostedChromeMetrics.monthHeight / 2,
        child: SizedBox(
          height: FrostedChromeMetrics.monthHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? FrostedChromeMetrics.monthInsetWide : 0,
            ),
            child: Row(
              mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: FrostedChromeMetrics.monthGap,
              children: [
                Flexible(
                  child: frostedCapCentred(
                    Text(
                      month,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: t.textTheme.titleSmall.line(14).tracked(-0.01),
                    ),
                  ),
                ),
                Icon(
                  FrostedGlyphs.chevronDown,
                  size: FrostedChromeMetrics.monthGlyph,
                  color: t.colorScheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      );
      // .switch { gap: 4px; padding: 3px; border-radius: 999px;
      //   background: var(--wash) }
      // .switch .prev { font: 500 12px/1 var(--font-t);
      //   color: var(--ink-2); padding-left: 4px }
      // The arrows and the month stand in their touch targets (the floor,
      // 40) round their 32 faces; the switch is drawn as a band behind
      // them at their height and the inset round them.
      final face = _Band(
        reach:
            math.max(
              0.0,
              FrostedBreakpoints.hitTargetOf(context) -
                  FrostedChromeMetrics.monthHeight,
            ) /
            2,
        inset: FrostedChromeMetrics.monthSwitchInset,
        band: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(
            arrow / 2 + FrostedChromeMetrics.monthSwitchInset,
          ),
          color: t.glass.wash,
        ),
        child: Row(
          mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
          spacing: FrostedChromeMetrics.monthSwitchGap,
          children: [
            // The arrows keep to the band's ends, their targets growing
            // inward.
            step(
              FrostedGlyphs.chevronLeft,
              onEarlier,
              RawWidgetsLocalizations.of(context).previousMonthTooltip,
              AlignmentDirectional.centerStart,
            ),
            if (previous case final previous?)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: FrostedChromeMetrics.monthPrevInset,
                ),
                child: ExcludeSemantics(
                  child: frostedCapCentred(
                    Text(
                      previous,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: TextScaler.noScaling,
                      style: t.textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            if (wide) current else Expanded(child: current),
            step(
              FrostedGlyphs.forward,
              onLater,
              RawWidgetsLocalizations.of(context).nextMonthTooltip,
              AlignmentDirectional.centerEnd,
            ),
          ],
        ),
      );
      return face;
    }

    // The anchor handed to [onOpen] is the pill's own box: from 600 up the
    // Builder stands inside the Align, so the box is not the line's, and a
    // screen reader's box is the pill's.
    final group = Semantics(
      container: true,
      label: label,
      explicitChildNodes: true,
      child: Builder(builder: pill),
    );
    return wide
        ? Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: group,
          )
        : group;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('month', month))
      ..add(StringProperty('previous', previous, defaultValue: null))
      ..add(
        ObjectFlagProperty<void Function(BuildContext anchor)>.has(
          'onOpen',
          onOpen,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onEarlier', onEarlier))
      ..add(ObjectFlagProperty<VoidCallback>.has('onLater', onLater))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(DiagnosticsProperty<Key>('openKey', openKey, defaultValue: null));
  }
}

// One of the month switch's arrows: a raised 32 round wearing its glyph, or,
// with nowhere to go, the glyph alone, faded and unspoken.
Widget _monthStep(
  FrostedThemeData t,
  double arrow,
  IconData icon,
  VoidCallback? onTap,
  String name,
) {
  // .switch .arr { width: 32px; height: 32px; background: #fff;
  //   box-shadow: var(--edge), 0 2px 6px -2px rgba(42,36,100,.18) }
  // .switch .arr.off { color: var(--ink-3); background: none;
  //   box-shadow: none; opacity: .6 }
  if (onTap == null) {
    return ExcludeSemantics(
      child: Opacity(
        opacity: _monthArrowOffOpacity,
        child: SizedBox.square(
          dimension: arrow,
          child: Center(
            child: Icon(
              icon,
              size: FrostedChromeMetrics.monthArrowGlyph,
              color: t.colorScheme.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
  return FrostedPressable(
    onPressed: onTap,
    semanticLabel: name,
    radius: arrow / 2,
    child: SizedBox.square(
      dimension: arrow,
      child: FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(arrow / 2),
        color: t.glass.plane,
        shadows: [_edge(t), ...t.shadows.raised],
        child: Center(
          child: Icon(
            icon,
            size: FrostedChromeMetrics.monthArrowGlyph,
            color: t.colorScheme.textPrimary,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

/// One of a [FrostedQuickActions]: a glyph on its round and its word, and
/// the walkthrough [key] set on its hit target.
@immutable
class FrostedQuickAction {
  /// Creates a [FrostedQuickAction].
  const FrostedQuickAction(
    this.icon,
    this.label, {
    required this.onPressed,
    this.key,
  });

  /// The glyph in its disc.
  final IconData icon;

  /// The words under it.
  final String label;

  /// Where the action goes; null shows it inert.
  final VoidCallback? onPressed;

  /// The walkthrough key set on its hit target.
  final Key? key;
}

/// Home's quick actions: a tile 14 by 8 inside holding four ways across, 4
/// apart, each a 44 round of the brighter glass with its rim and edge wearing
/// an 18 glyph in the ink, its word 8 under in the secondary ink (Transfer, Pay
/// a bill, Add to goal, Split). Each is a link named by its word; [semanticLabel] names
/// the group.
///
/// ```dart
/// FrostedQuickActions([FrostedQuickAction(FrostedGlyphs.arrowLeftRight, 'Transfer', onPressed: transfer), FrostedQuickAction(FrostedGlyphs.receipt, 'Pay a bill', onPressed: bills), FrostedQuickAction(FrostedGlyphs.piggyBank, 'Add to goal', onPressed: goal), FrostedQuickAction(FrostedGlyphs.split, 'Split', onPressed: split)])
/// ```
class FrostedQuickActions extends StatelessWidget {
  /// Creates a [FrostedQuickActions].
  const FrostedQuickActions(this.actions, {this.semanticLabel, super.key});

  /// The actions, in order.
  final List<FrostedQuickAction> actions;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label =
        semanticLabel ?? FrostedLocalizations.of(context).quickActions;
    final t = context.frostedTheme;
    const round = FrostedChromeMetrics.actionRound;
    // .qa-b { gap: 8px; font: 500 12px/1.2 var(--font-t); color: var(--ink-2) }
    // .qa-b .ic { width: 44px; height: 44px; background: rgba(255,255,255,.8);
    //   box-shadow: var(--rim), var(--edge) }  .qa-b .ic .i { 18px }
    Widget action(FrostedQuickAction a) => FrostedPressable(
      key: a.key,
      onPressed: a.onPressed,
      semanticLabel: a.label,
      role: FrostedPressRole.link,
      radius: FrostedCorners.r12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.actionWordGap,
        children: [
          SizedBox.square(
            dimension: round,
            child: FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(round / 2),
              color: t.glass.fillHigh,
              sheen: t.glass.rim,
              shadows: [_edge(t)],
              child: Center(
                child: Icon(
                  a.icon,
                  size: FrostedChromeMetrics.actionGlyph,
                  color: t.colorScheme.textPrimary,
                ),
              ),
            ),
          ),
          Text(
            a.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: t.textTheme.labelMedium
                .line(14.4)
                .c(t.colorScheme.textSecondary),
          ),
        ],
      ),
    );
    // .qa { grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 4px;
    //   padding: 14px 8px }
    return _ownWidth(
      context,
      FrostedCard(
        padding: FrostedChromeMetrics.actionsInset,
        child: Semantics(
          container: true,
          label: label,
          explicitChildNodes: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FrostedChromeMetrics.actionGap,
            children: [
              for (final a in actions)
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: _quickActionWide,
                    ),
                    child: action(a),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedQuickAction>('actions', actions))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

// ---------------------------------------------------------------------------
// Action tiles
// ---------------------------------------------------------------------------

/// One of a [FrostedActionTiles]: a way to move money, its glyph on the ink
/// round, its [label], the quiet [note] under it, and the walkthrough
/// [key] set on its hit target.
@immutable
class FrostedActionTile {
  /// Creates a [FrostedActionTile].
  const FrostedActionTile(
    this.icon,
    this.label, {
    required this.onPressed,
    this.note,
    this.tail,
    this.key,
  });

  /// The tile's glyph.
  final IconData icon;

  /// The tile's words.
  final String label;

  /// The quiet line under the label (Your accounts, 6 in November), cut
  /// short with an ellipsis.
  final String? note;

  /// More after the note where the desktop has the room, set off with a middle
  /// dot ($2,541.40).
  final String? tail;

  /// Where the tile goes; null shows it inert.
  final VoidCallback? onPressed;

  /// The walkthrough key set on its hit target.
  final Key? key;
}

/// Move's ways to move money: tiles two across, 8 apart (the desktop's gap on
/// the desktop), each the faint glass 14 round with its hairline ring, 10
/// inside (16 on the desktop), its glyph on a 32 (40) round of the ink act
/// beside its word in the 600 16 display face over a quiet 12 (14) line; the
/// tiles of a row equal in height. Each is one link read as its word and its
/// line; [semanticLabel] names the group.
///
/// ```dart
/// FrostedActionTiles([FrostedActionTile(FrostedGlyphs.arrowLeftRight, 'Transfer', note: 'Your accounts', onPressed: transfer), FrostedActionTile(FrostedGlyphs.receipt, 'Pay a bill', note: '6 in November', tail: r'$2,541.40', onPressed: bills)], semanticLabel: 'Ways to move money')
/// ```
class FrostedActionTiles extends StatelessWidget {
  /// Creates a [FrostedActionTiles].
  const FrostedActionTiles(this.tiles, {this.semanticLabel, super.key});

  /// The tiles, in order.
  final List<FrostedActionTile> tiles;

  /// What a screen reader calls the tiles together.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final wide = FrostedBreakpoints.isWide(context);
    final round = wide
        ? FrostedChromeMetrics.moveActRoundWide
        : FrostedChromeMetrics.moveActRound;
    // .mv-act { gap: 10px; padding: 10px; border-radius: 14px;
    //   background: rgba(255,255,255,.6);
    //   box-shadow: inset 0 0 0 1px rgba(21,21,45,.06) }
    // .mv-ic { 32px; background: var(--ink-fill); color: #fff;
    //   box-shadow: var(--ink-lift) }  .mv-ic .i { 16px }
    // .mv-t { font: 600 16px/1.2 var(--font-d); letter-spacing: -.01em }
    // .mv-act .row-s { font-size: 12px }
    // desktop: .mv-act { padding: 16px; gap: 14px }  .mv-ic { 40px; .i 18px }
    //   .mv-act .row-main { gap: 4px }  .mv-act .row-s { font-size: 14px }
    Widget tile(FrostedActionTile a) {
      final note = a.note == null
          ? null
          : wide && a.tail != null
          ? '${a.note} · ${a.tail}'
          : a.note;
      return MergeSemantics(
        child: FrostedPressable(
          key: a.key,
          onPressed: a.onPressed,
          role: FrostedPressRole.link,
          excludeChild: false,
          radius: FrostedChromeMetrics.moveActRadius,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(FrostedChromeMetrics.moveActRadius),
            color: t.glass.fill,
            ring: t.glass.edge,
            padding: EdgeInsets.all(
              wide
                  ? FrostedChromeMetrics.moveActInsetWide
                  : FrostedChromeMetrics.moveActInset,
            ),
            child: Row(
              spacing: wide
                  ? FrostedChromeMetrics.moveActGapWide
                  : FrostedChromeMetrics.moveActGap,
              children: [
                SizedBox.square(
                  dimension: round,
                  child: FrostedFace(
                    material: FrostedMaterial.paint,
                    radius: BorderRadius.circular(round / 2),
                    gradients: [t.colorScheme.buttonFill],
                    sheen: t.colorScheme.buttonSheen,
                    shadows: t.shadows.button,
                    child: Center(
                      child: Icon(
                        a.icon,
                        size: wide
                            ? FrostedChromeMetrics.moveActGlyphWide
                            : FrostedChromeMetrics.moveActGlyph,
                        color: t.colorScheme.onButton,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: wide
                        ? FrostedChromeMetrics.moveActLineGapWide
                        : FrostedChromeMetrics.moveActLineGap,
                    children: [
                      Text(
                        a.label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleLarge.line(19.2).tracked(-0.01),
                      ),
                      if (note != null)
                        Text(
                          note,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: wide
                              ? t.textTheme.bodyMedium.line(18.2)
                              : t.textTheme.bodyMedium.at(12).line(15.6),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final gap = wide
        ? FrostedBreakpoints.gap(context)
        : FrostedChromeMetrics.moveActsGap;
    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: gap,
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                for (final j in [i, i + 1])
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: _moveActWide),
                      child: j < tiles.length
                          ? tile(tiles[j])
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
    if (semanticLabel == null) return _ownWidth(context, grid);
    return _ownWidth(
      context,
      Semantics(
        container: true,
        label: semanticLabel,
        explicitChildNodes: true,
        child: grid,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedActionTile>('tiles', tiles))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

// ---------------------------------------------------------------------------
// Quick amounts
// ---------------------------------------------------------------------------

/// One of a [FrostedQuickAmounts]: the [amount] it stands for, the word
/// under it, and the walkthrough [key] set on its hit target.
@immutable
class FrostedQuickAmount {
  /// Creates a [FrostedQuickAmount].
  const FrostedQuickAmount(this.amount, this.label, {this.key});

  /// What choosing it sets.
  final num amount;

  /// The line under the figure (A month, Two months, The rest).
  final String label;

  /// The walkthrough key set on its hit target.
  final Key? key;
}

/// A goal's quick amounts: wells three across, 8 apart, each the whole-dollar
/// figure in the display face over a quiet 12 word, 10 by 6 inside on the white
/// well with its hairline ring; the chosen one stays glass, a little clearer,
/// with a dot printed in its top corner and its word in the secondary ink. The
/// page owns [value] (the chosen amount, or none); a null [onChanged] leaves
/// them inert. A screen reader hears a group named [semanticLabel] of buttons, the
/// chosen one selected.
///
/// ```dart
/// FrostedQuickAmounts(options: const [FrostedQuickAmount(100, 'A month'), FrostedQuickAmount(200, 'Two months'), FrostedQuickAmount(1160, 'The rest')], value: amount, onChanged: (v) => setState(() => amount = v))
/// ```
class FrostedQuickAmounts extends StatelessWidget {
  /// Creates a [FrostedQuickAmounts].
  const FrostedQuickAmounts({
    required this.options,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  /// The amounts, in order.
  final List<FrostedQuickAmount> options;

  /// The chosen amount; null chooses none.
  final num? value;

  /// Called with the amount chosen; null leaves them inert.
  final ValueChanged<num>? onChanged;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label =
        semanticLabel ?? FrostedLocalizations.of(context).quickAmounts;
    final t = context.frostedTheme;
    // .qamt { gap: 4px; padding: 10px 6px; border-radius: 12px;
    //   background: rgba(255,255,255,.82);
    //   box-shadow: inset 0 0 0 1px rgba(21,21,45,.08) }
    // .qamt b { font-size: 16px }  .qamt span { font: 500 12px/1.2
    //   var(--font-t); color: var(--ink-3) }
    // .qamt.on { background: var(--ink-fill); color: #fff;
    //   box-shadow: var(--ink-lift) }  .qamt.on span { color: rgba(255,255,255,.72) }
    Widget well(FrostedQuickAmount item) {
      final on = item.amount == value;
      final figure = FrostedFormat.money(item.amount, cents: false);
      // Chosen, the well stays glass: a little clearer, a dot printed in
      // its top corner, in the room over its figure, never a fill of ink.
      final face = FrostedFace(
        material: FrostedMaterial.paint,
        radius: BorderRadius.circular(FrostedChromeMetrics.quickAmountRadius),
        color: t.glass.well,
        wash: on ? t.glass.wash : null,
        ring: frostedLitEdge(t, t.glass.wellEdge),
        padding: FrostedChromeMetrics.quickAmountInset,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: FrostedChromeMetrics.quickAmountGap,
          children: [
            // A figure is never broken: at large text one wider than its
            // well shrinks to it whole ("$1,160", never "$1,16" over "0").
            FittedBox(
              fit: BoxFit.scaleDown,
              child: FrostedNumberText(
                figure,
                style: t.textTheme.titleMedium.c(t.colorScheme.textPrimary),
              ),
            ),
            Text(
              item.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t.textTheme.labelMedium
                  .line(14.4)
                  .c(
                    on
                        ? t.colorScheme.textSecondary
                        : t.colorScheme.textTertiary,
                  ),
            ),
          ],
        ),
      );
      return FrostedPressable(
        key: item.key,
        onPressed: onChanged == null ? null : () => onChanged!(item.amount),
        semanticLabel: '$figure, ${item.label}',
        selected: on,
        radius: FrostedChromeMetrics.quickAmountRadius,
        child: _chosenDot(t, on, face),
      );
    }

    return _ownWidth(
      context,
      Semantics(
        container: true,
        label: label,
        explicitChildNodes: true,
        child: _Grid(
          columns: _quickAmountColumns,
          gap: FrostedChromeMetrics.quickAmountsGap,
          least: _quickAmountWide,
          children: [for (final item in options) well(item)],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedQuickAmount>('options', options))
      ..add(DiagnosticsProperty<num>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<num>>.has('onChanged', onChanged))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

/// [face] with, when [on], the chosen dot printed in its top corner: a 7
/// disc in the ink, 5 in from the top and the end, inside the glass. The
/// face keeps the constraints it was given, so a well still fills its cell.
Widget _chosenDot(FrostedThemeData t, bool on, Widget face) => Stack(
  fit: StackFit.passthrough,
  children: [
    face,
    PositionedDirectional(
      top: 5,
      end: 5,
      child: ExcludeSemantics(
        child: FrostedFade(
          opacity: on ? 1 : 0,
          child: SizedBox.square(
            dimension: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.colorScheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Icon picker
// ---------------------------------------------------------------------------

/// One of a [FrostedIconPicker]: a glyph from the Lucide set, the word a
/// screen reader hears for it (and the value the picker hands back), and
/// the walkthrough [key] set on its hit target.
@immutable
class FrostedIconChoice {
  /// Creates a [FrostedIconChoice].
  const FrostedIconChoice(this.icon, this.label, {this.key});

  /// The choice's glyph.
  final IconData icon;

  /// What a screen reader calls it, and its value.
  final String label;

  /// The walkthrough key set on its hit target.
  final Key? key;
}

/// A goal's icon picker: wells six across, 8 apart, each 44 tall and 12 round
/// on the white well with its hairline ring, an 18 glyph in the secondary ink;
/// the chosen one stays glass, a little clearer, its glyph in the ink and a dot
/// printed in its top corner; [labelled] writes [label] over the wells as the
/// field's label. The page owns [value], a choice's word; a null [onChanged]
/// leaves them inert. A screen reader hears a group named [label] of buttons,
/// the chosen one selected.
///
/// ```dart
/// FrostedIconPicker(icons: const [FrostedIconChoice(FrostedGlyphs.plane, 'Plane'), FrostedIconChoice(FrostedGlyphs.bike, 'Bike'), FrostedIconChoice(FrostedGlyphs.house, 'Home')], value: icon, onChanged: (v) => setState(() => icon = v))
/// ```
class FrostedIconPicker extends StatelessWidget {
  /// Creates a [FrostedIconPicker].
  const FrostedIconPicker({
    required this.icons,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelled = false,
    super.key,
  });

  /// The choices, in order.
  final List<FrostedIconChoice> icons;

  /// The chosen choice's word; null chooses none.
  final String? value;

  /// Called with the chosen label; null leaves them inert.
  final ValueChanged<String>? onChanged;

  /// What a screen reader calls the group.
  final String? label;

  /// Whether [label] is written over the wells as a field's label.
  final bool labelled;

  @override
  Widget build(BuildContext context) {
    final label = this.label ?? FrostedLocalizations.of(context).icon;
    final t = context.frostedTheme;
    // .ico { height: 44px; border-radius: 12px; color: var(--ink-2);
    //   background: rgba(255,255,255,.82);
    //   box-shadow: inset 0 0 0 1px rgba(21,21,45,.08) }  .ico .i { 18px }
    // .ico.on { background: var(--ink-fill); color: #fff;
    //   box-shadow: var(--ink-lift) }
    Widget well(FrostedIconChoice choice) {
      final on = choice.label == value;
      return FrostedPressable(
        key: choice.key,
        onPressed: onChanged == null ? null : () => onChanged!(choice.label),
        semanticLabel: choice.label,
        selected: on,
        radius: FrostedChromeMetrics.iconWellRadius,
        child: SizedBox(
          height: FrostedChromeMetrics.iconWell,
          // Chosen, the well stays glass: a little clearer, its glyph in the
          // ink and a dot printed in its top corner, never a fill of ink.
          child: _chosenDot(
            t,
            on,
            FrostedFace(
              material: FrostedMaterial.paint,
              radius: BorderRadius.circular(
                FrostedChromeMetrics.iconWellRadius,
              ),
              color: t.glass.well,
              wash: on ? t.glass.wash : null,
              ring: frostedLitEdge(t, t.glass.wellEdge),
              child: Center(
                child: Icon(
                  choice.icon,
                  size: FrostedChromeMetrics.iconWellGlyph,
                  color: on
                      ? t.colorScheme.textPrimary
                      : t.colorScheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final group = _ownWidth(
      context,
      Semantics(
        container: true,
        label: label,
        explicitChildNodes: true,
        child: _Grid(
          columns: FrostedChromeMetrics.iconWellsPerRow,
          gap: FrostedChromeMetrics.iconWellGap,
          least: _iconWellWide,
          drawn: FrostedChromeMetrics.iconWell,
          children: [for (final choice in icons) well(choice)],
        ),
      ),
    );
    return labelled ? _Labelled(label, child: group) : group;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedIconChoice>('icons', icons))
      ..add(StringProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(FlagProperty('labelled', value: labelled, ifTrue: 'labelled'));
  }
}

/// A strip whose controls stand in touch targets taller than their faces
/// (a segmented strip, the month switch): [child], the controls, [inset]
/// from the strip's sides, and [band], the strip as drawn, behind them at
/// their faces' height and [inset] round them, centred. A control's target
/// reaches [reach] past its face above and below; where that is more than
/// [inset] the targets stand past the band, else the band holds them.
class _Band extends StatelessWidget {
  const _Band({
    required this.reach,
    required this.inset,
    required this.band,
    required this.child,
  });

  final double reach;
  final double inset;
  final Widget band;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final past = math.max(0.0, reach - inset);
    return Stack(
      children: [
        Positioned.fill(top: past, bottom: past, child: band),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: math.max(0.0, inset - reach),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// A grid of equal columns, [gap] apart each way, as CSS's
/// `grid-template-columns: repeat(n, minmax(0, 1fr))` lays one out: the
/// last row's empty cells keep their width. Asked its own width (under
/// [_ownWidth]) each cell is the widest cell's, at least [least]. Cells
/// drawn [drawn] tall stand in taller touch targets: the rows close up by
/// the difference, so the drawn cells stay [gap] apart. A cell is never
/// narrower than the touch target while the row can help it: the gaps close
/// first (to 4 at the least: six icon wells in a card's 326 stay 40 wide),
/// then a column moves to the next row.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.columns,
    required this.gap,
    required this.children,
    this.least = 0,
    this.drawn,
  });

  final int columns;
  final double gap;
  final List<Widget> children;
  final double least;
  final double? drawn;

  @override
  Widget build(BuildContext context) {
    final target = FrostedBreakpoints.hitTargetOf(context);
    return _Cells(
      columns: columns,
      gap: gap,
      rowGap: switch (drawn) {
        final drawn? => math.max(0.0, gap - math.max(0.0, target - drawn)),
        null => gap,
      },
      least: least,
      floor: target,
      textDirection: Directionality.of(context),
      children: [
        ...children,
        // The last row's empty cells, which keep their width.
        for (var i = children.length; i % columns != 0; i++)
          const SizedBox.shrink(),
      ],
    );
  }
}

/// [_Grid]'s layout: [columns] cells to a row (fewer where a cell would
/// stand under [floor] even with the gaps closed to 4), [gap] apart across
/// (less, to keep a cell at [floor]), [rowGap] apart down, each row as tall
/// as its tallest cell, the cells at its top.
class _Cells extends MultiChildRenderObjectWidget {
  const _Cells({
    required this.columns,
    required this.gap,
    required this.rowGap,
    required this.least,
    required this.floor,
    required this.textDirection,
    required super.children,
  });

  final int columns;
  final double gap;
  final double rowGap;
  final double least;
  final double floor;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCells(columns, gap, rowGap, least, floor, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderCells renderObject) {
    renderObject
      ..columns = columns
      ..gap = gap
      ..rowGap = rowGap
      ..least = least
      ..floor = floor
      ..textDirection = textDirection;
  }
}

class _CellData extends ContainerBoxParentData<RenderBox> {}

class _RenderCells extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellData> {
  _RenderCells(
    this._columns,
    this._gap,
    this._rowGap,
    this._least,
    this._floor,
    this._textDirection,
  );

  int get columns => _columns;
  int _columns;
  set columns(int value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double get gap => _gap;
  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double get rowGap => _rowGap;
  double _rowGap;
  set rowGap(double value) {
    if (value == _rowGap) return;
    _rowGap = value;
    markNeedsLayout();
  }

  double get least => _least;
  double _least;
  set least(double value) {
    if (value == _least) return;
    _least = value;
    markNeedsLayout();
  }

  double get floor => _floor;
  double _floor;
  set floor(double value) {
    if (value == _floor) return;
    _floor = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellData) child.parentData = _CellData();
  }

  /// The columns, the gap across and a cell's width in [width].
  (int, double, double) _fit(double width) {
    final closest = math.min(_gap, FrostedSpacing.s4);
    var n = math.max(1, _columns);
    while (n > 1 && n * _floor + (n - 1) * closest > width) {
      n--;
    }
    final g = n < 2
        ? 0.0
        : math.min(_gap, math.max(closest, (width - n * _floor) / (n - 1)));
    return (n, g, math.max(0.0, (width - (n - 1) * g) / n));
  }

  List<RenderBox> get _cells => [
    for (var c = firstChild; c != null; c = childAfter(c)) c,
  ];

  double _across(double Function(RenderBox child) widthOf) {
    var widest = _least;
    for (final c in _cells) {
      widest = math.max(widest, widthOf(c));
    }
    return widest * _columns + _gap * (_columns - 1);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _across((c) => c.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _across((c) => c.getMaxIntrinsicWidth(double.infinity));

  double _down(double width, double Function(RenderBox, double) heightOf) {
    final (n, _, cell) = _fit(width);
    final cells = _cells;
    var total = 0.0;
    for (var row = 0; row < cells.length; row += n) {
      var tallest = 0.0;
      for (var i = row; i < math.min(row + n, cells.length); i++) {
        tallest = math.max(tallest, heightOf(cells[i], cell));
      }
      total += tallest + (row == 0 ? 0 : _rowGap);
    }
    return total;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _down(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _down(width, (c, w) => c.getMaxIntrinsicHeight(w));

  double _widthIn(BoxConstraints constraints) => constraints.hasBoundedWidth
      ? constraints.maxWidth
      : constraints.constrainWidth(computeMaxIntrinsicWidth(double.infinity));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final width = _widthIn(constraints);
    return constraints.constrain(
      Size(
        width,
        _down(
          width,
          (c, w) => c.getDryLayout(BoxConstraints.tightFor(width: w)).height,
        ),
      ),
    );
  }

  @override
  void performLayout() {
    final width = _widthIn(constraints);
    final (n, g, cell) = _fit(width);
    final cells = _cells;
    var y = 0.0;
    for (var row = 0; row < cells.length; row += n) {
      if (row > 0) y += _rowGap;
      var tallest = 0.0;
      for (var i = row; i < math.min(row + n, cells.length); i++) {
        final child = cells[i]
          ..layout(BoxConstraints.tightFor(width: cell), parentUsesSize: true);
        tallest = math.max(tallest, child.size.height);
        final column = i - row;
        final x = _textDirection == TextDirection.rtl
            ? width - cell - column * (cell + g)
            : column * (cell + g);
        (child.parentData! as _CellData).offset = Offset(x, y);
      }
      y += tallest;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
