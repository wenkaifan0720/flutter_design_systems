/// A value handle, headless: the focusable thumb of a slider, a range
/// slider, a split view's divider or a colour picker's channel. It holds the
/// keys (arrows by [DesignValueHandle.step], Page Up and Down by
/// [DesignValueHandle.pageStep], Home and End to the ends), the screen
/// reader's slider (its value, increase and decrease) and the face's states;
/// its parent turns pointer drags into values, since only it knows the
/// track.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Builds a handle's face for its [states] (focused while the keyboard is
/// on it, hovered, pressed while dragged, disabled).
typedef DesignHandleBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// A focusable value between [min] and [max].
///
/// Along a horizontal [axis], Right and Up raise the value (Left in right
/// to left). Along a vertical one, the arrow toward [growsToward] raises it.
///
/// ```dart
/// DesignValueHandle(value: 0.5, onChanged: (value) {}, semanticLabel: 'Volume', builder: (context, states) => const SizedBox(width: 20, height: 20))
/// ```
class DesignValueHandle extends StatefulWidget {
  /// A handle at [value].
  const DesignValueHandle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.builder,
    this.min = 0,
    this.max = 1,
    this.step,
    this.pageStep,
    this.divisions,
    this.axis = Axis.horizontal,
    this.growsToward = VerticalDirection.up,
    this.onChangeStart,
    this.onChangeEnd,
    this.dragging = false,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.minimumSize = const Size(44, 44),
    this.onKeyEvent,
  });

  /// The value.
  final double value;

  /// A key's or a screen reader's new value; null disables the handle.
  final ValueChanged<double>? onChanged;

  /// Paints the handle.
  final DesignHandleBuilder builder;

  /// The least value.
  final double min;

  /// The greatest value.
  final double max;

  /// An arrow's change; null: a division, else a hundredth of the range.
  final double? step;

  /// A page key's change; null: a tenth of the range (at least a [step]).
  final double? pageStep;

  /// How many steps the range snaps to; null: none.
  final int? divisions;

  /// Which way the track runs.
  final Axis axis;

  /// Which way the value grows along a vertical track.
  final VerticalDirection growsToward;

  /// Called before a key changes the value.
  final ValueChanged<double>? onChangeStart;

  /// Called after a key changed the value.
  final ValueChanged<double>? onChangeEnd;

  /// Whether the parent is dragging it ([WidgetState.pressed]).
  final bool dragging;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// What a screen reader hears for a value, as
  /// `Slider.semanticFormatterCallback`; null: a whole percentage of the
  /// range.
  final String Function(double value)? semanticFormatterCallback;

  /// Its focus node. The caller's, who disposes it; null: the handle's
  /// [Focus] makes its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The cursor over it; null: a grab cursor along its axis.
  final MouseCursor? mouseCursor;

  /// The least size of its target.
  final Size minimumSize;

  /// Keys it does not handle itself (Enter on a split view's divider).
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;

  @override
  State<DesignValueHandle> createState() => _DesignValueHandleState();
}

class _DesignValueHandleState extends State<DesignValueHandle> {
  bool _hovered = false;
  bool _focused = false;

  double get _range => widget.max - widget.min;

  double get _step {
    final s = widget.step;
    if (s != null) return s;
    final d = widget.divisions;
    return d != null && d > 0 ? _range / d : _range / 100;
  }

  double get _page {
    final p = widget.pageStep ?? _range / 10;
    return p < _step ? _step : p;
  }

  double _snap(double v) {
    final c = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    if (d == null || d <= 0) return c;
    final unit = _range / d;
    return widget.min + ((c - widget.min) / unit).round() * unit;
  }

  void _set(double to) {
    final change = widget.onChanged;
    final v = _snap(to);
    if (change == null || v == widget.value) return;
    widget.onChangeStart?.call(widget.value);
    change(v);
    widget.onChangeEnd?.call(v);
  }

  String _say(double v) =>
      widget.semanticFormatterCallback?.call(v) ??
      '${(_range == 0 ? 0 : (v - widget.min) / _range * 100).round()}%';

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (widget.onChanged == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey up;
    final LogicalKeyboardKey down;
    if (widget.axis == Axis.horizontal) {
      up = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
      down = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    } else if (widget.growsToward == VerticalDirection.up) {
      up = LogicalKeyboardKey.arrowUp;
      down = LogicalKeyboardKey.arrowDown;
    } else {
      up = LogicalKeyboardKey.arrowDown;
      down = LogicalKeyboardKey.arrowUp;
    }
    final horizontal = widget.axis == Axis.horizontal;
    final v = widget.value;
    if (key == up || (horizontal && key == LogicalKeyboardKey.arrowUp)) {
      _set(v + _step);
    } else if (key == down ||
        (horizontal && key == LogicalKeyboardKey.arrowDown)) {
      _set(v - _step);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _set(v + _page);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _set(v - _page);
    } else if (key == LogicalKeyboardKey.home) {
      _set(widget.min);
    } else if (key == LogicalKeyboardKey.end) {
      _set(widget.max);
    } else {
      return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final v = widget.value;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (enabled && _hovered) WidgetState.hovered,
      if (enabled && _focused) WidgetState.focused,
      if (enabled && widget.dragging) WidgetState.pressed,
    };
    final cursor =
        widget.mouseCursor ??
        (enabled
            ? (widget.axis == Axis.horizontal
                  ? SystemMouseCursors.resizeLeftRight
                  : SystemMouseCursors.resizeUpDown)
            : MouseCursor.defer);
    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticLabel,
      value: _say(v),
      increasedValue: v < widget.max ? _say(_snap(v + _step)) : null,
      decreasedValue: v > widget.min ? _say(_snap(v - _step)) : null,
      onIncrease: enabled && v < widget.max ? () => _set(v + _step) : null,
      onDecrease: enabled && v > widget.min ? () => _set(v - _step) : null,
      enabled: enabled,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: _key,
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor: cursor,
          onShowFocusHighlight: (on) => setState(() => _focused = on),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: widget.minimumSize.width,
                minHeight: widget.minimumSize.height,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: widget.builder(context, states),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
