/// A region that scrolls with a quiet scrollbar of its own, and two panes
/// with a divider that resizes them, painted on ui_core's scroll area and
/// split view.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';

/// A region of a page that scrolls on its own: a long list in a side
/// panel, release notes in a card, a wide table sideways. Its scrollbar is
/// Minimal's: a 6 px bar in the tertiary ink inside a 12 px track at the
/// end edge (or the bottom), the content kept 16 px off that edge so it
/// never runs up to the thumb, shown while it scrolls and while a pointer
/// rests on it, then faded; a dragged thumb darkens. The thumb drags, a
/// press on the gutter pages toward it, and the region is a tab stop the
/// arrows, Page Up and Down, Home and End scroll, a focus ring round it
/// while the keyboard is there.
///
/// [child] is the content; the area scrolls it on [controller] (its own
/// unstated). The behaviour is ui_core's ([DesignScrollArea]); Minimal
/// paints it. [shape] outlines the ring (and clips the content), else
/// `shapes.small`.
///
/// ```dart
/// MinimalScrollArea(height: 240, child: Column(children: notes))
/// ```
class MinimalScrollArea extends StatefulWidget {
  /// A scroll area around [child].
  const MinimalScrollArea({
    super.key,
    required this.child,
    this.controller,
    this.axis = Axis.vertical,
    this.height,
    this.width,
    this.alwaysShown = false,
    this.label,
    this.shape,
    this.padding = EdgeInsets.zero,
    this.focusNode,
    this.autofocus = false,
  });

  /// The content.
  final Widget child;

  /// The area's keyboard stop (the arrow and page keys scroll it).
  final FocusNode? focusNode;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The scroll position, when the caller holds it.
  final ScrollController? controller;

  /// Which way it scrolls.
  final Axis axis;

  /// Its height, for a vertical area in a page that scrolls itself.
  final double? height;

  /// Its width, for a sideways area in a row.
  final double? width;

  /// Show the scrollbar whenever there is anything to scroll.
  final bool alwaysShown;

  /// What a screen reader calls the region.
  final String? label;

  /// The outline of its focus ring and clip; `shapes.small` unstated.
  final OutlinedBorder? shape;

  /// Space round the content, inside the scrolling.
  final EdgeInsetsGeometry padding;

  @override
  State<MinimalScrollArea> createState() => _MinimalScrollAreaState();
}

class _MinimalScrollAreaState extends State<MinimalScrollArea> {
  ScrollController? _own;

  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final still = context.minimalStill;
    final shape = widget.shape ?? t.shapes.small;
    final vertical = widget.axis == Axis.vertical;
    final area = DesignScrollArea(
      controller: _controller,
      axis: widget.axis,
      thickness: 12,
      visibility: widget.alwaysShown
          ? DesignScrollbarVisibility.always
          : DesignScrollbarVisibility.auto,
      semanticLabel: widget.label,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      thumbBuilder: (context, thumb) {
        final held = thumb.states.contains(WidgetState.pressed);
        return AnimatedOpacity(
          opacity: thumb.visible ? 1 : 0,
          duration: still ? Duration.zero : MinimalMotion.base,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: (held ? t.mutedForeground : t.textTertiary).withValues(
                  alpha: held ? 0.7 : 0.5,
                ),
              ),
            ),
          ),
        );
      },
      frameBuilder: (context, focused, area) => Container(
        foregroundDecoration: minimalStateLayer(t, shape, {
          if (focused) WidgetState.focused,
        }, inside: true),
        child: minimalClip(shape, child: area),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: widget.axis,
          // The bar's gutter: the content stands clear of the thumb, as far
          // off it as the thumb stands off the edge and more.
          padding: widget.padding.add(
            vertical
                ? const EdgeInsetsDirectional.only(end: _barGutter)
                : const EdgeInsets.only(bottom: _barGutter),
          ),
          child: widget.child,
        ),
      ),
    );
    return SizedBox(width: widget.width, height: widget.height, child: area);
  }
}

/// How far a scroll area's content stands off the edge its bar is on: the
/// 12 px track, and 4 more of air between the thumb and the words.
const double _barGutter = 16;

/// Two panes and a divider that resizes them: a list beside its detail, an
/// editor over its output. The divider is a hairline (the focus colour at
/// `t.focusWidth` while the keyboard is on it, the firm hairline while it
/// is dragged); with [handle], a small grip stands on its middle. Its
/// target is 12 px across, over both panes' edges.
///
/// A drag moves it, the arrows step it (and a screen reader hears a slider
/// of the first pane's share), Enter collapses the first pane and brings it
/// back; the panes keep [minFirst] and [minSecond]. Nest one in another for
/// three panes. The behaviour is ui_core's ([DesignSplitView]); Minimal
/// paints it.
///
/// ```dart
/// MinimalResizable(first: list, second: detail, initialFraction: 0.35, minFirst: 220, minSecond: 320)
/// ```
class MinimalResizable extends StatelessWidget {
  /// A split of [first] and [second].
  const MinimalResizable({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.handle = false,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// The divider's keyboard stop (the arrows move it).
  final FocusNode? focusNode;

  /// Whether the divider takes focus when it first shows.
  final bool autofocus;

  /// The first pane (the start side, or the top).
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Side by side ([Axis.horizontal]) or stacked.
  final Axis axis;

  /// The first pane's share, when the app holds it.
  final double? fraction;

  /// Where a split that holds its own share starts.
  final double initialFraction;

  /// A drag's, a key's or a screen reader's new share.
  final ValueChanged<double>? onChanged;

  /// The first pane's least size.
  final double minFirst;

  /// The second pane's least size.
  final double minSecond;

  /// Whether a grip stands on the divider's middle.
  final bool handle;

  /// What a screen reader calls the divider; Resize unstated.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final across = axis == Axis.horizontal;
    return DesignSplitView(
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      dividerThickness: t.hairline,
      focusNode: focusNode,
      autofocus: autofocus,
      semanticLabel: label ?? MinimalLocalizations.of(context).resize,
      dividerBuilder: (context, states, axis) {
        final ring = states.ring;
        final held = states.contains(WidgetState.pressed);
        final line = ring
            ? t.ring
            : held
            ? t.borderStrong
            : t.border;
        final weight = ring ? t.focusWidth : t.hairline;
        // A share of the run lands the divider between pixels; it is drawn
        // on the nearest one, as crisp and as light as the frame's hairline.
        return _Snap(
          ratio: MediaQuery.devicePixelRatioOf(context),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                left: across ? -(weight - t.hairline) / 2 : 0,
                right: across ? -(weight - t.hairline) / 2 : 0,
                top: across ? 0 : -(weight - t.hairline) / 2,
                bottom: across ? 0 : -(weight - t.hairline) / 2,
                child: ColoredBox(color: line),
              ),
              if (handle)
                OverflowBox(
                  maxWidth: across ? 12 : 24,
                  maxHeight: across ? 24 : 12,
                  child: Container(
                    width: across ? 12 : 24,
                    height: across ? 24 : 12,
                    decoration: minimalFrame(
                      t.shapes.mark,
                      fill: t.card,
                      side: BorderSide(color: line, width: t.rim),
                    ),
                    child: MinimalIcon(
                      across
                          ? LucideIcons.gripVertical
                          : LucideIcons.gripHorizontal,
                      size: 10,
                      color: t.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Paints [child] moved to the nearest device pixel, so a hairline placed at
/// a fraction of a pixel draws as one sharp line rather than two faint ones.
class _Snap extends SingleChildRenderObjectWidget {
  const _Snap({required this.ratio, super.child});

  /// Device pixels per logical pixel.
  final double ratio;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSnap(ratio);

  @override
  void updateRenderObject(BuildContext context, _RenderSnap renderObject) {
    renderObject.ratio = ratio;
  }
}

class _RenderSnap extends RenderProxyBox {
  _RenderSnap(this._ratio);

  double _ratio;
  set ratio(double value) {
    if (value == _ratio) return;
    _ratio = value;
    markNeedsPaint();
  }

  double _snap(double v) =>
      _ratio <= 0 ? v : (v * _ratio).roundToDouble() / _ratio;

  @override
  void paint(PaintingContext context, Offset offset) =>
      super.paint(context, Offset(_snap(offset.dx), _snap(offset.dy)));
}
