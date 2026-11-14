import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/icon_fill.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How a [Fluent2TabList] draws its tabs, Fluent's `appearance`:
/// [transparent] words on no fill with the brand indicator under the
/// selected one (the default), [subtle] the same on the subtle fill's
/// hover, [subtleCircular] pills with the selected one on the brand's tint
/// in its stroke, [filledCircular] pills on the third neutral layer with
/// the selected one in the brand's fill.
enum Fluent2TabAppearance {
  /// Words on no fill, the brand indicator under the selected tab.
  transparent,

  /// The same on the subtle fill's hover.
  subtle,

  /// Pills, the selected one on the brand's tint in its stroke.
  subtleCircular,

  /// Pills on the third neutral layer, the selected one in the brand's fill.
  filledCircular,
}

/// A tab's size, Fluent's `size`: [small] 32 tall (6 round its words),
/// [medium] 44 (12 over and under, 10 at the sides), [large] 54 in body2
/// with a 24 glyph.
enum Fluent2TabSize {
  /// The small size.
  small,

  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// One tab of a [Fluent2TabList.items]: its [label], a glyph before it
/// ([icon], [selectedIcon] while it is the selected tab, Fluent's filled
/// design), and whether it can be chosen ([enabled]).
///
/// ```dart
/// Fluent2Tab('Files', icon: Fluent2Icons.folder, selectedIcon: Fluent2Icons.folderFilled)
/// ```
@immutable
class Fluent2Tab {
  /// A tab labelled [label].
  const Fluent2Tab(
    this.label, {
    this.icon,
    this.selectedIcon,
    this.enabled = true,
  });

  /// Its words.
  final String label;

  /// A glyph before the words.
  final IconData? icon;

  /// The glyph while it is the selected tab; null wears [icon]'s filled
  /// twin, which it also wears under the pointer.
  final IconData? selectedIcon;

  /// False draws it inert in the disabled ink.
  final bool enabled;
}

/// Fluent 2's TabList: peer sections of one page as a row of [tabs] (a
/// column with [vertical]), the one at [selectedIndex] selected: its
/// words in body1Strong (the width each tab keeps either way), its glyph
/// filled and in the brand, and under it the 3 brand indicator that slides
/// from the tab chosen before (`durationSlow`, `curveDecelerateMax`; it
/// settles at once under Reduce Motion), or in the
/// circular appearances its pill. A row longer than its room scrolls,
/// keeping the selected tab in view. A row of transparent or subtle tabs
/// hangs its first tab's inset (its padding round the words) toward the
/// start, so the first word and its indicator start where a title and a
/// field in the same column start; a pill's edge stays on the column's. A tab press asks [onChanged] for its
/// index; null draws the list disabled. [Fluent2TabList.items] takes tabs
/// with glyphs, or one out of use. Read as a tab bar of tabs, the
/// selected one said.
///
/// ```dart
/// Fluent2TabList(tabs: const ['Chat', 'Files', 'Notes'], selectedIndex: tab, onChanged: (i) => setState(() => tab = i))
/// ```
class Fluent2TabList extends StatefulWidget {
  /// A tab per word in [tabs].
  const Fluent2TabList({
    super.key,
    required List<String> this.tabs,
    required this.selectedIndex,
    this.onChanged,
    this.appearance = Fluent2TabAppearance.transparent,
    this.size = Fluent2TabSize.medium,
    this.vertical = false,
    this.label,
  }) : items = null;

  /// A tab per [Fluent2Tab] in [items]: words with a glyph, or a tab out
  /// of use.
  const Fluent2TabList.items({
    super.key,
    required List<Fluent2Tab> this.items,
    required this.selectedIndex,
    this.onChanged,
    this.appearance = Fluent2TabAppearance.transparent,
    this.size = Fluent2TabSize.medium,
    this.vertical = false,
    this.label,
  }) : tabs = null;

  /// The tabs' words (the default constructor).
  final List<String>? tabs;

  /// The tabs (the [Fluent2TabList.items] constructor).
  final List<Fluent2Tab>? items;

  /// The selected tab's index.
  final int selectedIndex;

  /// Asked for a tab's index when it is pressed; null draws the list
  /// disabled.
  final ValueChanged<int>? onChanged;

  /// Fluent's `appearance`: how the tabs are drawn.
  final Fluent2TabAppearance appearance;

  /// Fluent's `size`: the tabs' height and type.
  final Fluent2TabSize size;

  /// Lays the tabs in a column, the indicator at their start.
  final bool vertical;

  /// What a screen reader calls the list.
  final String? label;

  List<Fluent2Tab> get _all =>
      items ?? [for (final word in tabs!) Fluent2Tab(word)];

  int get _count => items?.length ?? tabs!.length;

  @override
  State<Fluent2TabList> createState() => _Fluent2TabListState();
}

class _Fluent2TabListState extends State<Fluent2TabList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: Fluent2Motion.slow,
    value: 1,
  );
  late List<GlobalKey> _keys = _keysFor(widget._count);

  /// Where the indicator starts its slide from, relative to the selected
  /// tab: its offset along the axis and its length's ratio.
  double _from = 0;
  double _scale = 1;

  static List<GlobalKey> _keysFor(int n) => [
    for (var i = 0; i < n; i++) GlobalKey(),
  ];

  @override
  void didUpdateWidget(Fluent2TabList old) {
    super.didUpdateWidget(old);
    if (old._count != widget._count) {
      _keys = _keysFor(widget._count);
      return;
    }
    if (old.selectedIndex == widget.selectedIndex) return;
    final was = old.selectedIndex;
    final now = widget.selectedIndex;
    if (was < 0 || now < 0 || was >= _keys.length || now >= _keys.length) {
      return;
    }
    final before = _rectOf(was);
    final after = _rectOf(now);
    final circular =
        widget.appearance == Fluent2TabAppearance.subtleCircular ||
        widget.appearance == Fluent2TabAppearance.filledCircular;
    if (before != null &&
        after != null &&
        !circular &&
        Fluent2Motion.on(context)) {
      final length = widget.vertical ? after.height : after.width;
      _from = widget.vertical
          ? before.top - after.top
          : before.left - after.left;
      _scale = length == 0
          ? 1
          : (widget.vertical ? before.height : before.width) / length;
      _slide
        ..value = 0
        ..animateTo(1, curve: Fluent2Motion.decelerateMax);
    } else {
      _slide.value = 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final at = _keys[now].currentContext;
      if (!mounted || at == null) return;
      Scrollable.ensureVisible(
        at,
        alignment: 0.5,
        duration: Fluent2Motion.on(context)
            ? Fluent2Motion.normal
            : Duration.zero,
        curve: Fluent2Motion.decelerateMid,
      );
    });
  }

  Rect? _rectOf(int i) {
    final box = _keys[i].currentContext?.findRenderObject();
    final list = context.findRenderObject();
    if (box is! RenderBox || list is! RenderBox || !box.hasSize) return null;
    final at = box.localToGlobal(Offset.zero, ancestor: list);
    return at & box.size;
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circular =
        widget.appearance == Fluent2TabAppearance.subtleCircular ||
        widget.appearance == Fluent2TabAppearance.filledCircular;
    final gap = !circular
        ? 0.0
        : widget.size == Fluent2TabSize.small
        ? Fluent2Spacing.sNudge
        : Fluent2Spacing.s;
    final change = widget.onChanged;
    final selected = widget.selectedIndex;
    final tabs = [
      for (final (i, tab) in widget._all.indexed)
        KeyedSubtree(
          key: _keys[i],
          child: _Tab(
            tab: tab,
            selected: i == selected,
            appearance: widget.appearance,
            size: widget.size,
            vertical: widget.vertical,
            slide: i == selected ? _slide : null,
            from: _from,
            scale: _scale,
            onTap: change == null || !tab.enabled
                ? null
                : () {
                    if (i != selected) change(i);
                  },
          ),
        ),
    ];
    final bar = Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      label: widget.label,
      child: widget.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: tabs,
            )
          // The row is as tall as its tallest tab (a tab with a glyph),
          // and every tab takes that height, as Fluent's flex row
          // stretches its tabs; never the height round the list. Under a
          // finger that is the 48 target, a circular tab's pill included
          // (every control's face stands the target there).
          : IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: tabs,
              ),
            ),
    );
    if (widget.vertical) return bar;
    // The first tab's inset: its padding at the side, and the words' 2 when
    // it shows no glyph (a glyph's box starts at the padding).
    final side = widget.size == Fluent2TabSize.small ? 6.0 : 10.0;
    final hang = circular || widget._count == 0
        ? 0.0
        : side + (widget._all.first.icon == null ? 2 : 0);
    // A row of tabs keeps every name whole: as the reader's text grows the
    // names grow only while the row fits its room (never under their own
    // size), and a row longer than that scrolls.
    final strip = LayoutBuilder(
      builder: (context, box) {
        // The room the hang already widened.
        final fit = _fitScale(context, box.maxWidth, gap, side);
        final size =
            (widget.size == Fluent2TabSize.large
                    ? context.fluent2Theme.subtitle2
                    : context.fluent2Theme.body1Strong)
                .fontSize ??
            14;
        final capped =
            fit > 1 &&
            fit < MediaQuery.textScalerOf(context).scale(size) / size;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: fit,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            // Capped to fit, the row stands in its room: a face's own
            // rounding past the measure is drawn smaller whole, never cut
            // at the edge.
            child: capped
                ? SizedBox(
                    width: box.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: bar,
                    ),
                  )
                : bar,
          ),
        );
      },
    );
    if (hang == 0) return strip;
    return _HangStart(by: hang, child: strip);
  }

  /// The largest text scale, at most the reader's and at least 1, at which
  /// the row's tabs stand in [room] side by side ([gap] apart, [side] of
  /// padding each side of a tab, a glyph and its gap where a tab has one,
  /// the words at their chosen weight and 2 each side).
  double _fitScale(BuildContext context, double room, double gap, double side) {
    final t = context.fluent2Theme;
    final large = widget.size == Fluent2TabSize.large;
    final strong = large ? t.subtitle2 : t.body1Strong;
    final size = strong.fontSize ?? 14;
    final reader = MediaQuery.textScalerOf(context).scale(size) / size;
    final tabs = widget._all;
    if (!room.isFinite || tabs.isEmpty || reader <= 1) return reader;
    final glyph = large ? Fluent2IconSize.i24 : Fluent2IconSize.i20;
    final glyphGap = widget.size == Fluent2TabSize.small
        ? Fluent2Spacing.xxs
        : Fluent2Spacing.sNudge;
    var fixed = gap * (tabs.length - 1);
    var words = 0.0;
    for (final tab in tabs) {
      fixed += 2 * side + 4 + (tab.icon == null ? 0 : glyph + glyphGap);
      final painter = TextPainter(
        text: TextSpan(text: tab.label, style: strong),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      words += painter.width;
      painter.dispose();
    }
    if (words <= 0) return reader;
    // A hundredth under the exact fit, so layout's rounding never leaves a
    // hair to scroll.
    final fits = ((room - fixed) / words * 100).floorToDouble() / 100;
    return math.max(1.0, math.min(reader, fits));
  }
}

/// Lays [child] out [by] wider than the room it is given and moves it [by]
/// toward the start, so its first words start on the room's start while its
/// end keeps the room's end. Paint and hits move together (the hung part
/// answers as far as the room round the strip reaches).
class _HangStart extends SingleChildRenderObjectWidget {
  const _HangStart({required this.by, required super.child});

  final double by;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHangStart(by, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderHangStart renderObject) {
    renderObject
      ..by = by
      ..direction = Directionality.of(context);
  }
}

class _RenderHangStart extends RenderProxyBox {
  _RenderHangStart(this._by, this._direction);

  double _by;
  set by(double value) {
    if (value == _by) return;
    _by = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsPaint();
  }

  /// Where the child is painted: [_by] left of the box from the left, at
  /// the box's left (reaching [_by] past its right) from the right.
  Offset get _shift => Offset(_direction == TextDirection.rtl ? 0 : -_by, 0);

  BoxConstraints _inner(BoxConstraints c) => c.hasBoundedWidth
      ? c.copyWith(minWidth: c.minWidth + _by, maxWidth: c.maxWidth + _by)
      : c;

  Size _outer(BoxConstraints c, Size inner) =>
      c.constrain(Size(math.max(0, inner.width - _by), inner.height));

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(0, super.computeMinIntrinsicWidth(height) - _by);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(0, super.computeMaxIntrinsicWidth(height) - _by);

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width + _by);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width + _by);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _outer(constraints, child!.getDryLayout(_inner(constraints)));

  @override
  void performLayout() {
    child!.layout(_inner(constraints), parentUsesSize: true);
    size = _outer(constraints, child!.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(child!, offset + _shift);

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(_shift.dx, 0, 0, 1);

  // The hung part answers too, as far as the room round the strip reaches.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      hitTestChildren(result, position: position);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: _shift,
        position: position,
        hitTest: (result, at) => child!.hitTest(result, position: at),
      );
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.appearance,
    required this.size,
    required this.vertical,
    required this.slide,
    required this.from,
    required this.scale,
    required this.onTap,
  });

  final Fluent2Tab tab;
  final bool selected;
  final Fluent2TabAppearance appearance;
  final Fluent2TabSize size;
  final bool vertical;
  final Animation<double>? slide;
  final double from;
  final double scale;
  final VoidCallback? onTap;

  bool get _circular =>
      appearance == Fluent2TabAppearance.subtleCircular ||
      appearance == Fluent2TabAppearance.filledCircular;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final large = size == Fluent2TabSize.large;
    // useTabStyles: the button's padding by size and axis; a circular tab
    // gives a pixel of its block padding to its 1 stroke.
    final EdgeInsets padding = switch ((size, vertical)) {
      (Fluent2TabSize.small, false) => const EdgeInsets.all(6),
      (Fluent2TabSize.small, true) => const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      (Fluent2TabSize.medium, false) => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      (Fluent2TabSize.medium, true) => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      (Fluent2TabSize.large, false) => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      (Fluent2TabSize.large, true) => const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
    };
    final room = _circular
        ? EdgeInsets.symmetric(
            horizontal: padding.left - 1,
            vertical: switch (size) {
              Fluent2TabSize.small => 1,
              Fluent2TabSize.medium => 5,
              Fluent2TabSize.large => 7,
            },
          )
        : padding;
    final glyphSize = large ? Fluent2IconSize.i24 : Fluent2IconSize.i20;
    final gap = size == Fluent2TabSize.small
        ? Fluent2Spacing.xxs
        : Fluent2Spacing.sNudge;
    final rest = large ? t.body2 : t.body1;
    final strong = large ? t.subtitle2 : t.body1Strong;
    // The role alone, merged with the press's own node: the press brings the
    // selected state, the enabled flag and the tap (the press's node is a
    // container, so a role around it would stand on a node of its own).
    return Fluent2HitSlop(
      child: MergeSemantics(
        child: Semantics(
          role: SemanticsRole.tab,
          child: Fluent2Pressable(
            onPressed: onTap,
            label: tab.label,
            selected: selected,
            radius: _circular ? 10000 : Fluent2Radius.medium,
            builder: (context, states) {
              final press = states.press;
              final disabled = press == Fluent2Press.disabled;
              final f = _face(t, press);
              // The tab bar theme's colours over Fluent's, in the tab's
              // states: `fill`, `foreground` (words and glyph), `edge` (the
              // selected indicator, or a circular tab's rim).
              final look = Fluent2StyleOf([t.tabListTheme], states);
              final ink = look.foreground ?? f.ink;
              final fill = look.fill ?? f.fill;
              return fluent2EasedInks(
                [ink, fill, look.foreground ?? f.glyph, look.edge ?? f.stroke],
                (context, inks) {
                  final [ink, fill, glyphInk, edgeInk] = inks;
                  final icon = tab.icon == null
                      ? null
                      : Icon(
                          selected
                              ? (tab.selectedIcon ?? fluent2Filled(tab.icon!))
                              : fluent2FillOn(tab.icon!, states),
                          size: glyphSize,
                          color: glyphInk,
                        );
                  // The selected cut's width is kept by every state, so choosing
                  // a tab never moves its neighbours; the rest cut stands in the
                  // middle of it (Fluent's `contentReservedSpace`).
                  final words = Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Visibility(
                          visible: false,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Text(tab.label, maxLines: 1, style: strong),
                        ),
                        fluent2CapCentred(
                          Text(
                            tab.label,
                            maxLines: 1,
                            style: (selected ? strong : rest)
                                .merge(look.textStyle)
                                .c(ink),
                          ),
                        ),
                      ],
                    ),
                  );
                  final content = Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: gap,
                    children: [?icon, words],
                  );
                  final shape = BorderRadius.circular(
                    _circular ? 10000 : Fluent2Radius.medium,
                  );
                  Widget box = Container(
                    padding: room,
                    alignment: vertical
                        ? AlignmentDirectional.centerStart
                        : Alignment.center,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: shape,
                      border: _circular
                          ? Border.all(
                              color: edgeInk,
                              width: Fluent2Stroke.thin,
                            )
                          : null,
                    ),
                    child: content,
                  );
                  if (_circular) return box;
                  final bar = selected
                      ? look.edge ??
                            press.pick(
                              t.colors.compoundBrandStroke,
                              t.colors.compoundBrandStrokeHover,
                              t.colors.compoundBrandStrokePressed,
                              t.textDisabled,
                            )
                      : disabled
                      ? null
                      : press.pick(
                          t.colors.transparentStroke,
                          t.colors.neutralStroke1Hover,
                          t.colors.neutralStroke1Pressed,
                        );
                  if (bar == null) return box;
                  final thick = size == Fluent2TabSize.small
                      ? Fluent2Stroke.thick
                      : Fluent2Stroke.thicker;
                  Widget mark = DecoratedBox(
                    decoration: BoxDecoration(
                      color: bar,
                      borderRadius: BorderRadius.circular(10000),
                    ),
                  );
                  final s = slide;
                  if (s != null) {
                    mark = AnimatedBuilder(
                      animation: s,
                      builder: (context, child) {
                        final a = s.value;
                        final k = scale + (1 - scale) * a;
                        final d = from * (1 - a);
                        return Transform(
                          alignment: vertical
                              ? Alignment.topCenter
                              : Alignment.centerLeft,
                          transform: vertical
                              ? (Matrix4.translationValues(0, d, 0)
                                  ..scaleByDouble(1, k, 1, 1))
                              : (Matrix4.translationValues(d, 0, 0)
                                  ..scaleByDouble(k, 1, 1, 1)),
                          child: child,
                        );
                      },
                      child: mark,
                    );
                  }
                  final inset = switch (size) {
                    Fluent2TabSize.small => vertical ? 4.0 : 6.0,
                    Fluent2TabSize.medium => vertical ? 8.0 : 12.0,
                    Fluent2TabSize.large => vertical ? 10.0 : 12.0,
                  };
                  box = Stack(
                    clipBehavior: Clip.none,
                    children: [
                      box,
                      if (vertical)
                        PositionedDirectional(
                          start: 0,
                          top: inset,
                          bottom: inset,
                          width: thick,
                          child: mark,
                        )
                      else
                        Positioned(
                          left: inset,
                          right: inset,
                          bottom: 0,
                          height: thick,
                          child: mark,
                        ),
                    ],
                  );
                  return box;
                },
              );
            },
          ),
        ),
      ),
    );
  }

  _TabFace _face(Fluent2ThemeData t, Fluent2Press press) {
    final c = t.colors;
    final disabled = press == Fluent2Press.disabled;
    switch (appearance) {
      case Fluent2TabAppearance.transparent:
      case Fluent2TabAppearance.subtle:
        final subtle = appearance == Fluent2TabAppearance.subtle;
        final fill = disabled
            ? c.transparentBackground
            : subtle
            ? press.pick(
                c.subtleBackground,
                c.subtleBackgroundHover,
                c.subtleBackgroundPressed,
              )
            : press.pick(
                c.transparentBackground,
                c.transparentBackgroundHover,
                c.transparentBackgroundPressed,
              );
        if (disabled) {
          return _TabFace(
            fill,
            c.transparentStroke,
            c.neutralForegroundDisabled,
            c.neutralForegroundDisabled,
          );
        }
        if (selected) {
          return _TabFace(
            fill,
            c.transparentStroke,
            press.pick(
              c.neutralForeground1,
              c.neutralForeground1Hover,
              c.neutralForeground1Pressed,
            ),
            press.pick(
              c.compoundBrandForeground1,
              c.compoundBrandForeground1Hover,
              c.compoundBrandForeground1Pressed,
            ),
          );
        }
        final ink = press.pick(
          c.neutralForeground2,
          c.neutralForeground2Hover,
          c.neutralForeground2Pressed,
        );
        return _TabFace(fill, c.transparentStroke, ink, ink);
      case Fluent2TabAppearance.subtleCircular:
        if (disabled) {
          return selected
              ? _TabFace(
                  fluent2WellDisabled(t),
                  fluent2Step(t, c.neutralStrokeDisabled),
                  c.neutralForegroundDisabled,
                  c.neutralForegroundDisabled,
                )
              : _TabFace(
                  c.subtleBackground,
                  c.transparentStroke,
                  c.neutralForegroundDisabled,
                  c.neutralForegroundDisabled,
                );
        }
        if (selected) {
          final ink = press.pick(
            c.brandForeground2,
            c.brandForeground2Hover,
            c.brandForeground2Pressed,
          );
          return _TabFace(
            press.pick(
              c.brandBackground2,
              c.brandBackground2Hover,
              c.brandBackground2Pressed,
            ),
            press.pick(
              c.compoundBrandStroke,
              c.compoundBrandStrokeHover,
              c.compoundBrandStrokePressed,
            ),
            ink,
            ink,
          );
        }
        final ink = press.pick(
          c.neutralForeground2,
          c.neutralForeground2Hover,
          c.neutralForeground2Pressed,
        );
        return _TabFace(
          press.pick(
            c.subtleBackground,
            c.subtleBackgroundHover,
            c.subtleBackgroundPressed,
          ),
          press.pick(
            c.transparentStroke,
            c.neutralStroke1Hover,
            c.neutralStroke1Pressed,
          ),
          ink,
          ink,
        );
      case Fluent2TabAppearance.filledCircular:
        if (disabled) {
          return _TabFace(
            fluent2WellDisabled(t),
            selected
                ? fluent2Step(t, c.neutralStrokeDisabled)
                : c.transparentStroke,
            c.neutralForegroundDisabled,
            c.neutralForegroundDisabled,
          );
        }
        if (selected) {
          return _TabFace(
            press.pick(
              c.brandBackground,
              c.brandBackgroundHover,
              c.brandBackgroundPressed,
            ),
            c.transparentStroke,
            c.neutralForegroundOnBrand,
            c.neutralForegroundOnBrand,
          );
        }
        final ink = press.pick(
          c.neutralForeground2,
          c.neutralForeground2Hover,
          c.neutralForeground2Pressed,
        );
        // Fluent's neutralBackground3 step laid over the ground, so an
        // unchosen pill shows on the tinted page as on a card.
        return _TabFace(fluent2Well(t, press), c.transparentStroke, ink, ink);
    }
  }
}

@immutable
final class _TabFace {
  const _TabFace(this.fill, this.stroke, this.ink, this.glyph);

  final Color fill;
  final Color stroke;
  final Color ink;
  final Color glyph;
}
