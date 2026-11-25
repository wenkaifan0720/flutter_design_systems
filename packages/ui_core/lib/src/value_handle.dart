/// A value handle, headless: the focusable thumb of a slider, a range
/// slider, a split view's divider or a colour picker's channel. It holds the
/// keys (arrows by [RawValueHandle.step], Page Up and Down by
/// [RawValueHandle.pageStep], Home and End to the ends), the screen
/// reader's slider (its value, increase and decrease) and the face's states;
/// its parent turns pointer drags into values, since only it knows the
/// track.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'internal/focus_visible.dart';
import 'localizations.dart';

/// Builds a handle's face for its [states] (focused while the keyboard is
/// on it, hovered, pressed and dragged while dragged, disabled).
typedef RawHandleBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// A focusable value between [min] and [max].
///
/// Along a horizontal [axis], Right and Up raise the value (Left in right
/// to left). Along a vertical one, the arrow toward [growsToward] raises it.
///
/// ```dart
/// RawValueHandle(value: 0.5, onChanged: (value) {}, semanticLabel: 'Volume', builder: (context, states) => const SizedBox(width: 20, height: 20))
/// ```
class RawValueHandle extends StatefulWidget {
  /// A handle at [value].
  const RawValueHandle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.builder,
    this.min = 0,
    this.max = 1,
    this.step,
    this.pageStep,
    this.divisions,
    this.clampValue,
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
    this.minimumSize = const Size(40, 40),
    this.onKeyEvent,
    this.statesController,
  }) : assert(min <= max, 'min is at most max'),
       assert(
         value >= min && value <= max,
         'value $value is between min $min and max $max',
       ),
       assert(divisions == null || divisions > 0),
       assert(step == null || step > 0),
       assert(pageStep == null || pageStep > 0);

  /// The value.
  final double value;

  /// A key's or a screen reader's new value.
  ///
  /// {@template design.nullDisables}
  /// Null disables it, with no second switch, as Flutter's controls do: it
  /// leaves the focus order and a screen reader reads it as disabled.
  /// {@endtemplate}
  final ValueChanged<double>? onChanged;

  /// Paints the handle.
  final RawHandleBuilder builder;

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

  /// Limits a snapped value before it is announced or sent to [onChanged].
  /// A range slider uses this to keep a thumb clear of its neighbour while
  /// keeping both thumbs on the same scale. The callback must be pure.
  final double Function(double value)? clampValue;

  /// Which way the track runs.
  final Axis axis;

  /// Which way the value grows along a vertical track.
  final VerticalDirection growsToward;

  /// Called before a key changes the value.
  final ValueChanged<double>? onChangeStart;

  /// Called after a key changed the value.
  final ValueChanged<double>? onChangeEnd;

  /// Whether the parent is dragging it ([WidgetState.dragged], and
  /// [WidgetState.pressed] as before it).
  final bool dragging;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// What a screen reader hears for a value, as
  /// `Slider.semanticFormatterCallback`; null: a whole percentage of the
  /// range, formatted in the reader's locale.
  final String Function(double value)? semanticFormatterCallback;

  /// Its focus node.
  ///
  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// The cursor over it; null: a grab cursor ([SystemMouseCursors.grab]),
  /// grabbing ([SystemMouseCursors.grabbing]) while [dragging], and the
  /// basic arrow when disabled.
  final MouseCursor? mouseCursor;

  /// The least size of its target.
  final Size minimumSize;

  /// Keys it does not handle itself (Enter on a split view's divider).
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;

  /// The states, when the caller watches or drives them itself, as
  /// [RawButton.statesController]. The caller's, who disposes it; null:
  /// the handle makes its own and disposes it.
  final WidgetStatesController? statesController;

  @override
  State<RawValueHandle> createState() => _RawValueHandleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<double>>.has('onChanged', onChanged),
      )
      ..add(ObjectFlagProperty<RawHandleBuilder>.has('builder', builder))
      ..add(DoubleProperty('min', min, defaultValue: 0))
      ..add(DoubleProperty('max', max, defaultValue: 1))
      ..add(DoubleProperty('step', step, defaultValue: null))
      ..add(DoubleProperty('pageStep', pageStep, defaultValue: null))
      ..add(IntProperty('divisions', divisions, defaultValue: null))
      ..add(
        ObjectFlagProperty<double Function(double)>.has(
          'clampValue',
          clampValue,
        ),
      )
      ..add(EnumProperty<Axis>('axis', axis, defaultValue: Axis.horizontal))
      ..add(
        EnumProperty<VerticalDirection>(
          'growsToward',
          growsToward,
          defaultValue: VerticalDirection.up,
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
        FlagProperty(
          'dragging',
          value: dragging,
          ifTrue: 'dragging',
          defaultValue: false,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(double value)>.has(
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
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<MouseCursor>(
          'mouseCursor',
          mouseCursor,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'minimumSize',
          minimumSize,
          defaultValue: const Size(40, 40),
        ),
      )
      ..add(
        ObjectFlagProperty<
          KeyEventResult Function(FocusNode node, KeyEvent event)
        >.has('onKeyEvent', onKeyEvent),
      )
      ..add(
        DiagnosticsProperty<WidgetStatesController>(
          'statesController',
          statesController,
          defaultValue: null,
        ),
      );
  }
}

class _RawValueHandleState extends State<RawValueHandle> {
  WidgetStatesController? _own;

  WidgetStatesController get _controller =>
      widget.statesController ?? (_own ??= WidgetStatesController());

  bool _hovered = false;
  bool _focused = false;
  // Shown as a browser's :focus-visible shows it (internal/focus_visible.dart).
  late final RawFocusShown _focus;

  bool get _enabled => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    _focus = RawFocusShown((on) {
      _focused = on;
      _putState(WidgetState.focused, _enabled && on);
    });
    _controller.addListener(_changed);
    _sync(null);
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _putState(WidgetState state, bool on) {
    if (_controller.value.contains(state) != on) {
      _controller.update(state, on);
    }
  }

  // Brings the states a change of the widget makes in line, during
  // build-time updates (no listener runs mid-build): disabled with
  // [RawValueHandle.onChanged], pressed and dragged with
  // [RawValueHandle.dragging]. What the pointer and the focus bring stays.
  void _sync(RawValueHandle? old) {
    final v = _controller.value;
    void put(WidgetState state, bool on) => on ? v.add(state) : v.remove(state);
    final enabled = _enabled;
    if (old == null || (old.onChanged != null) != enabled) {
      put(WidgetState.disabled, !enabled);
      put(WidgetState.hovered, enabled && _hovered);
      put(WidgetState.focused, enabled && _focused);
    }
    final dragged = enabled && widget.dragging;
    if (old == null
        ? dragged
        : (old.onChanged != null && old.dragging) != dragged) {
      put(WidgetState.pressed, dragged);
      put(WidgetState.dragged, dragged);
    }
  }

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

  // A dragged thumb crossing a division plays the haptic
  // table's step (RawHaptics.selectionChanged).
  @override
  void didUpdateWidget(RawValueHandle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statesController != widget.statesController) {
      (oldWidget.statesController ?? _own)?.removeListener(_changed);
      if (widget.statesController != null) {
        _own?.dispose();
        _own = null;
      }
      _controller.addListener(_changed);
    }
    final before = Set.of(_controller.value);
    _sync(oldWidget);
    // A change the widget brought is told to the controller's listeners once
    // the frame is built, as [RawButton] tells one.
    if (!setEquals(before, _controller.value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.value = Set.of(_controller.value);
      });
    }
    final d = widget.divisions;
    if (!widget.dragging || d == null || _range == 0) return;
    int division(double v) => ((v - widget.min) / (_range / d)).round();
    if (division(widget.value) != division(oldWidget.value)) {
      RawHaptics.of(context).selectionChanged?.call();
    }
  }

  double _nextValue(double v) {
    final c = v.clamp(widget.min, widget.max);
    final d = widget.divisions;
    var snapped = c;
    if (d != null && d > 0 && _range > 0) {
      final unit = _range / d;
      snapped = widget.min + ((c - widget.min) / unit).round() * unit;
    }
    return (widget.clampValue?.call(snapped) ?? snapped).clamp(
      widget.min,
      widget.max,
    );
  }

  void _set(double v) {
    final change = widget.onChanged;
    if (change == null || v == widget.value) return;
    widget.onChangeStart?.call(widget.value);
    change(v);
    widget.onChangeEnd?.call(v);
  }

  String _say(double v) =>
      widget.semanticFormatterCallback?.call(v) ??
      RawWidgetsLocalizations.of(context)
          .formatPercent(_range == 0 ? 0 : (v - widget.min) / _range);

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
    final double next;
    if (key == up || (horizontal && key == LogicalKeyboardKey.arrowUp)) {
      next = v + _step;
    } else if (key == down ||
        (horizontal && key == LogicalKeyboardKey.arrowDown)) {
      next = v - _step;
    } else if (key == LogicalKeyboardKey.pageUp) {
      next = v + _page;
    } else if (key == LogicalKeyboardKey.pageDown) {
      next = v - _page;
    } else if (key == LogicalKeyboardKey.home) {
      next = widget.min;
    } else if (key == LogicalKeyboardKey.end) {
      next = widget.max;
    } else {
      return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
    }
    _set(_nextValue(next));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    final v = widget.value;
    final higher = _nextValue(v + _step);
    final lower = _nextValue(v - _step);
    final states = Set<WidgetState>.unmodifiable(_controller.value);
    final cursor =
        widget.mouseCursor ??
        (!enabled
            ? SystemMouseCursors.basic
            : widget.dragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab);
    return Semantics(
      container: true,
      slider: true,
      label: widget.semanticLabel,
      value: _say(v),
      increasedValue: higher > v ? _say(higher) : null,
      decreasedValue: lower < v ? _say(lower) : null,
      onIncrease: enabled && higher > v ? () => _set(higher) : null,
      onDecrease: enabled && lower < v ? () => _set(lower) : null,
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
          onShowFocusHighlight: _focus.focused,
          child: MouseRegion(
            onEnter: (_) {
              _hovered = true;
              _putState(WidgetState.hovered, _enabled);
            },
            onExit: (_) {
              _hovered = false;
              _putState(WidgetState.hovered, false);
            },
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
