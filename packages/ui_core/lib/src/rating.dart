/// A rating, headless: a row of items (stars, hearts) filled up to a value,
/// set by a tap, a drag, the keys or a screen reader, in whole or half
/// steps; or shown read-only (an average).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'localizations.dart';

/// One item of a [RawRating], as the look paints it.
@immutable
class RawRatingItemDetails {
  /// An item's details.
  const RawRatingItemDetails({
    required this.index,
    required this.fill,
    required this.isPreview,
    required this.states,
  });

  /// Its place in the row, from 0, in reading order.
  final int index;

  /// How much of it the value shown covers, 0 to 1: 0, 0.5 or 1, or any
  /// fraction of a value such as an average of 3.7.
  final double fill;

  /// Whether [fill] shows where a hovering pointer would set the rating,
  /// not its value.
  final bool isPreview;

  /// The rating's states: [WidgetState.focused], [WidgetState.hovered],
  /// [WidgetState.disabled], and [WidgetState.pressed] on the item under
  /// the held pointer as it presses or drags.
  final Set<WidgetState> states;
}

/// Paints one item of a rating.
typedef RawRatingItemBuilder = Widget Function(
  BuildContext context,
  RawRatingItemDetails details,
);

/// Lays out a rating's [items], in reading order.
typedef RawRatingLayoutBuilder = Widget Function(
  BuildContext context,
  List<Widget> items,
);

/// A rating of [itemCount] items filled up to [value] (0, none, to
/// [itemCount]): [onChanged] gets the value a tap, a drag, a key or a
/// screen reader sets.
///
/// A tap sets the item tapped (its first half, a half, with [allowHalf];
/// mirrored right to left); a tap on the value already set changes
/// nothing. Hovering previews the value a tap would set; a drag sweeps
/// across, changing it as it goes, a step played at each
/// ([DesignHaptics.selectionChanged]). Keys (a single tab stop): Right and
/// Up step up, Left and Down back (Right and Left as drawn, so mirrored
/// right to left), End sets [itemCount], Home or 0 clears it, a digit
/// sets that many. A screen reader hears a slider, "Rating, 3 of 5"
/// ([RawWidgetsLocalizations.ratingValueLabel]), and steps it.
///
/// [readOnly] shows a value (an average of 3.7): no input and no tab stop,
/// read as a value, not as disabled.
///
/// ```dart
/// RawRating(value: 3, onChanged: (value) {}, itemBuilder: (context, item) => Text(item.fill >= 1 ? '★' : '☆'))
/// ```
class RawRating extends StatefulWidget {
  /// A rating showing [value].
  const RawRating({
    super.key,
    required this.value,
    required this.onChanged,
    required this.itemBuilder,
    this.itemCount = 5,
    this.allowHalf = false,
    this.readOnly = false,
    this.layoutBuilder,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
  }) : assert(itemCount > 0),
       assert(value >= 0 && value <= itemCount);

  /// How many items are filled, 0 to [itemCount]; any fraction shows.
  final double value;

  /// Called with each value set, a drag's as it moves.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<double>? onChanged;

  /// Paints an item.
  final RawRatingItemBuilder itemBuilder;

  /// How many items. Defaults to 5.
  final int itemCount;

  /// Whether a value can end in a half: from where the pointer lands, and
  /// in the keys' and a screen reader's steps. Defaults to false.
  final bool allowHalf;

  /// Whether it only shows [value]: no input, no tab stop, read as a value
  /// rather than as disabled. Defaults to false.
  final bool readOnly;

  /// Lays out the items; null: a [Row] in reading order.
  final RawRatingLayoutBuilder? layoutBuilder;

  /// Called with the value as a change begins (a press, a drag, a key).
  final ValueChanged<double>? onChangeStart;

  /// Called with the value as a change ends (a release, a key).
  final ValueChanged<double>? onChangeEnd;

  /// What a screen reader calls it; null: "Rating"
  /// ([RawWidgetsLocalizations.ratingLabel]).
  final String? semanticLabel;

  /// How a screen reader says a value; null: "3.5 of 5" in the reader's
  /// numbers ([RawWidgetsLocalizations.ratingValueLabel]).
  final String Function(double value)? semanticFormatterCallback;

  /// The rating's focus; null: its own.
  final FocusNode? focusNode;

  /// Whether the rating takes focus when it first shows.
  final bool autofocus;

  /// The pointer's cursor over it; null: a click cursor while it takes
  /// input.
  final MouseCursor? mouseCursor;

  @override
  State<RawRating> createState() => _DesignRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawRatingItemBuilder>.has(
          'itemBuilder',
          itemBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawRatingLayoutBuilder>.has(
          'layoutBuilder',
          layoutBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has(
          'onChangeStart',
          onChangeStart,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has(
          'onChangeEnd',
          onChangeEnd,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(double)>.has(
          'semanticFormatterCallback',
          semanticFormatterCallback,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MouseCursor>(
          'mouseCursor',
          mouseCursor,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(IntProperty('itemCount', itemCount, defaultValue: 5))
      ..add(
        FlagProperty(
          'allowHalf',
          value: allowHalf,
          ifTrue: 'allowHalf',
          defaultValue: false,
        ),
      )
      ..add(
        FlagProperty(
          'readOnly',
          value: readOnly,
          ifTrue: 'readOnly',
          defaultValue: false,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

class _DesignRatingState extends State<RawRating> {
  FocusNode? _ownNode;
  List<GlobalKey> _keys = const [];
  // The value a hovering pointer would set; null, none.
  double? _preview;
  // The value a drag has set so far; null, no drag.
  double? _dragged;
  int? _pressedItem;
  bool _hovered = false;

  FocusNode get _node =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'rating'));

  bool get _interactive => widget.onChanged != null && !widget.readOnly;
  double get _step => widget.allowHalf ? 0.5 : 1;

  @override
  void initState() {
    super.initState();
    _node.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(RawRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_rebuild);
      _node.addListener(_rebuild);
    }
    if (!_interactive) {
      _preview = null;
      _dragged = null;
      _pressedItem = null;
    }
  }

  @override
  void dispose() {
    _node.removeListener(_rebuild);
    _ownNode?.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // One whole change (a tap, a key, a screen reader's step).
  void _change(double value) {
    final next = value.clamp(0, widget.itemCount).toDouble();
    if (next == widget.value) return;
    widget.onChangeStart?.call(widget.value);
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
  }

  // The step above [value], or below it, on this rating's steps.
  double _stepFrom(double value, int way) {
    final steps = value / _step;
    final on = (steps - steps.roundToDouble()).abs() < 1e-9;
    final n = way > 0
        ? (on ? steps.round() + 1 : steps.ceil())
        : (on ? steps.round() - 1 : steps.floor());
    return (n * _step).clamp(0, widget.itemCount).toDouble();
  }

  // The value a pointer at [global] sets: the item under it, its first
  // half a half; before the first item the least step, past the last all.
  double? _valueAt(Offset global) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      final local = box.globalToLocal(global);
      final width = box.size.width;
      final fraction = rtl ? (width - local.dx) / width : local.dx / width;
      if (fraction < 0 && i == 0) return _step;
      if (fraction >= 0 && fraction < 1) {
        return widget.allowHalf && fraction < 0.5 ? i + 0.5 : i + 1.0;
      }
    }
    return widget.itemCount.toDouble();
  }

  void _hover(PointerHoverEvent event) {
    if (!_interactive || _dragged != null) return;
    final at = _valueAt(event.position);
    if (at != _preview) setState(() => _preview = at);
  }

  void _dragStart(Offset global) {
    widget.onChangeStart?.call(widget.value);
    _dragged = widget.value;
    _preview = null;
    _dragTo(global);
  }

  void _press(double? value) {
    final index = value?.ceil();
    final pressed = index == null ? null : index - 1;
    if (pressed != _pressedItem) setState(() => _pressedItem = pressed);
  }

  void _dragTo(Offset global) {
    final at = _valueAt(global);
    _press(at);
    if (at == null || at == _dragged) return;
    _dragged = at;
    DesignHaptics.of(context).selectionChanged?.call();
    widget.onChanged?.call(at);
    setState(() {});
  }

  void _dragEnd() {
    if (_pressedItem != null) setState(() => _pressedItem = null);
    // A tap cancels the drag it never became: nothing to end.
    final at = _dragged;
    if (at == null) return;
    setState(() => _dragged = null);
    widget.onChangeEnd?.call(at);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_interactive) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final v = widget.value;
    if (key == LogicalKeyboardKey.arrowUp || key == forward) {
      _change(_stepFrom(v, 1));
    } else if (key == LogicalKeyboardKey.arrowDown || key == back) {
      _change(_stepFrom(v, -1));
    } else if (key == LogicalKeyboardKey.home) {
      _change(0);
    } else if (key == LogicalKeyboardKey.end) {
      _change(widget.itemCount.toDouble());
    } else {
      final c = event.character;
      final digit = c == null || c.length != 1 ? null : int.tryParse(c);
      if (digit == null || digit > widget.itemCount) {
        return KeyEventResult.ignored;
      }
      _change(digit.toDouble());
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l = RawWidgetsLocalizations.of(context);
    if (_keys.length != widget.itemCount) {
      _keys = [for (var i = 0; i < widget.itemCount; i++) GlobalKey()];
    }
    final v = widget.value;
    final preview = _interactive ? _preview : null;
    final shown = preview ?? v;
    final disabled = widget.onChanged == null && !widget.readOnly;
    final states = <WidgetState>{
      if (_interactive && _node.hasFocus) WidgetState.focused,
      if (_interactive && _hovered) WidgetState.hovered,
      if (disabled) WidgetState.disabled,
    };
    final items = [
      for (var i = 0; i < widget.itemCount; i++)
        KeyedSubtree(
          key: _keys[i],
          child: widget.itemBuilder(
            context,
            RawRatingItemDetails(
              index: i,
              fill: (shown - i).clamp(0, 1).toDouble(),
              isPreview: preview != null,
              states: i == _pressedItem
                  ? {...states, WidgetState.pressed}
                  : states,
            ),
          ),
        ),
    ];
    String say(double value) =>
        widget.semanticFormatterCallback?.call(value) ??
        l.ratingValueLabel(value, widget.itemCount);
    final up = _interactive && v < widget.itemCount ? _stepFrom(v, 1) : null;
    final down = _interactive && v > 0 ? _stepFrom(v, -1) : null;
    final laidOut =
        widget.layoutBuilder?.call(context, items) ??
        Row(mainAxisSize: MainAxisSize.min, children: items);
    return Semantics(
      container: true,
      slider: !widget.readOnly,
      label: widget.semanticLabel ?? l.ratingLabel,
      value: say(v),
      increasedValue: up == null ? null : say(up),
      decreasedValue: down == null ? null : say(down),
      onIncrease: up == null ? null : () => _change(up),
      onDecrease: down == null ? null : () => _change(down),
      enabled: widget.readOnly ? null : !disabled,
      child: Focus(
        focusNode: _node,
        autofocus: widget.autofocus,
        canRequestFocus: _interactive,
        skipTraversal: !_interactive,
        includeSemantics: !widget.readOnly,
        onKeyEvent: _onKey,
        child: MouseRegion(
          cursor: _interactive
              ? widget.mouseCursor ?? SystemMouseCursors.click
              : MouseCursor.defer,
          onEnter: (_) => setState(() => _hovered = true),
          onHover: _hover,
          onExit: (_) => setState(() {
            _hovered = false;
            _preview = null;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onHorizontalDragDown: _interactive
                ? (details) => _press(_valueAt(details.globalPosition))
                : null,
            onTapUp: _interactive
                ? (details) {
                    final at = _valueAt(details.globalPosition);
                    if (at != null) _change(at);
                  }
                : null,
            onHorizontalDragStart: _interactive
                ? (details) => _dragStart(details.globalPosition)
                : null,
            onHorizontalDragUpdate: _interactive
                ? (details) => _dragTo(details.globalPosition)
                : null,
            onHorizontalDragEnd: _interactive ? (_) => _dragEnd() : null,
            onHorizontalDragCancel: _interactive ? _dragEnd : null,
            child: ExcludeSemantics(child: laidOut),
          ),
        ),
      ),
    );
  }
}
