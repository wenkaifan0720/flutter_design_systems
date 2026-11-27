import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/edge_fade.dart';
import '../internal/face.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../theme.dart';

/// In-page section tabs — Overview · Activity · Notes on a detail page: a
/// 44 px strip over the page's hairline, 13 px medium labels (the current
/// one in the ink, the rest quiet) with an optional mono count beside each,
/// and a 2 px ink underline under the current tab. A strip wider than the
/// screen scrolls sideways.
///
/// The strip is ONE focus stop, on the current tab: focused, it wears the
/// 2 px focus ring and the arrow keys move the choice to the neighbour
/// (round from the last to the first, Home and End to the ends), scrolling
/// it into view — focus and choice never part, so a following Enter or
/// Space changes nothing. A screen reader meets a tab bar of tabs, each
/// selected or not and its place ("Tab 2 of 3"), its count with its name.
/// The behaviour is ui_core's ([RawTabBar]); Minimal paints it, and
/// keeps its own scroll, its faded ends and the room its ring takes past
/// the strip's ends. [padding] insets the
/// labels (pass `MinimalInsets.gutter` on a full-bleed page: the first
/// label's glyphs sit exactly on the gutter) while the hairline runs edge
/// to edge. A null [onChanged] disables the strip.
///
/// With a [controller] (ui_core's `RawTabController`, as Flutter's `TabBar`
/// takes a `TabController`) the strip and a `RawTabBarView` of the tabs'
/// panels share one choice: a tap, an arrow or a swipe of the panels moves
/// both, and a screen reader hears each tab control its panel. Without one,
/// [selectedIndex] and [onChanged] hold the choice.
///
/// ```dart
/// MinimalTabBar(tabs: ['Overview', 'Activity', 'Notes'], counts: [null, 12, 3], selectedIndex: tab, onChanged: go)
/// ```
class MinimalTabBar extends StatefulWidget {
  /// A strip of [tabs].
  const MinimalTabBar({
    super.key,
    required this.tabs,
    this.selectedIndex,
    this.onChanged,
    this.controller,
    this.icons,
    this.counts,
    this.padding = EdgeInsets.zero,
  }) : assert(
         controller != null || selectedIndex != null,
         'a tab bar takes a controller or a selectedIndex',
       );

  /// The tabs' names.
  final List<String> tabs;

  /// The current tab, when no [controller] holds it.
  final int? selectedIndex;

  /// Called with the tab chosen. Without a [controller], null disables the
  /// strip.
  final ValueChanged<int>? onChanged;

  /// The choice the strip shares with a `RawTabBarView` of the panels; the
  /// caller's, who disposes it.
  ///
  /// ```dart
  /// MinimalTabBar(tabs: const ['Overview', 'Activity'], controller: tabs)
  /// ```
  final RawTabController? controller;

  /// One glyph per tab (null for a tab without one), before its name.
  final List<IconData?>? icons;

  /// One count per tab (null for a tab without one), printed in mono after
  /// its label.
  final List<int?>? counts;

  /// The strip's inset for its labels; the hairline under them ignores it.
  final EdgeInsetsGeometry padding;

  @override
  State<MinimalTabBar> createState() => _MinimalTabBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('tabs', tabs))
      ..add(IntProperty('selectedIndex', selectedIndex, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<RawTabController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(IterableProperty<IconData?>('icons', icons, defaultValue: null))
      ..add(IterableProperty<int?>('counts', counts, defaultValue: null))
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'padding',
          padding,
          defaultValue: EdgeInsets.zero,
        ),
      );
  }
}

const double _underline = 2;

/// How far a tab's press wash and focus ring stand past its words.
const double _halo = MinimalSpacing.s8;

class _MinimalTabBarState extends State<MinimalTabBar>
    with TickerProviderStateMixin {
  // The strip's own choice, when the caller holds no controller.
  RawTabController? _own;
  late RawTabController _controller;
  late int _shown;
  List<GlobalKey> _keys = const [];

  @override
  void initState() {
    super.initState();
    _controller = _take();
    _shown = _controller.index;
  }

  RawTabController _take() =>
      (widget.controller ?? (_own = _make()))..addListener(_chosen);

  RawTabController _make() => RawTabController(
    length: widget.tabs.length,
    initialIndex: widget.selectedIndex ?? 0,
    vsync: this,
  );

  List<GlobalKey> _keysFor(int n) {
    if (_keys.length != n) _keys = [for (var i = 0; i < n; i++) GlobalKey()];
    return _keys;
  }

  @override
  void didUpdateWidget(MinimalTabBar old) {
    super.didUpdateWidget(old);
    final caller = widget.controller;
    if (caller != old.controller ||
        (caller == null && widget.tabs.length != _controller.length)) {
      _controller.removeListener(_chosen);
      final gone = _own;
      _own = null;
      _controller = _take();
      _shown = _controller.index;
      if (gone != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => gone.dispose());
      }
    } else if (caller == null) {
      final index = widget.selectedIndex!;
      if (_controller.index != index) _controller.index = index;
    }
  }

  // A choice made off screen (a key press, a parent, a swipe of the
  // panels) scrolls into view.
  void _reveal(int index, {required bool forward}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _keys.length) return;
      final tab = _keys[index].currentContext;
      if (tab == null) return;
      final instant = tab.minimalStill;
      Scrollable.ensureVisible(
        tab,
        duration: instant ? Duration.zero : MinimalMotion.base,
        curve: MinimalMotion.out,
        alignmentPolicy: forward
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_chosen);
    _own?.dispose();
    super.dispose();
  }

  // The choice moved (a tap, an arrow, the panels, the parent): the strip
  // shows it and scrolls to it, and the page hears a choice it didn't make.
  // Without a controller, a page that keeps its own choice puts the bar
  // back.
  void _chosen() {
    final i = _controller.index;
    if (i == _shown) return;
    final forward = i > _shown;
    setState(() => _shown = i);
    _reveal(i, forward: forward);
    final onChanged = widget.onChanged;
    final kept = widget.selectedIndex;
    if (widget.controller == null && i == kept) return;
    if (onChanged != null) {
      RawHaptics.of(context).selectionChanged?.call();
      onChanged(i);
    }
    if (widget.controller != null || kept == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kept = widget.selectedIndex;
      if (mounted && kept != null && _controller.index != kept) {
        _controller.index = kept;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    final counts = widget.counts;
    final icons = widget.icons;
    final index = _controller.index;
    assert(counts == null || counts.length == tabs.length, 'a count per tab');
    assert(icons == null || icons.length == tabs.length, 'a glyph per tab');
    assert(index >= 0 && index < tabs.length, 'index out of range');
    final t = context.minimalTheme;
    final enabled = widget.controller != null || widget.onChanged != null;
    final instant = context.minimalStill;
    final keys = _keysFor(tabs.length);
    final current = _controller.index;

    Widget tab(RawTab design, RawTabDetails details) {
      final i = details.index;
      final selected = i == current;
      final count = counts?[i];
      final states = details.states;
      Widget face = SizedBox(
        height: MinimalChromeMetrics.row,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The press wash covers the tab's whole tap target and [_halo]
            // past it, so the cell a tap reaches is the cell that shows it.
            Positioned.fill(
              child: IgnorePointer(
                child: _TargetWash(
                  color: states.down
                      ? minimalPressInk(t).withValues(alpha: 0.08)
                      : null,
                  shape: t.shapes.mark,
                ),
              ),
            ),
            // The focus ring stands [_halo] past the words on either side,
            // so it never hugs a glyph; the tab's width, and so the strip's
            // layout, stay the words'.
            Positioned(
              left: -_halo,
              right: -_halo,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: minimalFrame(
                    t.shapes.mark,
                    side: states.ring
                        ? BorderSide(
                            color: t.ring,
                            width: t.focusWidth,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            // The label and count ARE the tab's width, so the first label's
            // glyphs start exactly at the strip's inset.
            Center(
              widthFactor: 1,
              // The label and its count each by their capitals, on the
              // tab's middle.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icons?[i] case final glyph?) ...[
                    MinimalFace(
                      ink: selected ? t.foreground : t.mutedForeground,
                      builder: (context, ink) => Icon(
                        glyph,
                        size: MediaQuery.textScalerOf(context).scale(16),
                        color: ink ?? t.mutedForeground,
                      ),
                    ),
                    const MinimalGap(MinimalSpacing.s8),
                  ],
                  // The label's ink lerps as the tab is chosen.
                  MinimalFace(
                    ink: selected ? t.foreground : t.mutedForeground,
                    builder: (context, ink) => minimalCapLabel(
                      Text(
                        tabs[i],
                        style: t.bodySmall.medium.c(ink ?? t.mutedForeground),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  if (count != null) ...[
                    const MinimalGap(MinimalControlMetrics.countGap),
                    minimalCapLabel(
                      Text(
                        '$count',
                        style: t.countFigure.c(t.mutedForeground),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: instant ? Duration.zero : MinimalMotion.fast,
                curve: MinimalMotion.out,
                height: _underline,
                decoration: BoxDecoration(
                  color: selected
                      ? t.foreground
                      : t.foreground.withValues(alpha: 0),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_underline / 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      // The first tab's words start on the strip's inset, its target
      // reaching on past them.
      face = TapTargetPadding(
        alignment: i == 0
            ? AlignmentDirectional.centerStart
            : AlignmentDirectional.center,
        child: face,
      );
      // The gutter between two tabs, half on each.
      face = Padding(
        padding: EdgeInsetsDirectional.only(
          start: i == 0 ? 0 : MinimalChromeMetrics.gutter / 2,
          end: i == tabs.length - 1 ? 0 : MinimalChromeMetrics.gutter / 2,
        ),
        child: KeyedSubtree(key: keys[i], child: face),
      );
      return AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: instant ? Duration.zero : MinimalMotion.fast,
        child: face,
      );
    }

    // The page's rule paints first, so the current tab's underline lies
    // over it rather than under it.
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      // The strip, and so its hairline, takes the width it is given (its
      // labels' alone where the width is unbounded).
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        heightFactor: 1,
        // Scrolled labels stop at the strip's ends (the fade cuts a faded
        // end); the halo and the focus ring, which stand past a tab's words,
        // keep their room at an unfaded end and above and below.
        child: ClipRect(
          clipper: const _StripClip(),
          child: MinimalEdgeFade(
            reach: _reach,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: widget.padding,
              clipBehavior: Clip.none,
              // The tabs keep their own widths: in the scroll's unbounded
              // width, ui_core's bar shares none out.
              child: RawTabBar(
                controller: _controller,
                tabs: [
                  for (var i = 0; i < tabs.length; i++)
                    RawTab(
                      // A count is heard with its name, as it is seen.
                      label: counts?[i] == null
                          ? tabs[i]
                          : '${tabs[i]}\n${counts![i]}',
                      enabled: enabled,
                    ),
                ],
                tabBuilder: (context, design, details) => tab(design, details),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How far past the strip's ends a tab's halo and its ring reach.
const double _reach = _halo + MinimalChromeMetrics.focusRing;

/// The strip's scroll clip: its own width, give or take a tab's halo and
/// the focus ring round it, and generous room above and below for the ring.
class _StripClip extends CustomClipper<Rect> {
  const _StripClip();

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -_reach,
    -MinimalChromeMetrics.gutter,
    size.width + _reach,
    size.height + MinimalChromeMetrics.gutter,
  );

  @override
  bool shouldReclip(_StripClip oldClipper) => false;
}

/// A tab's press wash: over the tap target the tab stands in, [_halo] past
/// it at either side, as tall as the tab.
class _TargetWash extends LeafRenderObjectWidget {
  const _TargetWash({required this.color, required this.shape});

  final Color? color;
  final ShapeBorder shape;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTargetWash(color, shape);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTargetWash)
        ..color = color
        ..shape = shape;
}

class _RenderTargetWash extends RenderBox {
  _RenderTargetWash(this._color, this._shape);

  Color? _color;
  set color(Color? v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  ShapeBorder _shape;
  set shape(ShapeBorder v) {
    if (v == _shape) return;
    _shape = v;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final color = _color;
    if (color == null || color.a == 0) return;
    var rect = Rect.fromLTRB(-_halo, 0, size.width + _halo, size.height);
    RenderObject? up = parent;
    while (up != null && up is! RenderTapTargetPadding) {
      up = up.parent;
    }
    if (up is RenderTapTargetPadding && up.hasSize) {
      final back = Matrix4.tryInvert(getTransformTo(up));
      if (back != null) {
        final target = MatrixUtils.transformRect(back, Offset.zero & up.size);
        rect = Rect.fromLTRB(
          target.left - _halo,
          0,
          target.right + _halo,
          size.height,
        );
      }
    }
    context.canvas.drawPath(
      _shape.getOuterPath(rect.shift(offset)),
      Paint()..color = color,
    );
  }
}
