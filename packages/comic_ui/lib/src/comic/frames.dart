// The comic page: square inked panels, narration captions, and the tiers they stand in. Nothing here has a lip shadow; a
// panel is a 3 px contour on a flat fill, and the white between panels is the gutter.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'layout.dart';
import 'print.dart';
import 'theme.dart';
import 'press.dart';
import 'component_themes.dart';
import 'styled.dart';

/// Who a filled label belongs to: `lamp` is the narrator and today, `ink` a fact in full contour, `you` is yours, `shade` the
/// group, `paper` a plain box. Each brings its own letters.
enum ComicSpeaker {
  /// The warm narration fill.
  narrator,

  /// A full-ink label.
  fact,

  /// The viewer's action color.
  currentUser,

  /// The secondary print color.
  group,

  /// Plain paper and its reading ink.
  plain,
}

/// The background and foreground inks for [tone].
(Color, Color) comicToneInks(ComicSpeaker tone, ComicColors c) =>
    switch (tone) {
      ComicSpeaker.narrator => (c.caption, c.onCaption),
      ComicSpeaker.fact =>
        c.dark ? (c.control, c.onPaper) : (c.outline, c.paper),
      ComicSpeaker.currentUser => (c.primary, c.onPrimary),
      ComicSpeaker.group => (c.shade, c.onShade),
      ComicSpeaker.plain => (c.paper, c.onPaper),
    };

/// A narration caption: the square box a narrator talks from. By default it hangs in its panel's top corner, ruled on its two
/// open sides. [free] stands it alone with all four edges, to lay over art. [tight] is the size for a small panel.
///
/// ```dart
/// ComicCaption('Meanwhile, by the lake', icon: ComicGlyphs.mapPin)
/// ```
class ComicCaption extends StatelessWidget {
  /// Creates a [ComicCaption].
  const ComicCaption(
    this.words, {
    super.key,
    this.style,
    this.icon,
    this.tone = ComicSpeaker.narrator,
    this.free = false,
    this.tight = false,
    this.wordsAt,
  });

  /// How far in from the caption's start edge its words begin. A panel sets it to its own inset, so the caption's words
  /// stand on the keyline its rows' words do. Null keeps the caption's own padding.
  final double? wordsAt;

  /// Surface appearance above the badge theme.
  final ComicStyle? style;

  /// The words displayed in this composition.
  final String words;

  /// The optional glyph beside the words.
  final IconData? icon;

  /// The semantic or surface tone of this component.
  final ComicSpeaker tone;

  /// [free]: draws the caption as a standalone framed label. [tight]: uses reduced spacing for the compact label.
  final bool free, tight;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final (fill, letters) = comicToneInks(tone, t.colors);
    final look = ComicStyleOf([style, t.badgeTheme], const {});
    final line = comicRim(t, look, t.colors.nightLine);
    final size = tight ? 11.0 : 12.0;
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: AnimatedComicShape(
        shape: look.shape ?? t.shapes.small,
        builder: (context, shape) => DecoratedBox(
          decoration: shape != null
              ? ShapeDecoration(
                  color: look.fill ?? fill,
                  shape: shape.copyWith(side: line),
                )
              : BoxDecoration(
                  color: look.fill ?? fill,
                  border: free
                      ? Border.fromBorderSide(line)
                      : BorderDirectional(end: line, bottom: line),
                ),
          child: Padding(
            padding:
                (look.padding(Directionality.of(context)) ??
                        t.density.padding(
                          (tight
                                  ? const EdgeInsetsDirectional.fromSTEB(
                                      7,
                                      4,
                                      7,
                                      3,
                                    )
                                  : free
                                  ? const EdgeInsetsDirectional.fromSTEB(
                                      10,
                                      6,
                                      10,
                                      5,
                                    )
                                  : const EdgeInsetsDirectional.fromSTEB(
                                      10,
                                      5,
                                      10,
                                      4,
                                    ))
                              .resolve(Directionality.of(context)),
                        ))
                    .add(shape?.dimensions ?? EdgeInsets.zero)
                    .add(
                      shape == null ? EdgeInsets.zero : const EdgeInsets.all(6),
                    )
                    .resolve(Directionality.of(context))
                    .startAt(wordsAt, Directionality.of(context)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: look.iconSize ?? 15,
                    color: look.foreground ?? letters,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    words.toUpperCase(),
                    style:
                        look.textStyle ??
                        t.type.text(
                          size,
                          free ? 1.3 : 1.2,
                          weight: FontWeight.w800,
                          color: look.foreground ?? letters,
                          tracking: free ? .05 : .06,
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

/// A panel's fill. `plain` the card; `well` a step off it; `dots` and `currentUserDots` Ben-Day under the words, whose quiet words go
/// to full ink by themselves; `lamp` the narrator's fill, whose inks all change to its letters.
enum ComicPanelFill {
  /// The panel ground.
  plain,

  /// A recessed tonal ground.
  inset,

  /// Halftone dots on the secondary tint.
  dots,

  /// Halftone dots on the viewer's tint.
  currentUserDots,

  /// The warm narration fill.
  lamp,
}

/// A slanted gutter's side, handed down by `ComicTier(slanted: true)`.
class _SlantScope extends InheritedWidget {
  const _SlantScope({
    required this.slant,
    required this.lastPanel,
    required super.child,
  });
  final double slant;
  final bool lastPanel;
  @override
  bool updateShouldNotify(_SlantScope old) =>
      old.slant != slant || old.lastPanel != lastPanel;
}

/// How much room the slanted gutter takes from a panel's end and its start: (start, end). A bleeding panel's own band reads it.
(double, double) comicSlantInset(BuildContext context) {
  final s = context.dependOnInheritedWidgetOfExactType<_SlantScope>();
  if (s == null) return (0, 0);
  return s.lastPanel ? (s.slant, 0) : (0, s.slant);
}

class _SlantClip extends CustomClipper<Path> {
  _SlantClip(this.slant, this.lastPanel, this.rtl);
  final double slant;
  final bool lastPanel, rtl;
  @override
  Path getClip(Size s) {
    final p = Path();
    double x(double v) => rtl ? s.width - v : v;
    if (lastPanel) {
      p
        ..moveTo(x(slant), 0)
        ..lineTo(x(s.width), 0)
        ..lineTo(x(s.width), s.height)
        ..lineTo(x(0), s.height);
    } else {
      p
        ..moveTo(x(0), 0)
        ..lineTo(x(s.width), 0)
        ..lineTo(x(s.width - slant), s.height)
        ..lineTo(x(0), s.height);
    }
    return p..close();
  }

  @override
  bool shouldReclip(_SlantClip o) =>
      o.slant != slant || o.lastPanel != lastPanel || o.rtl != rtl;
}

extension _StartAt on EdgeInsets {
  /// These insets with the start side set to [start], when given.
  EdgeInsets startAt(double? start, TextDirection direction) => start == null
      ? this
      : direction == TextDirection.ltr
      ? copyWith(left: start)
      : copyWith(right: start);
}

/// The start side of [insets] in [context]'s direction.
double _startOf(EdgeInsetsGeometry insets, BuildContext context) {
  final direction = Directionality.of(context);
  final resolved = insets.resolve(direction);
  return direction == TextDirection.ltr ? resolved.left : resolved.right;
}

/// The everyday inside of a panel: 14 on a phone, 20 22 22 on a desktop.
EdgeInsets comicPanelInset(ComicThemeData t) => t.desk
    ? const EdgeInsets.fromLTRB(22, 20, 22, 22)
    : const EdgeInsets.all(14);

/// The panel: a 3 px square contour on a fill, with an optional caption in its corner. Every box on a page is one of these. It
/// takes the height its tier gives it, and its child grows to fill that. Children: anything. [bleed] takes away the inside, for
/// art that runs to the contour. [compact] asks a star inside for its short form on a phone.
///
/// ```dart
/// ComicPanel(caption: 'Coming up', captionIcon: ComicGlyphs.calendar, child: ComicListTile(isFirst: true, title: 'Fri 4 Dec'))
/// ```
class ComicPanel extends StatelessWidget {
  /// Creates a [ComicPanel].
  const ComicPanel({
    super.key,
    this.style,
    this.child,
    this.caption,
    this.captionIcon,
    this.captionTone = ComicSpeaker.narrator,
    this.ground = ComicPanelFill.plain,
    this.bleed = false,
    this.padding,
    this.compact = false,
    this.shrinkWrap = false,
    this.onPressed,
    this.label,
    this.selected,
    this.focusNode,
    this.autofocus = false,
  });

  /// Per-state frame and content style, above cardTheme.
  final ComicStyle? style;

  /// Content placed inside this widget.
  final Widget? child;

  /// The optional narration caption.
  final String? caption;

  /// An optional glyph beside the narration caption.
  final IconData? captionIcon;

  /// The caption's semantic surface treatment.
  final ComicSpeaker captionTone;

  /// The background treatment behind this content.
  final ComicPanelFill ground;

  /// [bleed]: allows content to reach the frame's inside edges. [compact]: uses the compact form of the composition.
  final bool bleed, compact;

  /// Hugs the content of a captionless panel, for compact control surfaces.
  final bool shrinkWrap;

  /// Space between the content and its boundary.
  final EdgeInsetsGeometry? padding;

  /// Called when activated; null disables the action.
  final VoidCallback? onPressed;

  /// What a screen reader says of a pressable panel.
  final String? label;

  /// The selection state of a selectable panel; null omits that state.
  final bool? selected;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context),
        look = ComicStyleOf([
          style,
          ComicTheme.of(context).cardTheme,
        ], const {});
    if (onPressed == null) {
      final face = _build(context, {
        if (selected == true) WidgetState.selected,
      });
      return selected == null
          ? face
          : Semantics(
              container: true,
              selected: selected,
              label: label,
              child: face,
            );
    }
    return ComicPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      label: label ?? caption,
      selected: selected,
      outline: look.shapes(t.shapes.medium),
      overlay: look.overlay,
      builder: _build,
    );
  }

  Widget _build(BuildContext context, Set<WidgetState> states) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final look = ComicStyleOf([style, t.cardTheme], states),
        rim = comicRim(
          t,
          ComicStyleOf([style, t.cardTheme], states),
          c.nightLine,
          3,
        );
    final (slantStart, slantEnd) = comicSlantInset(context);
    final inset =
        look.padding(Directionality.of(context)) ??
        padding ??
        comicPanelInset(t);
    final Widget? body = child == null
        ? null
        : bleed
        ? child
        // The panel's words hold one keyline at its inset; the caption is the frame's corner tag, outside it.
        : DesignKeylineRegion(
            label: caption ?? 'Panel',
            child: Padding(
              padding: inset.add(
                EdgeInsetsDirectional.only(start: slantStart, end: slantEnd),
              ),
              child: child,
            ),
          );
    Widget inner = shrinkWrap && caption == null
        ? body ?? const SizedBox.shrink()
        : ComicColumn(
            children: [
              if (caption != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: slantStart),
                  child: ComicCaption(
                    caption!,
                    icon: captionIcon,
                    tone: captionTone,
                    tight: slantStart + slantEnd > 0,
                    // The caption's words on the keyline of the panel's own words.
                    wordsAt: bleed ? null : _startOf(inset, context),
                  ),
                ),
              if (body != null) ComicGrow(child: body),
            ],
          );
    if (compact) inner = ComicCompactScope(on: true, child: inner);
    inner = switch (ground) {
      ComicPanelFill.dots => ComicBenDay(
        color: c.dotTint,
        pitch: 9,
        radius: 2.2,
        child: ComicDotsScope(child: inner),
      ),
      ComicPanelFill.currentUserDots => ComicBenDay(
        color: c.currentUserDot,
        pitch: 10,
        radius: c.dark ? 2.2 : 1.9,
        child: ComicDotsScope(child: inner),
      ),
      ComicPanelFill.lamp => ComicLetteringScope(c.onCaption, child: inner),
      _ => inner,
    };
    final fill =
        look.fill ??
        switch (ground) {
          ComicPanelFill.inset => c.inset,
          ComicPanelFill.lamp => c.caption,
          _ => c.card,
        };
    final slant = context.dependOnInheritedWidgetOfExactType<_SlantScope>();
    if (look.foreground != null) {
      inner = ComicLetteringScope(look.foreground!, child: inner);
    }
    if (look.textStyle != null) {
      inner = DefaultTextStyle.merge(style: look.textStyle!, child: inner);
    }
    final content = inner;
    return AnimatedComicShape(
      shape: look.shape ?? (slant == null ? t.shapes.medium : null),
      builder: (context, shape) {
        Widget box;
        if (shape != null) {
          final outline = shape.copyWith(side: rim);
          box = ComicStateDecoration(
            decoration: ShapeDecoration(color: fill, shape: outline),
            child: Padding(
              padding: EdgeInsets.all(rim.width),
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: comicInsetShape(shape, rim.width),
                  textDirection: Directionality.of(context),
                ),
                child: Padding(
                  padding: shape.copyWith(side: BorderSide.none).dimensions,
                  child: content,
                ),
              ),
            ),
          );
        } else if (slant != null) {
          final clip = _SlantClip(
            slant.slant,
            slant.lastPanel,
            Directionality.of(context) == TextDirection.rtl,
          );
          box = ClipPath(
            clipper: clip,
            child: ColoredBox(
              color: rim.color,
              child: Padding(
                padding: EdgeInsets.all(rim.width),
                child: ClipPath(
                  clipper: clip,
                  child: ColoredBox(color: fill, child: inner),
                ),
              ),
            ),
          );
        } else {
          box = ComicStateDecoration(
            decoration: BoxDecoration(
              color: fill,
              border: Border.fromBorderSide(rim),
            ),
            child: Padding(
              padding: EdgeInsets.all(rim.width),
              child: ClipRect(child: inner),
            ),
          );
        }
        return box;
      },
    );
  }
}

/// How a tier stands on a phone. `pairs`: two across, a lone last taking the row. `strip`: two, one, two, one, as a comic page
/// breaks up a grid. `stack`: one under another, for panels of words.
enum ComicTierLayout {
  /// Pairs panels on a compact screen.
  pairs,

  /// Scrolls the panels in a horizontal strip.
  strip,

  /// Stacks panels vertically.
  stack,
}

/// A tier of a comic page: panels side by side on a desktop, sharing a height and a 16 gutter, reflowed on a phone with a 10
/// gutter. Give it plain children, usually `ComicPanel`s. It picks their shares by how many there are: one takes the row, two
/// halves, three thirds, four quarters, five with the last one wider. [spans] sets them yourself, in parts of their sum, on a
/// desktop only: on a phone the tier reflows by [phone] and the spans don't hold. Where a column would be under 130 (grown
/// with the text size) it stacks them, however wide the window. Keep it to two or three tiers before a splash breaks
/// them up. [slanted] cuts the gutter between two panels on a lean, once a page.
///
/// ```dart
/// ComicTier(spans: const [5, 3], phone: ComicTierLayout.pairs, children: [ComicPanel(child: a), ComicPanel(child: b)])
/// ```
class ComicTier extends StatelessWidget {
  /// Creates a [ComicTier].
  const ComicTier({
    super.key,
    required this.children,
    this.spans,
    this.phone = ComicTierLayout.pairs,
    this.slanted = false,
  });

  /// Child widgets in their display order.
  final List<Widget> children;

  /// The panels' shares on a desktop, in parts of their sum. A phone reflows by [phone] instead.
  final List<int>? spans;

  /// How a tier reflows on a compact screen.
  final ComicTierLayout phone;

  /// Leans adjacent panels along a shared gutter.
  final bool slanted;

  static const double _least = 130;

  static List<int> _shares(int n) => switch (n) {
    1 => const [1],
    2 => const [1, 1],
    3 => const [1, 1, 1],
    4 => const [1, 1, 1, 1],
    5 => const [1, 1, 1, 1, 2],
    _ => List.filled(n, 1),
  };

  Widget _row(List<Widget> cells, List<int> flex, double gap, double slant) {
    final sum = flex.fold<int>(0, (a, b) => a + b);
    return ComicEqualRow(
      flex: flex,
      gap: gap,
      columns: sum,
      pull: slant,
      children: slant > 0 && cells.length == 2
          ? [
              _SlantScope(slant: slant, lastPanel: false, child: cells[0]),
              _SlantScope(slant: slant, lastPanel: true, child: cells[1]),
            ]
          : cells,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final flex = spans ?? _shares(children.length);
    final gap = t.desk ? 16.0 : 10.0;
    final slant = slanted && children.length == 2
        ? (t.desk ? 44.0 : 18.0)
        : 0.0;
    // Large text needs wider columns before its words break mid-word.
    final least = MediaQuery.textScalerOf(context).scale(_least);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.hasBoundedWidth ? box.maxWidth : t.width;
        final sum = flex.fold<int>(0, (a, b) => a + b);
        final smallest = flex.reduce(math.min);
        final across = (w + gap) * smallest / sum - gap >= least;
        if (t.desk && across) {
          if (children.length <= 5 || spans != null) {
            return _row(children, flex, gap, slant);
          }
          // More than five stay a page of tiers of three.
          return ComicColumn(
            gap: gap,
            children: [
              for (var i = 0; i < children.length; i += 3)
                _row(
                  children.sublist(i, math.min(i + 3, children.length)),
                  List.filled(math.min(3, children.length - i), 1),
                  gap,
                  0,
                ),
            ],
          );
        }
        final halves = (w - gap) / 2 >= least;
        if (phone == ComicTierLayout.stack || !halves || children.length == 1) {
          return ComicColumn(gap: gap, children: children);
        }
        final rows = <Widget>[];
        var i = 0, turn = 0;
        while (i < children.length) {
          final single =
              i == children.length - 1 ||
              (phone == ComicTierLayout.strip && turn % 2 == 1);
          if (single) {
            rows.add(children[i]);
            i += 1;
          } else {
            rows.add(
              _row([children[i], children[i + 1]], const [1, 1], gap, slant),
            );
            i += 2;
          }
          turn += 1;
        }
        return ComicColumn(gap: gap, children: rows);
      },
    );
  }
}

/// A column of panels inside a tier, with the page's gutter. [grow] lets its last panel take the height the tier has left, so
/// the column ends level with its neighbour rather than on a blank third.
///
/// ```dart
/// ComicPanelStack(children: [ComicPanel(child: a), ComicPanel(child: b)])
/// ```
class ComicPanelStack extends StatelessWidget {
  /// Creates a [ComicPanelStack].
  const ComicPanelStack({super.key, required this.children, this.grow = true});

  /// Child widgets in their display order.
  final List<Widget> children;

  /// Whether the layout uses available space for this child.
  final bool grow;
  @override
  Widget build(BuildContext context) => ComicColumn(
    gap: ComicTheme.of(context).desk ? 16 : 10,
    children: [
      for (var i = 0; i < children.length; i++)
        grow && i == children.length - 1
            ? ComicGrow(child: children[i])
            : children[i],
    ],
  );
}

/// A box inside a panel, a step off its fill: one room of three, one figure of three.
///
/// ```dart
/// ComicWell(child: Text('30 min'))
/// ```
class ComicWell extends StatelessWidget {
  /// Creates a [ComicWell].
  const ComicWell({
    super.key,
    this.style,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 9),
    this.lamp = false,
  });

  /// Per-state surface appearance above the card theme.
  final ComicStyle? style;

  /// Content placed inside this widget.
  final Widget child;

  /// Space between the content and its boundary.
  final EdgeInsetsGeometry padding;

  /// The one that matters: the narrator's fill and its letters.
  final bool lamp;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = ComicStyleOf([style, t.cardTheme], const {});
    final rim = comicRim(t, look, c.nightLine);
    Widget inside = lamp
        ? ComicLetteringScope(c.onCaption, child: child)
        : child;
    if (look.foreground != null) {
      inside = ComicLetteringScope(look.foreground!, child: inside);
    }
    if (look.textStyle != null) {
      inside = DefaultTextStyle.merge(style: look.textStyle, child: inside);
    }
    return AnimatedComicShape(
      shape: look.shape ?? t.shapes.medium,
      builder: (context, shape) => DecoratedBox(
        decoration: ShapeDecoration(
          color: look.fill ?? (lamp ? c.caption : c.inset),
          shape: (shape ?? const RoundedRectangleBorder()).copyWith(side: rim),
        ),
        child: Padding(
          padding:
              (look.padding(Directionality.of(context)) ??
                  t.density.padding(
                    padding.resolve(Directionality.of(context)),
                  )) +
              EdgeInsets.all(
                rim.width + comicCornerInset(shape, Directionality.of(context)),
              ) +
              (shape?.dimensions.resolve(Directionality.of(context)) ??
                  EdgeInsets.zero),
          child: inside,
        ),
      ),
    );
  }
}

/// What a `ComicPanel(compact: true)` tells the star inside it; a star asks with [comicCompactHere].
///
/// ```dart
/// ComicCompactScope(on: true, child: ComicBurst(number: '12'))
/// ```
class ComicCompactScope extends InheritedWidget {
  /// Creates a [ComicCompactScope].
  const ComicCompactScope({super.key, required this.on, required super.child});

  /// Whether the mark is active.
  final bool on;
  @override
  bool updateShouldNotify(ComicCompactScope old) => old.on != on;
}

/// Whether a star should draw its compact form: inside a compact frame, on a phone.
bool comicCompactHere(BuildContext context) =>
    !ComicTheme.of(context).desk &&
    (context.dependOnInheritedWidgetOfExactType<ComicCompactScope>()?.on ??
        false);
