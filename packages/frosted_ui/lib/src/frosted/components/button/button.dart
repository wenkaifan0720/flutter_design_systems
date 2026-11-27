import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/act_row.dart';
import '../../internal/face.dart';
import '../../internal/ink_on.dart';
import '../../internal/measure.dart';
import '../../internal/own_size.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../glass.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';
import '../../internal/cap.dart';

// The two faces a [FrostedButton] wears, one per constructor.
enum _Face { ink, glass, danger }

/// Whether [cut] draws a pill [height] tall: round ends, each corner at
/// least half the height (the ink act's own outline; null is the look's).
bool _isPill(OutlinedBorder? cut, double height) {
  bool round(BorderRadiusGeometry radius) {
    final r = radius.resolve(TextDirection.ltr);
    return [
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ].every((c) => math.min(c.x, c.y) >= height / 2 - 0.5);
  }

  return switch (cut) {
    null || StadiumBorder() => true,
    RoundedRectangleBorder(:final borderRadius) ||
    RoundedSuperellipseBorder(:final borderRadius) => round(borderRadius),
    _ => false,
  };
}

/// How large a [FrostedButton] stands.
enum FrostedButtonSize {
  /// 44 tall and 20 in, its word 14 and its glyph 18: a page's or a
  /// sheet's act.
  regular,

  /// 32 tall and 14 in, its word 12 and its glyph 14: a button in a tile's head
  /// or a line of words (See all, Edit).
  small,
}

// The light over a glass act shaded on another glass, by day: from above,
// fading out before its foot.
const LinearGradient _shadedLight = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
);

/// A pill wearing a word: [label] in the label type, an optional [icon] 8
/// before it, 44 tall and as wide as its word; with [expand] it takes all
/// the width there is, 48 tall with its word 16 (a sheet's
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
///
/// ```dart
/// FrostedButton.destructive('Delete task', icon: FrostedGlyphs.delete, onPressed: delete)
/// ```
class FrostedButton extends StatelessWidget {
  /// Creates the page's or the sheet's one act: the word on the ink with a
  /// light along its top edge, standing in its own lift (Move money, Review
  /// transfer, Add \$250).
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

  /// Creates a lesser act: the brighter glass with its rim of light and
  /// hairline edge, the word in the ink (Clear filters, Cancel).
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

  /// Creates an act that destroys or cannot be undone (Delete, Remove):
  /// glass tinted with the theme's danger hue, its word and glyph in a
  /// danger ink that holds 4.5:1 on the tint, day and night.
  const FrostedButton.destructive(
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
  }) : _face = _Face.danger;

  /// The word.
  final String label;

  /// What a press does; null draws the button disabled.
  final VoidCallback? onPressed;

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
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
  /// The ink act keeps its pill (law 6): a shape of its own that squares
  /// its ends fails a debug assert, and the theme's button shape passes it
  /// by. A glass button takes any shape.
  ///
  /// ```dart
  /// FrostedButton.glass(
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
    // The ink act keeps its pill (law 6). A shape of its own `style:` that
    // squares its ends fails a debug assert; the theme's button shape, which
    // shapes the glass buttons too, passes the act by. Either way the act is
    // drawn a pill.
    OutlinedBorder? cutOf(FrostedStyleLayers s) {
      final cut = s.cut(FrostedCorners.full);
      if (_face == _Face.glass || _isPill(cut, height)) return cut;
      final own = style?.shape?.resolve(s.states);
      assert(
        own == null || _isPill(own is StadiumBorder ? null : own, height),
        "Frosted's ink act keeps its pill (law 6, the ink pill): "
        '${own.runtimeType} squares its ends at $height tall. Shape a glass '
        'button (FrostedButton.glass) instead, or leave the act its own.',
      );
      return null;
    }

    // Out of use, the ink act is faint glass, its word in the quiet ink at
    // full strength: dimmed, the ink pill read as a grey smudge and took its
    // white word under 3:1.
    final faint = _face == _Face.ink && !enabled;
    // The destructive act's tint, over the page, and the danger ink that
    // holds 4.5:1 on it.
    final tint = t.colorScheme.dangerSubtle;
    final dangerInk = frostedDangerInk(t, tint);
    Widget draw(Set<WidgetState> states) {
      final s = layers.at(states);
      final cut = cutOf(s);
      final round = FrostedStyleLayers.radiusOf(cut, height, height / 2);
      final radius = BorderRadius.circular(round);
      final ink =
          s.foreground ??
          (faint
              ? t.colorScheme.textSecondary
              : switch (_face) {
                  _Face.ink => t.colorScheme.onButton,
                  _Face.glass => t.colorScheme.textPrimary,
                  _Face.danger => dangerInk,
                });
      final plain = small
          ? t.textTheme.labelLarge
                .at(FrostedChromeMetrics.buttonSmallWord)
                .c(ink)
          : wide
          ? t.textTheme.labelLarge
                .at(FrostedChromeMetrics.buttonWideWord)
                .c(ink)
          : t.textTheme.labelLarge.c(ink);
      // The ink act's word reads at its neighbours' weight by night.
      final own = s.words(plain);
      final words = _face == _Face.ink
          ? s.words(frostedInkWord(t, plain))
          : own;
      Widget word = frostedCapCentred(
        Text(
          label,
          maxLines: expand ? null : 1,
          overflow: expand ? TextOverflow.visible : TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: words,
        ),
      );
      // A pill that hugs its word keeps the width the word takes at its own
      // weight: the heavier night cut set wider, and a caption beside the act
      // that fit by day wrapped by night.
      if (!expand && words.fontWeight != own.fontWeight) {
        word = _SetAsWide(text: label, style: own, child: word);
      }
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
          Flexible(child: word),
        ],
      );
      final padding = s.padding;
      final content = padding == null
          ? _Spill(
              inset: inset,
              round: round,
              height: height,
              // The heavier night word's reach past the width it is set
              // at, either side: the spill's floor keeps it off the ends.
              overhang: !expand && words.fontWeight != own.fontWeight
                  ? _overhang(context, label, own, words)
                  : 0,
              child: row,
            )
          : Padding(padding: padding, child: row);
      final fill = s.fill;
      // No edge of the look's own on either: a light rim inside the glass
      // vanished on a light sheet and left the face 2 smaller than the ink
      // beside it. The glass reaches the box's edge; its rim lies inside.
      final (edge, edges) = s.edgeOf(null, FrostedStrokes.regular);
      Widget face = Container(
        constraints: BoxConstraints(
          minHeight: height,
          maxHeight: expand ? double.infinity : height,
        ),
        width: expand ? double.infinity : null,
        child: switch (_face) {
          // Out of use: the glass a glass act out of use shows (its pane
          // dimmed), the word over it at full strength. A pane at full
          // strength was as bright as a glass act in use beside it, and read
          // as one.
          _Face.ink when faint => Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: FrostedDim(
                  off: true,
                  child: FrostedFace(
                    material: FrostedMaterial.pane,
                    radius: radius,
                    shape: cut,
                    color: fill,
                    wash: s.overlay,
                    edge: edge,
                    edges: edges,
                  ),
                ),
              ),
              content,
            ],
          ),
          // Glass stained with the danger hue, its rim of light kept.
          _Face.danger => FrostedFace(
            material: FrostedMaterial.pane,
            radius: radius,
            shape: cut,
            color: fill ?? tint,
            wash: s.overlay,
            edge: edge,
            edges: edges,
            sheen: t.glass.rim,
            child: content,
          ),
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
          // shaded a step. By day the light falls on it from above, brighter
          // along its top under its sheen (a flat step of grey read duller
          // than the glass it stands on). No light ring round it: on a white
          // slab it would melt into the slab, and the pill would read a size
          // smaller than the act beside it.
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
            gradients: fill == null && !t.isDark
                ? const [_shadedLight]
                : const <Gradient>[],
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
      // The faint glass is the ink act's own off state, drawn at full
      // strength so its word stays readable.
      face = FrostedDim(off: !enabled && !faint, child: face);
      return face;
    }

    final cut = cutOf(layers);
    final Widget face = FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      radius: FrostedStyleLayers.radiusOf(cut, height, height / 2),
      shape: cut,
      builder: (context, states, _) => draw(states),
    );
    // A small or a compact button stands in the whole target round its face
    // (its pressable lays it out there).
    final button = face;
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(FlagProperty('expand', value: expand, ifTrue: 'expand'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        EnumProperty<FrostedButtonSize>(
          'size',
          size,
          defaultValue: FrostedButtonSize.regular,
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedStyle>('style', style, defaultValue: null),
      );
  }
}

/// A button's glyph and word, [inset] either side while they fit; handed
/// less (half a button row), they eat into that room, still centred, on one
/// line; only past the button's whole width does the word narrow. Its intrinsic widths keep the whole inset.
/// The spill stops where the face's [round] corner would cut the words: a
/// line as tall as large text makes it (200%) stays inside the pill's ends.
class _Spill extends SingleChildRenderObjectWidget {
  const _Spill({
    required this.inset,
    required this.round,
    required this.height,
    required super.child,
    this.overhang = 0,
  });

  final double inset;

  /// How far the words draw past their laid-out width, either side (a
  /// heavier cut set as wide as the lighter one, [_SetAsWide]).
  final double overhang;

  /// The face's corner radius.
  final double round;

  /// The face's height.
  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSpill(inset, round, height, overhang);

  @override
  void updateRenderObject(BuildContext context, _RenderSpill renderObject) =>
      renderObject
        ..inset = inset
        ..round = round
        ..faceHeight = height
        ..overhang = overhang;
}

// The least room a label keeps from its face's edges, as ui_core's
// DesignFaceInsetCheck asks (4).
const double _breath = FrostedSpacing.s4;

// How far [label] set in [heavy] reaches past its width set in [own], either
// side, at the reader's text size.
double _overhang(
  BuildContext context,
  String label,
  TextStyle own,
  TextStyle heavy,
) {
  double width(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  return math.max(0.0, (width(heavy) - width(own)) / 2);
}

class _RenderSpill extends RenderShiftedBox {
  _RenderSpill(this._inset, this._round, this._faceHeight, this._overhang)
    : super(null);

  double _overhang;
  set overhang(double value) {
    if (value == _overhang) return;
    _overhang = value;
    markNeedsLayout();
  }

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
  /// content's top and foot (centred in the face), so no word crosses it,
  /// and never under a label's breath (4); a heavier word's [overhang] on
  /// top, so its ink keeps that room too (at 200% "Transfer $500.00" stood
  /// 3.6 from the pill's end by day, 1.8 by night).
  double get _floor => math.max(_curve, _breath) + _overhang;

  double get _curve {
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

  /// The room above and below in [width]: once the words wrap (large
  /// text), one line's room from the face's top and foot, as a single line
  /// stands centred in it, so the first and last lines keep off the face's
  /// edge and clear of its round ends (they touched both at 200%). A line
  /// that does not wrap is centred in the face as it always was.
  double _rise(double width) {
    final c = child;
    if (c == null || !_faceHeight.isFinite || !width.isFinite) return 0;
    final inner = math.max(0.0, width - 2 * _side(width));
    final own = c.getMaxIntrinsicHeight(inner);
    // Words that fit the face with a label's breath above and below stand
    // centred in it as they always did; only taller ones (wrapped at large
    // text) are measured on one line. Two lines of 28 in a 62 face at 200%
    // stood 3 from its foot.
    if (own <= _faceHeight - 2 * _breath + 0.5) return 0;
    final line = c.getMaxIntrinsicHeight(double.infinity);
    if (own <= line + 0.5) return 0;
    return math.max(0, (_faceHeight - line) / 2);
  }

  /// The room either side in [width]: the whole inset while the content's
  /// own width fits beside it, less (to the [_floor]) as it does not; and
  /// the whole inset again once the word must narrow anyway, as CSS's
  /// ellipsis keeps its padding (spilled to the floor, a cut word stood on
  /// the pill's rim, "Remind me Thurs…" at 200%).
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
      (child?.getMinIntrinsicHeight(math.max(0, width - 2 * _side(width))) ??
          0) +
      2 * _rise(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      (child?.getMaxIntrinsicHeight(math.max(0, width - 2 * _side(width))) ??
          0) +
      2 * _rise(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final side = _side(constraints.maxWidth);
    final rise = _rise(constraints.maxWidth);
    final inner = constraints.deflate(
      EdgeInsets.symmetric(horizontal: side, vertical: rise),
    );
    final own = child?.getDryLayout(inner) ?? Size.zero;
    return constraints.constrain(
      Size(own.width + 2 * side, own.height + 2 * rise),
    );
  }

  @override
  void performLayout() {
    final side = _side(constraints.maxWidth);
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(2 * side, 0));
      return;
    }
    final rise = _rise(constraints.maxWidth);
    c.layout(
      constraints.deflate(
        EdgeInsets.symmetric(horizontal: side, vertical: rise),
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(c.size.width + 2 * side, c.size.height + 2 * rise),
    );
    (c.parentData! as BoxParentData).offset = Offset(
      (size.width - c.size.width) / 2,
      (size.height - c.size.height) / 2,
    );
  }
}

/// Buttons side by side, 10 apart on a phone and 16 on the desktop: equal
/// shares of the line, a button's word and glyph eating into its own inset where
/// its share is short of it; one whose word and glyph alone are wider than its
/// share keeps their width and the others share what is left (when even those
/// do not fit, all narrow in proportion). [columns] cuts the line into that
/// many shares however many buttons stand in it, so a lone act keeps its half
/// at the line's start; null gives each button a
/// share. Give it [FrostedButton]s without `expand`: each takes the width it is
/// handed. Every button in it shows the size the largest asks for, so the row
/// shows one top and one bottom: the glass and the ink differ in their fill,
/// never in their height.
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('columns', columns, defaultValue: null));
  }
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

/// A line in the meta type with one run of it a link (the search summary's merchant, the alerts' foot): the line in the quieter
/// ink, and [link], the first place its words stand in [text], in the working
/// ink over a hairline of the page ink at 20%, hung just under the letters' own
/// box (the line keeps its height). The
/// link is its own link node and tap target, keyed by [linkKey]; a null
/// [onPressed] leaves it inert. The link keeps to one line, as a word does.
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

  /// {@macro frosted.focusNode}
  final FocusNode? focusNode;

  /// {@macro frosted.autofocus}
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
                semanticLabel: link,
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('text', text))
      ..add(StringProperty('link', link))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DiagnosticsProperty<Key>('linkKey', linkKey, defaultValue: null))
      ..add(
        EnumProperty<TextAlign>(
          'textAlign',
          textAlign,
          defaultValue: TextAlign.start,
        ),
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

/// [child], a word drawn a cut heavier than [style] (the ink act's word by
/// night, [frostedInkWord]), set as wide as [text] sets in [style]: the
/// heavier word is centred on that width, a pixel or two of it in the pill's
/// inset, so the pill and all beside it stand where they stand by day. One
/// line.
class _SetAsWide extends SingleChildRenderObjectWidget {
  const _SetAsWide({
    required this.text,
    required this.style,
    required super.child,
  });

  final String text;
  final TextStyle style;

  TextPainter _measure(BuildContext context) {
    var own = DefaultTextStyle.of(context).style.merge(style);
    if (MediaQuery.boldTextOf(context)) {
      own = own.merge(const TextStyle(fontWeight: FontWeight.bold));
    }
    return TextPainter(
      text: TextSpan(text: text, style: own),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    );
  }

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSetAsWide(_measure(context));

  @override
  void updateRenderObject(BuildContext context, _RenderSetAsWide renderObject) {
    renderObject.measure = _measure(context);
  }
}

class _RenderSetAsWide extends RenderShiftedBox {
  _RenderSetAsWide(this._measure) : super(null);

  TextPainter _measure;
  set measure(TextPainter value) {
    final old = _measure;
    if (value.text == old.text &&
        value.textDirection == old.textDirection &&
        value.textScaler == old.textScaler &&
        value.locale == old.locale) {
      value.dispose();
      return;
    }
    _measure = value;
    old.dispose();
    markNeedsLayout();
  }

  /// The word's width at its own weight, on one line.
  double get _own => (_measure..layout()).maxIntrinsicWidth;

  @override
  double computeMinIntrinsicWidth(double height) => _own;

  @override
  double computeMaxIntrinsicWidth(double height) => _own;

  BoxConstraints _inner(BoxConstraints constraints, RenderBox child) {
    final width = constraints.constrainWidth(_own);
    // The heavier word's own room: a word cut short at its own weight is
    // cut as short heavier, not sooner.
    final grow = math.max(
      0.0,
      child.getMaxIntrinsicWidth(double.infinity) - _own,
    );
    return BoxConstraints(
      maxWidth: width + grow,
      minHeight: constraints.minHeight,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final inner = child.getDryLayout(_inner(constraints, child));
    return constraints.constrain(
      Size(constraints.constrainWidth(_own), inner.height),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints, child), parentUsesSize: true);
    size = constraints.constrain(
      Size(constraints.constrainWidth(_own), child.size.height),
    );
    (child.parentData! as BoxParentData).offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  void dispose() {
    _measure.dispose();
    super.dispose();
  }
}
