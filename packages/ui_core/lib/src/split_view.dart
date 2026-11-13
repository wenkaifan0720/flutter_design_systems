/// A resizable split, headless: two panes and a divider between them that a
/// drag, the arrows (a [DesignValueHandle]) and a screen reader's slider
/// move, and Enter collapses the first pane and brings it back. Nest one
/// in another for three or more panes.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'localizations.dart';
import 'value_handle.dart';

/// Builds a split view's divider for its [states] (focused while the
/// keyboard is on it, hovered, pressed while dragged).
typedef DesignDividerBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  Axis axis,
);

/// [first] and [second] side by side (or stacked, [axis] vertical), split
/// at [fraction] of the room (the first pane's share).
///
/// ```dart
/// DesignSplitView(first: const SizedBox(), second: const SizedBox(), dividerBuilder: (context, states, axis) => const ColoredBox(color: Color(0xFFDDDDDD)))
/// ```
class DesignSplitView extends StatefulWidget {
  /// A split of [first] and [second].
  const DesignSplitView({
    super.key,
    required this.first,
    required this.second,
    required this.dividerBuilder,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = 0.5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.dividerThickness = 1,
    this.hitExtent = 12,
    this.step = 0.02,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// The first pane (the start side, or the top).
  final Widget first;

  /// The second pane.
  final Widget second;

  /// Paints the divider (its [dividerThickness] across the run).
  final DesignDividerBuilder dividerBuilder;

  /// Side by side ([Axis.horizontal]) or stacked.
  final Axis axis;

  /// The first pane's share, when the app holds it; null: the view holds
  /// it, from [initialFraction].
  final double? fraction;

  /// Where a view that holds its own share starts.
  final double initialFraction;

  /// A drag's, a key's or a screen reader's new share.
  final ValueChanged<double>? onChanged;

  /// The first pane's least size.
  final double minFirst;

  /// The second pane's least size.
  final double minSecond;

  /// The divider's thickness in the layout.
  final double dividerThickness;

  /// The divider's pointer target across the run (over both panes' edges).
  final double hitExtent;

  /// An arrow's change in share.
  final double step;

  /// What a screen reader calls the divider; null:
  /// [DesignLocalizations.splitViewHandleLabel].
  final String? semanticLabel;

  /// The divider's focus. The caller's, who disposes it; null: its own.
  final FocusNode? focusNode;

  /// Whether the divider takes focus when it first appears.
  final bool autofocus;

  @override
  State<DesignSplitView> createState() => _DesignSplitViewState();
}

class _DesignSplitViewState extends State<DesignSplitView> {
  late double _own = widget.initialFraction;
  double? _restore;
  bool _dragging = false;

  double get _fraction => widget.fraction ?? _own;

  void _set(double f) {
    if (widget.fraction == null) setState(() => _own = f);
    widget.onChanged?.call(f);
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    final rtl = horizontal && Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, box) {
        final total =
            (horizontal ? box.maxWidth : box.maxHeight) -
            widget.dividerThickness;
        final lo = total <= 0 ? 0.0 : (widget.minFirst / total).clamp(0.0, 1.0);
        final hi = total <= 0
            ? 1.0
            : (1 - widget.minSecond / total).clamp(lo, 1.0);
        final f = _fraction.clamp(lo, hi);
        final a = total * f;
        final d = widget.dividerThickness;
        final hit = widget.hitExtent < d ? d : widget.hitExtent;

        // Places a child along the run from [start] for [extent] (mirrored
        // right to left).
        Widget place(double start, double extent, Widget child) {
          final from = rtl ? total + d - start - extent : start;
          return horizontal
              ? Positioned(
                  left: from,
                  width: extent,
                  top: 0,
                  bottom: 0,
                  child: child,
                )
              : Positioned(
                  top: start,
                  height: extent,
                  left: 0,
                  right: 0,
                  child: child,
                );
        }

        void drag(DragUpdateDetails details) {
          if (total <= 0) return;
          var delta = details.primaryDelta ?? 0;
          if (rtl) delta = -delta;
          _set((_fraction.clamp(lo, hi) + delta / total).clamp(lo, hi));
        }

        final handle = DesignValueHandle(
          value: f,
          min: lo,
          max: hi,
          step: widget.step,
          axis: widget.axis,
          growsToward: VerticalDirection.down,
          dragging: _dragging,
          minimumSize: Size.zero,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          semanticLabel:
              widget.semanticLabel ??
              DesignLocalizations.of(context).splitViewHandleLabel,
          onChanged: (v) {
            _restore = null;
            _set(v);
          },
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent ||
                event.logicalKey != LogicalKeyboardKey.enter) {
              return KeyEventResult.ignored;
            }
            final back = _restore;
            if (back != null) {
              _restore = null;
              _set(back.clamp(lo, hi));
            } else if (f > lo) {
              _restore = f;
              _set(lo);
            }
            return KeyEventResult.handled;
          },
          builder: (context, states) => SizedBox.expand(
            child: Center(
              child: SizedBox(
                width: horizontal ? d : null,
                height: horizontal ? null : d,
                child: widget.dividerBuilder(context, states, widget.axis),
              ),
            ),
          ),
        );

        return Stack(
          children: [
            place(0, a, widget.first),
            place(a + d, total - a, widget.second),
            place(
              a + d / 2 - hit / 2,
              hit,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: horizontal
                    ? (_) => setState(() => _dragging = true)
                    : null,
                onHorizontalDragUpdate: horizontal ? drag : null,
                onHorizontalDragEnd: horizontal
                    ? (_) => setState(() => _dragging = false)
                    : null,
                onVerticalDragStart: horizontal
                    ? null
                    : (_) => setState(() => _dragging = true),
                onVerticalDragUpdate: horizontal ? null : drag,
                onVerticalDragEnd: horizontal
                    ? null
                    : (_) => setState(() => _dragging = false),
                child: handle,
              ),
            ),
          ],
        );
      },
    );
  }
}
