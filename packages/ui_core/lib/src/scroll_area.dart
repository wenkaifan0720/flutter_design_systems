/// A scroll area, headless: a scroll view with a scrollbar the look paints.
/// The thumb drags, a press on the track pages toward it, and the area is a
/// tab stop the arrows, Page Up and Down, Home and End scroll.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// When a [DesignScrollArea]'s scrollbar shows.
enum DesignScrollbarVisibility {
  /// While it scrolls, and while a pointer is over the scrollbar.
  auto,

  /// Always, while there is anything to scroll.
  always,

  /// Never (the area still scrolls by keyboard).
  never,
}

/// A scrollbar's geometry and state, for the look to paint.
@immutable
class DesignScrollThumb {
  /// The scrollbar's state; the area makes it.
  const DesignScrollThumb({
    required this.axis,
    required this.trackExtent,
    required this.thumbExtent,
    required this.thumbOffset,
    required this.visible,
    required this.states,
  });

  /// Which way it runs.
  final Axis axis;

  /// The track's length.
  final double trackExtent;

  /// The thumb's length.
  final double thumbExtent;

  /// The thumb's distance from the track's start.
  final double thumbOffset;

  /// Whether the look should show it (fade it out when false).
  final bool visible;

  /// [WidgetState.hovered] while a pointer is over it,
  /// [WidgetState.pressed] while the thumb is dragged.
  final Set<WidgetState> states;
}

/// Paints a scrollbar's thumb or track.
typedef DesignScrollbarBuilder = Widget Function(
  BuildContext context,
  DesignScrollThumb thumb,
);

/// [child], a scroll view on [controller], with a scrollbar from
/// [thumbBuilder] (and [trackBuilder]) on its end edge (or bottom).
///
/// ```dart
/// DesignScrollArea(controller: controller, thumbBuilder: (context, thumb) => const ColoredBox(color: Color(0x66000000)), child: SingleChildScrollView(controller: controller, child: const Text('Terms')))
/// ```
class DesignScrollArea extends StatefulWidget {
  /// A scroll area around [child], which scrolls on [controller].
  const DesignScrollArea({
    super.key,
    required this.controller,
    required this.thumbBuilder,
    required this.child,
    this.trackBuilder,
    this.axis = Axis.vertical,
    this.thickness = 12,
    this.minThumbLength = 24,
    this.visibility = DesignScrollbarVisibility.auto,
    this.timeToFade = const Duration(milliseconds: 1200),
    this.focusable = true,
    this.focusNode,
    this.autofocus = false,
    this.step = 48,
    this.semanticLabel,
    this.frameBuilder,
  });

  /// The controller [child] scrolls on: give [child] the same one. The
  /// caller makes it, keeps it across rebuilds and disposes it.
  final ScrollController controller;

  /// Paints the thumb.
  final DesignScrollbarBuilder thumbBuilder;

  /// Paints the track; null: none.
  final DesignScrollbarBuilder? trackBuilder;

  /// The scroll view.
  final Widget child;

  /// The scroll view's axis.
  final Axis axis;

  /// The scrollbar's breadth (its pointer target too).
  final double thickness;

  /// The thumb's least length.
  final double minThumbLength;

  /// When the scrollbar shows.
  final DesignScrollbarVisibility visibility;

  /// How long it stays after scrolling stops ([DesignScrollbarVisibility.auto]).
  final Duration timeToFade;

  /// Whether the area is a tab stop that scrolls by keyboard (on for a
  /// region with nothing focusable in it).
  final bool focusable;

  /// The area's focus. The caller's, who disposes it; null: the area's own.
  final FocusNode? focusNode;

  /// Whether the area takes focus when it first appears (with [focusable]).
  final bool autofocus;

  /// How far an arrow key scrolls.
  final double step;

  /// What a screen reader calls the area.
  final String? semanticLabel;

  /// Paints around the area, `focused` while the keyboard is on it (its
  /// focus ring); null: nothing.
  final Widget Function(BuildContext context, bool focused, Widget area)?
  frameBuilder;

  @override
  State<DesignScrollArea> createState() => _DesignScrollAreaState();
}

class _DesignScrollAreaState extends State<DesignScrollArea> {
  bool _scrolling = false;
  bool _hovered = false;
  bool _dragging = false;
  bool _focused = false;
  Timer? _hide;

  ScrollPosition? get _position =>
      widget.controller.hasClients ? widget.controller.position : null;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != widget.axis) return false;
    if (n is ScrollStartNotification || n is ScrollUpdateNotification) {
      _hide?.cancel();
      if (!_scrolling) setState(() => _scrolling = true);
    } else if (n is ScrollEndNotification) {
      _hide?.cancel();
      _hide = Timer(widget.timeToFade, () {
        if (mounted) setState(() => _scrolling = false);
      });
    }
    return false;
  }

  void _to(double pixels, {bool animate = true}) {
    final p = _position;
    if (p == null) return;
    final target = pixels.clamp(p.minScrollExtent, p.maxScrollExtent);
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      p.jumpTo(target);
    } else {
      p.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final p = _position;
    if (!node.hasPrimaryFocus || p == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final vertical = widget.axis == Axis.vertical;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final page = p.viewportDimension * 0.8;
    double? to;
    if (key == (vertical ? LogicalKeyboardKey.arrowDown : _next(rtl))) {
      to = p.pixels + widget.step;
    } else if (key == (vertical ? LogicalKeyboardKey.arrowUp : _back(rtl))) {
      to = p.pixels - widget.step;
    } else if (key == LogicalKeyboardKey.pageDown) {
      to = p.pixels + page;
    } else if (key == LogicalKeyboardKey.pageUp) {
      to = p.pixels - page;
    } else if (key == LogicalKeyboardKey.home) {
      to = p.minScrollExtent;
    } else if (key == LogicalKeyboardKey.end) {
      to = p.maxScrollExtent;
    }
    if (to == null) return KeyEventResult.ignored;
    _to(to, animate: event is KeyDownEvent);
    return KeyEventResult.handled;
  }

  static LogicalKeyboardKey _next(bool rtl) =>
      rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
  static LogicalKeyboardKey _back(bool rtl) =>
      rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;

  Widget _bar(BuildContext context, BoxConstraints box) {
    final p = _position;
    final vertical = widget.axis == Axis.vertical;
    final track = vertical ? box.maxHeight : box.maxWidth;
    if (p == null || !p.hasContentDimensions || p.maxScrollExtent <= 0) {
      return const SizedBox.shrink();
    }
    final content = p.maxScrollExtent - p.minScrollExtent + p.viewportDimension;
    final thumb = (track * p.viewportDimension / content).clamp(
      widget.minThumbLength.clamp(0.0, track),
      track,
    );
    final range = p.maxScrollExtent - p.minScrollExtent;
    final along = ((p.pixels - p.minScrollExtent) / range).clamp(0.0, 1.0);
    final offset = (track - thumb) * along;
    final visible = switch (widget.visibility) {
      DesignScrollbarVisibility.always => true,
      DesignScrollbarVisibility.never => false,
      DesignScrollbarVisibility.auto => _scrolling || _hovered || _dragging,
    };
    final info = DesignScrollThumb(
      axis: widget.axis,
      trackExtent: track,
      thumbExtent: thumb,
      thumbOffset: offset,
      visible: visible,
      states: {
        if (_hovered) WidgetState.hovered,
        if (_dragging) WidgetState.pressed,
      },
    );
    // Pointer pixels to scroll pixels while dragging the thumb.
    final ratio = track - thumb <= 0 ? 0.0 : range / (track - thumb);
    void drag(DragUpdateDetails d) {
      final delta = d.primaryDelta ?? 0;
      _to(p.pixels + delta * ratio, animate: false);
    }

    // The bar is the pointer's: the scroll view under it carries the scroll
    // actions and the area its name, so neither the thumb's drag nor the
    // track's page press adds a node of its own.
    final thumbBox = GestureDetector(
      excludeFromSemantics: true,
      onVerticalDragStart: vertical
          ? (_) => setState(() => _dragging = true)
          : null,
      onVerticalDragUpdate: vertical ? drag : null,
      onVerticalDragEnd: vertical
          ? (_) => setState(() => _dragging = false)
          : null,
      onHorizontalDragStart: vertical
          ? null
          : (_) => setState(() => _dragging = true),
      onHorizontalDragUpdate: vertical ? null : drag,
      onHorizontalDragEnd: vertical
          ? null
          : (_) => setState(() => _dragging = false),
      child: widget.thumbBuilder(context, info),
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapUp: (d) {
          final at = vertical ? d.localPosition.dy : d.localPosition.dx;
          final page = p.viewportDimension * 0.8;
          if (at < offset) _to(p.pixels - page);
          if (at > offset + thumb) _to(p.pixels + page);
        },
        child: Stack(
          children: [
            if (widget.trackBuilder != null)
              Positioned.fill(child: widget.trackBuilder!(context, info)),
            Positioned(
              top: vertical ? offset : 0,
              bottom: vertical ? track - offset - thumb : 0,
              left: vertical ? 0 : offset,
              right: vertical ? 0 : track - offset - thumb,
              child: thumbBox,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vertical = widget.axis == Axis.vertical;
    final bar = ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => LayoutBuilder(builder: _bar),
    );
    final area = Stack(
      children: [
        Positioned.fill(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (_) {
                setState(() {});
                return false;
              },
              child: widget.child,
            ),
          ),
        ),
        if (vertical)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: widget.thickness,
            child: bar,
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.thickness,
            child: bar,
          ),
      ],
    );
    return Semantics(
      container: widget.semanticLabel != null,
      label: widget.semanticLabel,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus && widget.focusable,
        canRequestFocus: widget.focusable,
        skipTraversal: !widget.focusable,
        // The named area says it is a tab stop, and when it has the focus.
        includeSemantics: widget.focusable,
        onKeyEvent: _key,
        onFocusChange: (on) => setState(
          () => _focused =
              on &&
              FocusManager.instance.highlightMode ==
                  FocusHighlightMode.traditional,
        ),
        child: Builder(
          builder: (context) =>
              widget.frameBuilder?.call(context, _focused, area) ?? area,
        ),
      ),
    );
  }
}
