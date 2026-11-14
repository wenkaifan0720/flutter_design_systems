import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/act_row.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/measure.dart';
import '../../internal/own_size.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../glass.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

// The two faces a [FrostedButton] wears, one per constructor.
enum _Face { ink, glass }

/// How large a [FrostedButton] stands.
enum FrostedButtonSize {
  /// 44 tall and 20 in, its word 14 and its glyph 18: a page's or a
  /// sheet's act.
  regular,

  /// 32 tall and 14 in, its word 12 and its glyph 14 (`.btn--sm`): a
  /// button in a tile's head or a line of words (See all, Edit).
  small,
}

/// A pill wearing a word: [label] in the label type, an optional [icon] 8
/// before it, 44 tall and as wide as its word; with [expand] it takes all
/// the width there is, 48 tall with its word 16 (`.btn--wide`, a sheet's
/// foot); a small one ([size]) is 32 tall. A null [onPressed] draws it at the
/// disabled share without its lift, and makes it inert.
///
/// ```dart
/// FrostedButton('Review transfer', expand: true, onPressed: review)
/// ```
///
/// ```dart
/// FrostedButton.glass('Clear filters', icon: FrostedGlyphs.close, onPressed: clear)
/// ```
///
/// ```dart
/// FrostedButton.glass('See all', size: FrostedButtonSize.small, onPressed: seeAll)
/// ```
class FrostedButton extends StatelessWidget {
  /// Creates the page's or the sheet's one act (`.btn--ink`): the word on
  /// the ink with a light along its top edge, standing in its own lift
  /// (Move money, Review transfer, Add \$250).
  const FrostedButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.semanticLabel,
    this.size = FrostedButtonSize.regular,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = _Face.ink;

  /// Creates a lesser act (`.btn--glass`): the brighter glass with its rim
  /// of light and hairline edge, the word in the ink (Clear filters,
  /// Cancel).
  const FrostedButton.glass(
    this.label, {
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.semanticLabel,
    this.size = FrostedButtonSize.regular,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = _Face.glass;

  /// The word.
  final String label;

  /// What a press does; null draws the button disabled.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  final _Face _face;

  /// A glyph before the word, from the Lucide set.
  final IconData? icon;

  /// Whether the button takes all the width it is given, 48 tall (a
  /// sheet's foot, a row of two); from 600 wide, at most 320 of it.
  final bool expand;

  /// What a screen reader calls it where the word alone says too little
  /// (Edit: "Edit budget"); null says [label].
  final String? semanticLabel;

  /// How large it stands: [FrostedButtonSize.small] in a line of words.
  final FrostedButtonSize size;

  /// This button's own style, over `FrostedThemeData.components.button`:
  /// its fill (a flat colour in place of the ink's gradient), foreground,
  /// edge or side, overlay, shape, padding, minimum size, text style and
  /// icon size, each per state.
  ///
  /// ```dart
  /// FrostedButton(
  ///   'Save',
  ///   onPressed: save,
  ///   style: FrostedStyle(
  ///     shape: WidgetStatePropertyAll(
  ///       RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ///     ),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final enabled = onPressed != null;
    // In a row of acts every act shows the size the largest asks for: one
    // top and one bottom along the row, whatever each one's variant.
    final shown = FrostedActRow.shown(context, FrostedActRow.ask(this));
    final small = shown == FrostedActSize.small;
    final wide = shown == FrostedActSize.wide;
    // Large text grows the pill by its words' extra line: at 200% the words
    // filled a 44 pill to its rim.
    final height = frostedGrownHeight(
      context,
      t.density.height(
        small
            ? FrostedChromeMetrics.buttonSmallHeight
            : wide
            ? FrostedChromeMetrics.buttonWideHeight
            : FrostedChromeMetrics.buttonHeight,
      ),
      t.textTheme.labelLarge.at(
        small
            ? FrostedChromeMetrics.buttonSmallWord
            : wide
            ? FrostedChromeMetrics.buttonWideWord
            : t.textTheme.labelLarge.fontSize!,
      ),
    );
    final inset = t.density
        .padding(
          EdgeInsets.symmetric(
            horizontal: small
                ? FrostedChromeMetrics.buttonSmallInset
                : FrostedChromeMetrics.buttonInset,
          ),
        )
        .left;
    final layers = FrostedStyleLayers(style, t.components.button);
    // On another glass (a sheet, a dialog, a card) the capsule is shaded a
    // step with the page's ink, not raised white: a white step vanished on a
    // light sheet and left only the word to read as the button.
    final shaded = FrostedOnGlass.of(context) && !frostedOpaqueAt(context);
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final cut = s.cut(FrostedCorners.full);
      final round = FrostedStyleLayers.radiusOf(cut, height, height / 2);
      final radius = BorderRadius.circular(round);
      final ink =
          s.foreground ??
          switch (_face) {
            _Face.ink => t.colorScheme.onButton,
            _Face.glass => t.colorScheme.textPrimary,
          };
      final words = s.words(
        small
            ? t.textTheme.labelLarge
                  .at(FrostedChromeMetrics.buttonSmallWord)
                  .c(ink)
            : wide
            ? t.textTheme.labelLarge
                  .at(FrostedChromeMetrics.buttonWideWord)
                  .c(ink)
            : t.textTheme.labelLarge.c(ink),
      );
      final row = Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: small
            ? FrostedChromeMetrics.buttonSmallGap
            : FrostedChromeMetrics.buttonGap,
        children: [
          if (icon != null)
            Icon(
              icon,
              size:
                  s.iconSize ??
                  (small
                      ? FrostedChromeMetrics.buttonSmallGlyph
                      : FrostedChromeMetrics.buttonGlyph),
              color: ink,
            ),
          Flexible(
            child: frostedCapCentred(
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: words,
              ),
            ),
          ),
        ],
      );
      final padding = s.padding;
      final content = padding == null
          ? _Spill(inset: inset, round: round, height: height, child: row)
          : Padding(padding: padding, child: row);
      final fill = s.fill;
      // No edge of the look's own on either: a light rim inside the glass
      // vanished on a light sheet and left the face 2 smaller than the ink
      // beside it. The glass reaches the box's edge; its rim lies inside.
      final (edge, edges) = s.edgeOf(null, FrostedStrokes.regular);
      Widget face = SizedBox(
        height: height,
        width: expand ? double.infinity : null,
        child: switch (_face) {
          _Face.ink => FrostedFace(
            material: FrostedMaterial.paint,
            radius: radius,
            shape: cut,
            color: fill,
            gradients: fill == null
                ? [t.colorScheme.buttonFill]
                : const <Gradient>[],
            wash: s.overlay,
            edge: edge,
            edges: edges,
            sheen: t.colorScheme.buttonSheen,
            shadows: enabled ? t.shadows.button : const <BoxShadow>[],
            child: content,
          ),
          // A lesser act is a capsule of glass; on another glass it is
          // shaded a step.
          _Face.glass when shaded => FrostedFace(
            material: FrostedMaterial.paint,
            radius: radius,
            shape: cut,
            color:
                fill ??
                t.colorScheme.textPrimary.withValues(
                  alpha: t.isDark
                      ? FrostedChromeMetrics.glassStepNight
                      : FrostedChromeMetrics.glassStepDay,
                ),
            wash: s.overlay,
            edge: edge,
            edges: edges,
            sheen: t.glass.rim,
            child: content,
          ),
          // By night dark glass over a dark page reads as the page: a light
          // step (the ink's share) parts the capsule from it.
          _Face.glass => FrostedFace(
            material: FrostedMaterial.pane,
            radius: radius,
            shape: cut,
            color:
                fill ??
                (t.isDark
                    ? t.colorScheme.textPrimary.withValues(
                        alpha: FrostedChromeMetrics.glassStepNight,
                      )
                    : null),
            wash: s.overlay,
            edge: edge,
            edges: edges,
            sheen: t.glass.rim,
            child: content,
          ),
        },
      );
      face = s.least(face);
      face = FrostedDim(off: !enabled, child: face);
      return face;
    }

    final cut = layers.cut(FrostedCorners.full);
    final Widget face = FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: semanticLabel ?? label,
      radius: FrostedStyleLayers.radiusOf(cut, height, height / 2),
      shape: cut,
      builder: (context, states, _) => draw(states),
    );
    // A small or a compact button keeps the whole target round its face.
    final button = small || height < FrostedChromeMetrics.buttonHeight
        ? FrostedHitSlop(child: face)
        : face;
    // From 600 wide a wide button keeps to a control's measure (320): its
    // column's start, or the middle of its share in a row of acts. Taking a
    // desktop column's whole width, it read as a banner, not a button.
    if (expand && MediaQuery.sizeOf(context).width >= frostedMeasureFrom) {
      return FrostedOwnSize(
        maxWidth: frostedControlMeasure,
        along: FrostedActRow.of(context) == null ? -1 : 0,
        child: button,
      );
    }
    return button;
  }
}

/// A button's glyph and word, [inset] either side while they fit (`.btn {
/// padding: 0 20px }`); handed less (a `.btn-row` half), they eat into
/// that room, still centred, as the source's `white-space: nowrap` content
/// overflows its content box into the padding; only past the button's whole
/// width does the word narrow. Its intrinsic widths keep the whole inset.
/// The spill stops where the face's [round] corner would cut the words: a
/// line as tall as large text makes it (200%) stays inside the pill's ends.
class _Spill extends SingleChildRenderObjectWidget {
  const _Spill({
    required this.inset,
    required this.round,
    required this.height,
    required super.child,
  });

  final double inset;

  /// The face's corner radius.
  final double round;

  /// The face's height.
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSpill(inset, round, height);

  @override
  void updateRenderObject(BuildContext context, _RenderSpill renderObject) =>
      renderObject
        ..inset = inset
        ..round = round
        ..faceHeight = height;
}

class _RenderSpill extends RenderShiftedBox {
  _RenderSpill(this._inset, this._round, this._faceHeight) : super(null);

  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsLayout();
  }

  double _round;
  set round(double value) {
    if (value == _round) return;
    _round = value;
    markNeedsLayout();
  }

  double _faceHeight;
  set faceHeight(double value) {
    if (value == _faceHeight) return;
    _faceHeight = value;
    markNeedsLayout();
  }

  /// The least room either side: where the corner's curve stands at the
  /// content's top and foot (centred in the face), so no word crosses it.
  double get _floor {
    final c = child;
    if (c == null || !_faceHeight.isFinite) return 0;
    // A corner past half the height draws as half the height.
    final r = math.min(_round, _faceHeight / 2);
    if (r <= 0) return 0;
    final tall = c.getMaxIntrinsicHeight(double.infinity);
    final into = tall / 2 - (_faceHeight / 2 - r);
    if (into <= 0) return 0;
    final d = math.min(into, r);
    return r - math.sqrt(r * r - d * d);
  }

  /// The room either side in [width]: the whole inset while the content's
  /// own width fits beside it, less (to the [_floor]) as it does not; and
  /// the whole inset again once the word must narrow anyway, as CSS's
  /// ellipsis keeps its padding (spilled to the floor, a cut word stood on
  /// the pill's rim, "Remind me Thurs…" at 200%, self-review round 6).
  double _side(double width) {
    final c = child;
    final floor = _floor;
    if (c == null || !width.isFinite) return math.max(_inset, floor);
    final own = c.getMaxIntrinsicWidth(double.infinity);
    if (own > width - 2 * floor + 0.5) return math.max(_inset, floor);
    return math.max(((width - own) / 2).clamp(0.0, _inset), floor);
  }

  /// The least it takes with its word whole: the content and the [_floor]
  /// either side, the rest of the inset spilled.
  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) + 2 * _floor;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) + 2 * math.max(_inset, _floor);

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(math.max(0, width - 2 * _side(width))) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(math.max(0, width - 2 * _side(width))) ?? 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final side = _side(constraints.maxWidth);
    final inner = constraints.deflate(EdgeInsets.symmetric(horizontal: side));
    final own = child?.getDryLayout(inner) ?? Size.zero;
    return constraints.constrain(Size(own.width + 2 * side, own.height));
  }

  @override
  void performLayout() {
    final side = _side(constraints.maxWidth);
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(2 * side, 0));
      return;
    }
    c.layout(
      constraints.deflate(EdgeInsets.symmetric(horizontal: side)),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(c.size.width + 2 * side, c.size.height));
    (c.parentData! as BoxParentData).offset = Offset(
      (size.width - c.size.width) / 2,
      (size.height - c.size.height) / 2,
    );
  }
}

/// Buttons side by side, 10 apart on a phone and 16 on the desktop, as the source's `.btn-row` sets them:
/// equal shares of the line (`repeat(2, minmax(0, 1fr))`), a button's
/// word and glyph eating into its own inset where its share is short of
/// it; one whose word and glyph alone are wider than its share keeps
/// their width and the others share what is left (when even those do not
/// fit, all narrow in proportion). [columns] cuts the line into that many
/// shares however many buttons stand in it, so a lone act keeps its half
/// at the line's start (`.btn-row` is two columns); null gives each button
/// a share. Give it [FrostedButton]s without `expand`: each takes the width
/// it is handed. Every button in it shows the size the largest asks for, so
/// the row shows one top and one bottom: the glass and the ink differ in
/// their fill, never in their height.
///
/// ```dart
/// FrostedButtonRow(children: [FrostedButton.glass('Cancel', onPressed: cancel), FrostedButton('Freeze', icon: FrostedGlyphs.snowflake, onPressed: freeze)])
/// ```
///
/// ```dart
/// FrostedButtonRow(columns: 2, children: [FrostedButton.glass('Report a problem', onPressed: report)])
/// ```
class FrostedButtonRow extends StatelessWidget {
  /// Creates a [FrostedButtonRow].
  const FrostedButtonRow({required this.children, this.columns, super.key});

  /// The buttons, in reading order.
  final List<Widget> children;

  /// How many shares the line is cut into; null, one a button.
  final int? columns;

  @override
  Widget build(BuildContext context) =>
      _ButtonRow(columns: columns, children: FrostedActRow.wrap(children));
}

class _ButtonRow extends MultiChildRenderObjectWidget {
  const _ButtonRow({required super.children, this.columns});

  final int? columns;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderButtonRow(
    Directionality.of(context),
    FrostedBreakpoints.gap(context),
    columns,
    _cap(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderButtonRow)
      ..direction = Directionality.of(context)
      ..gap = FrostedBreakpoints.gap(context)
      ..columns = columns
      ..cap = _cap(context);
  }

  /// From 600 wide a share is at most a control's measure (320): a pair of
  /// acts stands at the line's start, not across a desktop column.
  static double _cap(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= frostedMeasureFrom
      ? frostedControlMeasure
      : double.infinity;
}

class _RowData extends ContainerBoxParentData<RenderBox> {}

class _RenderButtonRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _RowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _RowData> {
  _RenderButtonRow(this._direction, this._gap, this._columns, this._cap);

  double _cap;
  set cap(double value) {
    if (value == _cap) return;
    _cap = value;
    markNeedsLayout();
  }

  int? _columns;
  set columns(int? value) {
    if (value == _columns) return;
    _columns = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
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
    if (child.parentData is! _RowData) child.parentData = _RowData();
  }

  double _gaps(int n) => _gap * math.max(0, n - 1);

  /// Each button's width in [width]: equal shares of the line's columns,
  /// raised to the least a button takes with its word whole (its min
  /// intrinsic width: a [FrostedButton]'s word and glyph, its inset spilled)
  /// where that is more and the rest shared again; all narrowed in
  /// proportion to those when even they do not fit.
  List<double> _widths(double given) {
    final kids = getChildrenAsList();
    final shares = math.max(kids.length, _columns ?? 0);
    final width = _cap.isFinite
        ? math.min(given, _cap * shares + _gaps(shares))
        : given;
    if (kids.isEmpty || !width.isFinite) {
      return [for (final c in kids) c.getMaxIntrinsicWidth(double.infinity)];
    }
    final least = [
      for (final c in kids) c.getMinIntrinsicWidth(double.infinity),
    ];
    final n = math.max(kids.length, _columns ?? 0);
    // The buttons' own columns: the empty ones keep their shares.
    final room = math.max(0.0, width - _gaps(n)) * kids.length / n;
    final own = least;
    final total = own.fold(0.0, (a, b) => a + b);
    if (total >= room) {
      return [
        for (final w in own) total == 0 ? room / kids.length : room * w / total,
      ];
    }
    final fixed = List<double?>.filled(kids.length, null);
    var left = room;
    var open = kids.length;
    var changed = true;
    while (changed && open > 0) {
      changed = false;
      final share = left / open;
      for (var i = 0; i < kids.length; i++) {
        if (fixed[i] == null && own[i] > share) {
          fixed[i] = own[i];
          left -= own[i];
          open--;
          changed = true;
        }
      }
    }
    final share = open == 0 ? 0.0 : left / open;
    return [for (final w in fixed) w ?? share];
  }

  double _extent(BoxConstraints c, List<double> widths) => c.hasBoundedWidth
      ? c.maxWidth
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
      (c, w) => c.getDryLayout(BoxConstraints.tightFor(width: w)).height,
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
      c.layout(
        BoxConstraints.tightFor(width: widths[i++]),
        parentUsesSize: true,
      );
      h = math.max(h, c.size.height);
    }
    var x = 0.0;
    i = 0;
    for (var c = firstChild; c != null; c = childAfter(c)) {
      final w = widths[i++];
      (c.parentData! as _RowData).offset = Offset(
        _direction == TextDirection.rtl ? extent - x - w : x,
        (h - c.size.height) / 2,
      );
      x += w + _gap;
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

/// A line in the meta type with one run of it a link, as the source sets an
/// `a` inside its `p.meta` (the search summary's merchant, the alerts' foot):
/// the line in the quieter ink, and [link], the first place its words stand
/// in [text], in the working ink over a hairline of the page ink at 20%,
/// hung just under the letters' own box as CSS hangs an inline link's
/// border (the line keeps its height). The link is its own link node and
/// tap target, keyed by [linkKey]; a null [onPressed] leaves it inert. The link
/// keeps to one line, as a word does.
///
/// ```dart
/// FrostedLink('at Blue Fern Café in October, \$6.48 a visit', link: 'Blue Fern Café', onPressed: openCategory)
/// ```
///
/// ```dart
/// FrostedLink('Change these any time in Profile.', link: 'Profile', onPressed: openProfile)
/// ```
class FrostedLink extends StatelessWidget {
  /// Creates a [FrostedLink].
  const FrostedLink(
    this.text, {
    required this.link,
    required this.onPressed,
    this.linkKey,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The whole line, the link's words among it.
  final String text;

  /// The words of [text] that are the link.
  final String link;

  /// Where the link leads; null leaves it inert.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// A key for the link, where a tap lands: an app's walk names it by it.
  final Key? linkKey;

  /// How the words align across their lines.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final style = t.textTheme.bodyMedium;
    final at = link.isEmpty ? -1 : text.indexOf(link);
    assert(at >= 0, 'FrostedLink: the link "$link" is not in "$text".');
    if (at < 0) return Text(text, textAlign: textAlign, style: style);
    final end = at + link.length;
    return Text.rich(
      TextSpan(
        children: [
          if (at > 0) TextSpan(text: text.substring(0, at)),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            // Its own node: a line merges what a span holds into its words,
            // and the link would take the whole line with it.
            child: Semantics(
              container: true,
              child: FrostedPressable(
                focusNode: focusNode,
                autofocus: autofocus,
                key: linkKey,
                onPressed: onPressed,
                label: link,
                role: FrostedPressRole.link,
                child: FrostedDim(
                  off: onPressed == null,
                  child: CustomPaint(
                    foregroundPainter: _Hairline(
                      t.colorScheme.textPrimary.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      link,
                      maxLines: 1,
                      style: style.c(t.colorScheme.textSecondary),
                      // The span scales it with the line's text already.
                      textScaler: TextScaler.noScaling,
                      // The letters' own box, without the line's leading: the
                      // hairline hangs under it.
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
      textAlign: textAlign,
      style: style,
    );
  }
}

/// One device-independent pixel of [color] along the foot of the box,
/// outside it, as CSS draws a border-bottom below an inline box's content.
class _Hairline extends CustomPainter {
  const _Hairline(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(0, size.height, size.width, 1),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_Hairline oldDelegate) => oldDelegate.color != color;
}
