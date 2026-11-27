import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/cap_label.dart';
import '../../internal/icon_fill.dart';
import '../../internal/key_focus.dart';
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
/// from the tab chosen before on a spring that settles in `durationSlow`
/// (critically damped under Reduce Motion), or in the circular appearances
/// its pill. A row longer than its room scrolls, keeping the selected and
/// the focused tab in view. A row of transparent or subtle tabs hangs its
/// first tab's inset (its padding round the words) toward the start, so the
/// first word and its indicator start where a title and a field in the same
/// column start; a pill's edge stays on the column's. A tab press, or the
/// arrows along the row (one tab stop; mirrored right to left, Home and End
/// to the ends, tabs out of use skipped), asks [onChanged] for its index;
/// null draws the list disabled. [Fluent2TabList.items] takes tabs with
/// glyphs, or one out of use. Read as a tab bar of tabs, "Files, Tab 2 of
/// 3". It is ui_core's `RawTabBar` in Fluent's faces.
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
    this.semanticLabel,
    this.style,
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
    this.semanticLabel,
    this.style,
  }) : tabs = null;

  /// This tab list's own look, slot by slot, over its component theme
  /// ([Fluent2ThemeData.tabListTheme]): the slots its doc names.
  final Fluent2Style? style;

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
  final String? semanticLabel;

  List<Fluent2Tab> get _all =>
      items ?? [for (final word in tabs!) Fluent2Tab(word)];

  int get _count => items?.length ?? tabs!.length;

  @override
  State<Fluent2TabList> createState() => _Fluent2TabListState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
      )
      ..add(IterableProperty<String>('tabs', tabs, defaultValue: null))
      ..add(IterableProperty<Fluent2Tab>('items', items, defaultValue: null))
      ..add(IntProperty('selectedIndex', selectedIndex))
      ..add(ObjectFlagProperty<ValueChanged<int>?>.has('onChanged', onChanged))
      ..add(
        EnumProperty<Fluent2TabAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2TabAppearance.transparent,
        ),
      )
      ..add(
        EnumProperty<Fluent2TabSize>(
          'size',
          size,
          defaultValue: Fluent2TabSize.medium,
        ),
      )
      ..add(FlagProperty('vertical', value: vertical, ifTrue: 'vertical'))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null));
  }
}

class _Fluent2TabListState extends State<Fluent2TabList>
    with TickerProviderStateMixin {
  RawTabController? _tabs;

  // The indicator's slide: Fluent's `durationSlow` (300 ms) on ui_core's
  // spring, ω = 6 / 0.3 s.
  static const double _stiffness = 400;

  bool get _circular =>
      widget.appearance == Fluent2TabAppearance.subtleCircular ||
      widget.appearance == Fluent2TabAppearance.filledCircular;

  int get _at =>
      widget._count == 0 ? 0 : widget.selectedIndex.clamp(0, widget._count - 1);

  RawTabController? _controllerFor(int count) {
    if (count == 0) return null;
    return RawTabController(
      length: count,
      initialIndex: _at,
      vsync: this,
      dampingRatio: Fluent2Motion.springDamping,
      stiffness: _stiffness,
    )..addListener(_picked);
  }

  @override
  void initState() {
    super.initState();
    _tabs = _controllerFor(widget._count);
  }

  @override
  void didUpdateWidget(Fluent2TabList old) {
    super.didUpdateWidget(old);
    if (old._count != widget._count) {
      _tabs?.dispose();
      _tabs = _controllerFor(widget._count);
      return;
    }
    final tabs = _tabs;
    if (tabs != null && tabs.index != _at) tabs.animateTo(_at);
  }

  // A tab the bar chose (a press, the arrows): asked of [onChanged]; the
  // list shows what [selectedIndex] then says.
  void _picked() {
    final tabs = _tabs!;
    if (tabs.index == _at) return;
    widget.onChanged?.call(tabs.index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(tabs, _tabs) && tabs.index != _at) {
        tabs.index = _at;
      }
    });
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    if (tabs == null) return const SizedBox.shrink();
    final circular = _circular;
    final gap = !circular
        ? 0.0
        : widget.size == Fluent2TabSize.small
        ? Fluent2Spacing.sNudge
        : Fluent2Spacing.s;
    final live = widget.onChanged != null;
    final all = widget._all;
    final t = context.fluent2Theme;
    final thick = widget.size == Fluent2TabSize.small
        ? Fluent2Stroke.thick
        : Fluent2Stroke.thicker;
    final inset = switch (widget.size) {
      Fluent2TabSize.small => widget.vertical ? 4.0 : 6.0,
      Fluent2TabSize.medium => widget.vertical ? 8.0 : 12.0,
      Fluent2TabSize.large => widget.vertical ? 10.0 : 12.0,
    };
    final look = Fluent2StyleOf(
      [widget.style, t.tabListTheme],
      {
        WidgetState.selected,
        if (!live || !all[_at].enabled) WidgetState.disabled,
      },
    );
    // The strip never scrolls itself: Fluent's row scrolls round it (below),
    // so its tabs keep their own widths and the row its keyline outline. The
    // indicator stands over the tabs, as Fluent's does, so a focused tab's
    // ring never covers it.
    final bar = RawTabBar(
      controller: tabs,
      indicatorPosition: DecorationPosition.foreground,
      direction: widget.vertical ? Axis.vertical : Axis.horizontal,
      semanticLabel: widget.semanticLabel,
      tabs: [
        for (final tab in all)
          RawTab(
            label: tab.label,
            icon: tab.icon,
            enabled: live && tab.enabled,
          ),
      ],
      tabBuilder: (context, tab, details) {
        final face = _Reveal(
          selected: details.states.contains(WidgetState.selected),
          focused: details.states.contains(WidgetState.focused),
          child: _Tab(
            tab: all[details.index],
            states: details.states,
            appearance: widget.appearance,
            size: widget.size,
            vertical: widget.vertical,
            style: widget.style,
          ),
        );
        // Circular tabs stand [gap] apart.
        return gap == 0 || details.index == details.count - 1
            ? face
            : Padding(
                padding: widget.vertical
                    ? EdgeInsets.only(bottom: gap)
                    : EdgeInsetsDirectional.only(end: gap),
                child: face,
              );
      },
      // The 3 brand indicator under the selected tab's words (at its start
      // in a column), sliding on the spring from the tab chosen before; the
      // circular tabs fill their pill instead.
      indicatorBuilder: circular
          ? null
          : (context, details) {
              final states = details.states;
              // In the chosen tab's hover and press inks, as its words.
              final mark = DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      look.edge ??
                      (!live || !all[_at].enabled
                          ? t.textDisabled
                          : states.contains(WidgetState.pressed)
                          ? t.colors.compoundBrandStrokePressed
                          : states.contains(WidgetState.hovered)
                          ? t.colors.compoundBrandStrokeHover
                          : t.colors.compoundBrandStroke),
                  borderRadius: BorderRadius.circular(10000),
                ),
              );
              // ui_core lays the indicator out in the chosen tab's face.
              return widget.vertical
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: inset),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: SizedBox(
                          width: thick,
                          height: double.infinity,
                          child: mark,
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal: inset),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: thick,
                          width: double.infinity,
                          child: mark,
                        ),
                      ),
                    );
            },
    );
    if (widget.vertical) {
      // A column of tabs takes the room's width, as a stretched column.
      return LayoutBuilder(
        builder: (context, box) => box.hasBoundedWidth
            ? SizedBox(width: box.maxWidth, child: bar)
            : bar,
      );
    }
    // The first tab's inset: its padding at the side, and the words' 2 when
    // it shows no glyph (a glyph's box starts at the padding).
    final side = widget.size == Fluent2TabSize.small ? 6.0 : 10.0;
    final hang = circular || widget._count == 0
        ? 0.0
        : side + (all.first.icon == null ? 2 : 0);
    // A row of tabs keeps every name whole: as the reader's text grows the
    // names grow only while the row fits its room (never under their own
    // size); a row too long for its room at its own size scrolls, at the
    // reader's size, the chosen and the focused tab kept in view.
    final strip = LayoutBuilder(
      builder: (context, box) {
        // The room the hang already widened.
        final fit = _fitScale(context, box.maxWidth, gap, side);
        final size =
            (widget.size == Fluent2TabSize.large ? t.subtitle2 : t.body1Strong)
                .fontSize ??
            14;
        final reader = MediaQuery.textScalerOf(context).scale(size) / size;
        final capped = fit > 1 && fit < reader;
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: fit,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: _OutlineFromKeyline(
              by: hang,
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
    // A row too long for its room at its own size scrolls whatever the
    // size, so it takes the reader's.
    if (fits < 1) return reader;
    return math.min(reader, fits);
  }
}

/// Scrolls [child], a tab, into view in a row that scrolls: centred as it
/// is chosen ([selected] turns true), as the old row did, and the least way
/// as the keys reach it ([focused] turns true), over Fluent's
/// `durationNormal` (a cut under Reduce Motion).
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.selected,
    required this.focused,
    required this.child,
  });

  final bool selected;
  final bool focused;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  void _show({double? centre}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final duration = Fluent2Motion.on(context)
          ? Fluent2Motion.normal
          : Duration.zero;
      if (centre != null) {
        Scrollable.ensureVisible(
          context,
          alignment: centre,
          duration: duration,
          curve: Fluent2Motion.decelerateMid,
        );
        return;
      }
      for (final policy in const [
        ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ]) {
        Scrollable.ensureVisible(
          context,
          duration: duration,
          curve: Fluent2Motion.decelerateMid,
          alignmentPolicy: policy,
        );
      }
    });
  }

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _show(centre: 0.5);
    } else if (widget.focused && !old.focused) {
      _show();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Lays [child] out [by] wider than the room it is given and moves it [by]
/// toward the start, so its first words start on the room's start while its
/// end keeps the room's end. Paint and hits move together (the hung part
/// answers as far as the room round the strip reaches).
/// Clips what a screen reader outlines to start [by] in from the row's
/// start: the first tab's inset hangs over the page's margin, where a tap
/// may not reach, so its node starts on the keyline with the words, as far
/// as a tap always reaches. Paint and hits are untouched.
class _OutlineFromKeyline extends SingleChildRenderObjectWidget {
  const _OutlineFromKeyline({required this.by, required super.child});

  final double by;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOutlineFromKeyline(by, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOutlineFromKeyline renderObject,
  ) {
    renderObject
      ..by = by
      ..direction = Directionality.of(context);
  }
}

class _RenderOutlineFromKeyline extends RenderProxyBox {
  _RenderOutlineFromKeyline(this._by, this._direction);

  double _by;
  set by(double value) {
    if (value == _by) return;
    _by = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsSemanticsUpdate();
  }

  @override
  Rect? describeSemanticsClip(RenderObject? child) => _by == 0
      ? null
      : _direction == TextDirection.rtl
      ? Rect.fromLTRB(0, 0, math.max(0, size.width - _by), size.height)
      : Rect.fromLTRB(math.min(_by, size.width), 0, size.width, size.height);
}

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
    required this.states,
    required this.appearance,
    required this.size,
    required this.vertical,
    required this.style,
  });

  final Fluent2Tab tab;

  /// ui_core's tab states: selected, hovered, pressed, focused, disabled.
  final Set<WidgetState> states;
  final Fluent2TabAppearance appearance;
  final Fluent2TabSize size;
  final bool vertical;
  final Fluent2Style? style;

  bool get selected => states.contains(WidgetState.selected);

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
      (Fluent2TabSize.small, false) => const EdgeInsets.all(
        Fluent2Spacing.sNudge,
      ),
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
    // ui_core's bar presses the tab, moves the keys and names it to a screen
    // reader; the face paints its states and Fluent's focus ring.
    return TapTargetPadding(
      minSize: Fluent2Layout.tapFloorOf(context),
      child: Fluent2KeyRing(
        focused: states.contains(WidgetState.focused),
        radius: _circular ? 10000 : Fluent2Radius.medium,
        child: Builder(
          builder: (context) {
            final press = states.press;
            final disabled = press == Fluent2Press.disabled;
            final f = _face(t, press);
            // The tab bar theme's colours over Fluent's, in the tab's
            // states: `fill`, `foreground` (words and glyph), `edge` (the
            // selected indicator, or a circular tab's rim).
            final look = Fluent2StyleOf([style, t.tabListTheme], states);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: Fluent2Spacing.xxs,
                  ),
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
                        ? Border.all(color: edgeInk, width: Fluent2Stroke.thin)
                        : null,
                  ),
                  child: content,
                );
                if (_circular || selected) return box;
                // The selected tab's bar is ui_core's indicator; an
                // unchosen tab shows a bar under the pointer.
                final bar = disabled
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
                final mark = DecoratedBox(
                  decoration: BoxDecoration(
                    color: bar,
                    borderRadius: BorderRadius.circular(10000),
                  ),
                );
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
                fluent2Step(t, c.subtleBackgroundHover),
                fluent2Step(t, c.subtleBackgroundPressed),
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
            fluent2Step(t, c.subtleBackgroundHover),
            fluent2Step(t, c.subtleBackgroundPressed),
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
