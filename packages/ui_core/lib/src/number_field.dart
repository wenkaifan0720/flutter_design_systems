/// A number field, headless: a number typed in the reader's digits and
/// separators, stepped by the keys, a screen reader or two buttons that
/// repeat while held, and kept within its bounds.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/decimal.dart' as decimal;
import 'internal/field_words.dart';
import 'localizations.dart';

/// The field, as [RawNumberField.fieldBuilder] gets it: wire
/// [controller], [focusNode], [keyboardType], [inputFormatters] and
/// [onEditingComplete] to the look's text input.
@immutable
class RawNumberFieldDetails {
  /// The field's wiring.
  const RawNumberFieldDetails({
    required this.controller,
    required this.focusNode,
    required this.keyboardType,
    required this.inputFormatters,
    required this.onEditingComplete,
    required this.states,
  });

  /// The text the field edits: the caller's when it gave one, else the
  /// field's own. The field never disposes a caller's.
  final TextEditingController controller;

  /// The field's focus: the caller's when it gave one, else the field's.
  final FocusNode focusNode;

  /// A number pad: with a decimal key unless the step and the least value
  /// are whole, with a minus unless the least value is 0 or more.
  final TextInputType keyboardType;

  /// Keep out what can't become a number: letters, a second decimal
  /// separator, a decimal separator where only whole numbers go, a minus
  /// where none can.
  final List<TextInputFormatter> inputFormatters;

  /// Takes the typed number: pass it to the input's `onEditingComplete`
  /// (not `onSubmitted`: Enter takes the number and keeps the focus, as the
  /// web's does). Focus leaving the field takes it too.
  final VoidCallback onEditingComplete;

  /// The field's states: [WidgetState.focused], [WidgetState.hovered],
  /// [WidgetState.disabled] (a look makes its input read-only), and
  /// [WidgetState.error] while the text does not read as a number.
  final Set<WidgetState> states;
}

/// One of a number field's step buttons, as the look paints it.
@immutable
class RawNumberFieldButtonDetails {
  /// A button's details.
  const RawNumberFieldButtonDetails({
    required this.isIncrement,
    required this.states,
  });

  /// Whether it steps up; false, down.
  final bool isIncrement;

  /// Its states: [WidgetState.pressed] while held, [WidgetState.hovered],
  /// [WidgetState.disabled] at the limit or while the field is.
  final Set<WidgetState> states;
}

/// Paints the field's text input.
typedef RawNumberFieldBuilder = Widget Function(
  BuildContext context,
  RawNumberFieldDetails details,
);

/// Paints a step button: a look gives it a finger's floor
/// ([TapTargetPadding]).
typedef RawNumberFieldButtonBuilder = Widget Function(
  BuildContext context,
  RawNumberFieldButtonDetails details,
);

/// Lays out the [field] and its [decrement] and [increment] buttons.
typedef RawNumberFieldLayoutBuilder = Widget Function(
  BuildContext context,
  Widget field,
  Widget decrement,
  Widget increment,
);

/// A number typed or stepped: [value] the number, null when empty;
/// [onChanged] gets it as it is taken (Enter, the focus leaving, a step),
/// not on each key typed.
///
/// The text is the reader's ([RawWidgetsLocalizations.formatDecimal]: German's
/// `1.234,5`; Arabic's in Arabic-Indic digits, U+0660 to U+0669, grouped
/// by U+066C with U+066B for the point) and reads back in their digits or
/// ASCII.
/// A number typed is clamped to [min] and [max] and rounded to
/// [fractionDigits]; one that does not read puts the last value back.
///
/// A step goes to the next multiple of [step] counted from [min] (or 0)
/// that way, exactly in decimals (0.1 then 0.2 then 0.3), and takes typed
/// text first. Keys in the field: Up and Down a step, Page Up and Page
/// Down [pageStep]; Home and End stay the caret's. The two buttons step
/// once on a press and repeat while held; they are no tab stops and no
/// screen reader nodes: the field's own node steps, with the next and
/// previous values. That node spans the field but its buttons: each button
/// is cut away from the side of the entry (the box [fieldBuilder] builds)
/// it stands on, so a tap through the semantics tree on a button (a click
/// on the web with semantics on) reaches no node in the button's place.
/// Inside a
/// [RawInputDecorator] it takes the field's name, help and error, and the field
/// adds no node of its own that says them.
///
/// That node takes its value from the input's, merged into it. An input
/// that says itself whether it is enabled (Material's `TextField`) does
/// not merge: Flutter keeps apart two nodes that both say so, and the
/// field's node is left with next and previous values but no value, which
/// Flutter 3.47 asserts against. Give the value on the field's node, round
/// the input in [fieldBuilder]: `ListenableBuilder(listenable:
/// field.controller, builder: (context, child) => Semantics(value:
/// field.controller.text, child: child), child: TextField(...))` (the
/// input then stands in a node of its own under it).
///
/// ```dart
/// RawNumberField(value: 2, onChanged: (value) {}, min: 0, fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, keyboardType: field.keyboardType, inputFormatters: field.inputFormatters, onEditingComplete: field.onEditingComplete, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080)), buttonBuilder: (context, button) => Text(button.isIncrement ? '+' : '−'))
/// ```
class RawNumberField extends StatefulWidget {
  /// A number field showing [value].
  const RawNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.fieldBuilder,
    required this.buttonBuilder,
    this.layoutBuilder,
    this.min,
    this.max,
    this.step = 1,
    this.pageStep,
    this.fractionDigits,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.semanticFormatterCallback,
    this.repeatDelay = const Duration(milliseconds: 400),
    this.repeatInterval = const Duration(milliseconds: 80),
  }) : assert(step > 0),
       assert(min == null || max == null || min <= max);

  /// The number shown; null, empty.
  final double? value;

  /// Called with the number as it is taken, or null when the field is
  /// cleared.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<double?>? onChanged;

  /// Paints the text input. One that says itself whether it is enabled
  /// (Material's `TextField`) gives the field's node its value round it
  /// (see [RawNumberField]).
  final RawNumberFieldBuilder fieldBuilder;

  /// Paints a step button.
  final RawNumberFieldButtonBuilder buttonBuilder;

  /// Lays out the input and the buttons; null: a row of decrement, field,
  /// increment, in reading order (mirrored right to left).
  final RawNumberFieldLayoutBuilder? layoutBuilder;

  /// The least value; null, none.
  final double? min;

  /// The greatest value; null, none.
  final double? max;

  /// What a step moves by, to the next multiple counted from [min] (or
  /// 0). Defaults to 1: whole numbers, with no decimal key.
  final double step;

  /// What Page Up and Page Down move by; null: ten steps.
  final double? pageStep;

  /// The decimals a typed number keeps; null: as many as [step] and [min]
  /// have. The text shows as many as the number has, up to these.
  final int? fractionDigits;

  /// The text the field edits; null: the field's own.
  final TextEditingController? controller;

  /// The field's focus; null: the field's own.
  final FocusNode? focusNode;

  /// Whether the field takes focus when it first shows.
  final bool autofocus;

  /// What a screen reader calls the field ("Quantity"); null: the look's
  /// label, if it gives one. Inside a [RawInputDecorator] with a label, the
  /// field's label names it.
  final String? semanticLabel;

  /// How a screen reader says the next and previous values ("3 guests");
  /// null: the number in the reader's digits.
  final String Function(double value)? semanticFormatterCallback;

  /// How long a button is held before it repeats.
  final Duration repeatDelay;

  /// How often a held button steps once it repeats.
  final Duration repeatInterval;

  @override
  State<RawNumberField> createState() => _DesignNumberFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawNumberFieldBuilder>.has(
          'fieldBuilder',
          fieldBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawNumberFieldButtonBuilder>.has(
          'buttonBuilder',
          buttonBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawNumberFieldLayoutBuilder>.has(
          'layoutBuilder',
          layoutBuilder,
        ),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
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
        ObjectFlagProperty<String Function(double)>.has(
          'semanticFormatterCallback',
          semanticFormatterCallback,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'repeatDelay',
          repeatDelay,
          defaultValue: const Duration(milliseconds: 400),
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'repeatInterval',
          repeatInterval,
          defaultValue: const Duration(milliseconds: 80),
        ),
      )
      ..add(DoubleProperty('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<double?>>.has('onChanged', onChanged),
      )
      ..add(DoubleProperty('min', min, defaultValue: null))
      ..add(DoubleProperty('max', max, defaultValue: null))
      ..add(DoubleProperty('step', step, defaultValue: 1.0))
      ..add(DoubleProperty('pageStep', pageStep, defaultValue: null))
      ..add(IntProperty('fractionDigits', fractionDigits, defaultValue: null))
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

class _DesignNumberFieldState extends State<RawNumberField> {
  TextEditingController? _ownController;
  FocusNode? _ownNode;
  bool _hovered = false;
  bool _autofocused = false;
  // The value last taken or given: what an unreadable text goes back to.
  double? _value;
  // The text last shown for [_value]: unedited, it stands for [_value]
  // itself, not the number it rounds to.
  String _shown = '';
  // Whether the text was empty, or did not read, at the last build.
  bool _wasEmpty = true;
  bool _wasUnread = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _node =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'number field'));

  bool get _enabled => widget.onChanged != null;

  // The decimals a number keeps: the caller's, else the step's and min's.
  int get _places =>
      widget.fractionDigits ??
      [
        decimal.decimalsOf(widget.step),
        decimal.decimalsOf(widget.min ?? 0),
      ].reduce((a, b) => a > b ? a : b);

  bool get _whole => _places == 0;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _node.addListener(_focusChanged);
    _controller.addListener(_textChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_node.hasFocus) _show(_value);
    if (widget.autofocus && !_autofocused && _enabled) {
      _autofocused = true;
      FocusScope.of(context).autofocus(_node);
    }
  }

  @override
  void didUpdateWidget(RawNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_textChanged);
      _controller.addListener(_textChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_focusChanged);
      _node.addListener(_focusChanged);
    }
    if (widget.value != _value) {
      _value = widget.value;
      if (!_node.hasFocus) _show(_value);
    } else if (oldWidget.fractionDigits != widget.fractionDigits ||
        oldWidget.controller != widget.controller) {
      if (!_node.hasFocus) _show(_value);
    }
    if (!_enabled && _node.hasFocus) _node.unfocus();
  }

  @override
  void dispose() {
    _node.removeListener(_focusChanged);
    _controller.removeListener(_textChanged);
    _ownController?.dispose();
    _ownNode?.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (!_node.hasFocus) _commit();
    setState(() {});
  }

  void _textChanged() {
    if (_controller.text.isEmpty != _wasEmpty || _unread != _wasUnread) {
      setState(() {});
    }
  }

  // Whether the text, edited, does not read as a number.
  bool get _unread {
    final text = _controller.text.trim();
    if (text.isEmpty || _controller.text == _shown) return false;
    return RawWidgetsLocalizations.of(context).parseDecimal(text) == null;
  }

  String _format(double value) =>
      RawWidgetsLocalizations.of(context)
          .formatDecimal(decimal.roundTo(value, _places));

  void _show(double? value) {
    final text = value == null ? '' : _format(value);
    _shown = text;
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  double _clamp(double value) {
    final min = widget.min;
    final max = widget.max;
    if (min != null && value < min) return min;
    if (max != null && value > max) return max;
    return value;
  }

  void _take(double? value) {
    final changed = value != _value;
    _value = value;
    _show(value);
    if (changed) widget.onChanged?.call(value);
  }

  // The typed text read, clamped and rounded; the value when unedited or
  // unreadable; null when empty.
  double? _read() {
    if (_controller.text == _shown) return _value;
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final read = RawWidgetsLocalizations.of(context).parseDecimal(text);
    if (read == null) return _value;
    return _clamp(decimal.roundTo(read, _places));
  }

  void _commit() {
    if (!_enabled) return;
    if (_controller.text == _shown) return;
    _take(_read());
  }

  // The value [count] steps of [by] on from the value as typed.
  double _stepped(int count, {double? by}) {
    final from = _read();
    final min = widget.min;
    final max = widget.max;
    if (from == null) {
      // An empty field starts at its least value, or 0 within the bounds.
      final start = min ?? 0;
      return max != null && start > max ? max : start;
    }
    return decimal.stepDecimal(
      from,
      step: by ?? widget.step,
      count: count,
      min: min,
      max: max,
    );
  }

  bool _canStep(int way) {
    if (!_enabled) return false;
    final v = _read();
    if (v == null) return true;
    final bound = way > 0 ? widget.max : widget.min;
    return bound == null || (way > 0 ? v < bound : v > bound);
  }

  void _step(int count, {double? by}) {
    if (!_enabled) return;
    _take(_stepped(count, by: by));
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_enabled) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final page = widget.pageStep ?? widget.step * 10;
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _step(-1);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _step(1, by: page);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _step(-1, by: page);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // Lets through text on its way to a number: empty, a lone minus, a
  // trailing separator, the grouping as it is being typed.
  bool _partial(String text, RawWidgetsLocalizations l) {
    if (text.isEmpty) return true;
    // The reader's separators, read off numbers written their way.
    final zero = l.formatDecimal(0).runes.first;
    String marks(String written) => String.fromCharCodes(
      written.runes.where((r) => r < 0x30 || r > 0x39 && (r - zero).abs() > 9),
    );
    final point = marks(l.formatDecimal(1.5));
    final grouped = marks(l.formatDecimal(1000000));
    final group = grouped.isEmpty ? '' : grouped.characters.first;
    final minus = marks(l.formatDecimal(-1));
    final signed =
        text.contains('-') ||
        text.contains('−') ||
        minus.runes.any((r) => r > 0x7F && text.runes.contains(r));
    if (signed && (widget.min ?? -1) >= 0) return false;
    if (_whole &&
        (text.contains(point) ||
            (point != '.' && group != '.' && text.contains('.')))) {
      return false;
    }
    final ungrouped = (group.isEmpty ? text : text.replaceAll(group, ''))
        .replaceAll(RegExp(r'[\s  ]'), '');
    bool reads(String t) => l.parseDecimal(t) != null;
    return reads(ungrouped) || reads('${ungrouped}0') || reads('${text}0');
  }

  Widget _button(bool up) => _StepButton(
    enabled: _canStep(up ? 1 : -1),
    isIncrement: up,
    builder: widget.buttonBuilder,
    onStep: () {
      // A held button stops at the limit.
      if (!_canStep(up ? 1 : -1)) return false;
      _step(up ? 1 : -1);
      return true;
    },
    repeatDelay: widget.repeatDelay,
    repeatInterval: widget.repeatInterval,
  );

  @override
  Widget build(BuildContext context) {
    final l = RawWidgetsLocalizations.of(context);
    final empty = _wasEmpty = _controller.text.isEmpty;
    final unread = _wasUnread = _unread;
    final states = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (_enabled && _node.hasFocus) WidgetState.focused,
      if (_enabled && _hovered) WidgetState.hovered,
      if (unread) WidgetState.error,
    };
    final up = _canStep(1) ? _stepped(1) : null;
    final down = _canStep(-1) ? _stepped(-1) : null;
    String say(double v) =>
        widget.semanticFormatterCallback?.call(v) ?? _format(v);
    final field = widget.fieldBuilder(
      context,
      RawNumberFieldDetails(
        controller: _controller,
        focusNode: _node,
        keyboardType: TextInputType.numberWithOptions(
          decimal: !_whole,
          signed: (widget.min ?? -1) < 0,
        ),
        inputFormatters: [
          TextInputFormatter.withFunction(
            (old, next) => _partial(next.text, l) ? next : old,
          ),
        ],
        onEditingComplete: _commit,
        states: states,
      ),
    );
    final decrement = _button(false);
    final increment = _button(true);
    // The field's words, when a RawInputDecorator round it gives them to this
    // field's node.
    final words = RawFieldWords.maybeOf(context);
    final entry = _Entry(
      child: words == null ? field : RawFieldWordsCarried(child: field),
    );
    return _FieldNode(
      properties: SemanticsProperties(
        label: words?.name ?? widget.semanticLabel,
        hint: words?.hint,
        validationResult: words?.invalid ?? false
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        isRequired: words?.required ?? false ? true : null,
        enabled: _enabled,
        minValue: widget.min?.toString(),
        maxValue: widget.max?.toString(),
        // The next values beside the text's; an empty field has neither.
        increasedValue: up == null || empty ? null : say(up),
        decreasedValue: down == null || empty ? null : say(down),
        onIncrease: up == null ? null : () => _step(1),
        onDecrease: down == null ? null : () => _step(-1),
      ),
      textDirection: Directionality.maybeOf(context),
      child: ExcludeFocus(
        excluding: !_enabled,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onKeyEvent: _onKey,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child:
                widget.layoutBuilder?.call(
                  context,
                  entry,
                  decrement,
                  increment,
                ) ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    decrement,
                    Flexible(child: entry),
                    increment,
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

// The field's node: what it says and does, over the entry's box alone, so
// the buttons beside the entry stand under no node that takes a tap in
// their place.
class _FieldNode extends SingleChildRenderObjectWidget {
  const _FieldNode({
    required this.properties,
    required this.textDirection,
    required super.child,
  });

  final SemanticsProperties properties;
  final TextDirection? textDirection;

  @override
  _RenderFieldNode createRenderObject(BuildContext context) =>
      _RenderFieldNode(properties: properties, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderFieldNode renderObject) {
    renderObject
      ..properties = properties
      ..textDirection = textDirection;
  }
}

class _RenderFieldNode extends RenderSemanticsAnnotations {
  _RenderFieldNode({required super.properties, super.textDirection})
    : super(container: true);

  // The field, each step button cut away from the side of the entry it
  // stands on (a button over the entry is left), so a tap through the
  // semantics tree on a button finds no node in its place.
  @override
  Rect get semanticBounds {
    final whole = super.semanticBounds;
    RenderBox? entry;
    final buttons = <RenderBox>[];
    void visit(RenderObject c) {
      if (c is _RenderEntry) {
        entry ??= c;
      } else if (c is _RenderButtonBox) {
        buttons.add(c);
      } else {
        c.visitChildren(visit);
      }
    }

    visitChildren(visit);
    final e = _rectOf(entry);
    if (e == null) return whole;
    var left = whole.left, top = whole.top;
    var right = whole.right, bottom = whole.bottom;
    const slack = .5;
    for (final button in buttons) {
      final r = _rectOf(button);
      if (r == null || r.isEmpty) continue;
      if (r.left >= e.right - slack) {
        right = math.min(right, r.left);
      } else if (r.right <= e.left + slack) {
        left = math.max(left, r.right);
      } else if (r.top >= e.bottom - slack) {
        bottom = math.min(bottom, r.top);
      } else if (r.bottom <= e.top + slack) {
        top = math.max(top, r.bottom);
      }
    }
    return Rect.fromLTRB(left, top, right, bottom).expandToInclude(e);
  }

  Rect? _rectOf(RenderBox? box) {
    if (box == null || !box.hasSize || !box.attached) return null;
    return MatrixUtils.transformRect(
      box.getTransformTo(this),
      Offset.zero & box.size,
    );
  }

  @override
  void performLayout() {
    super.performLayout();
    // The entry may move inside a field whose size stays: its node follows.
    markNeedsSemanticsUpdate();
  }
}

// The box the entry stands in, which the field's node always spans.
class _Entry extends SingleChildRenderObjectWidget {
  const _Entry({required super.child});

  @override
  _RenderEntry createRenderObject(BuildContext context) => _RenderEntry();
}

class _RenderEntry extends RenderProxyBox {}

// The box a step button stands in, which the field's node leaves out.
class _ButtonBox extends SingleChildRenderObjectWidget {
  const _ButtonBox({required super.child});

  @override
  _RenderButtonBox createRenderObject(BuildContext context) =>
      _RenderButtonBox();
}

class _RenderButtonBox extends RenderProxyBox {}

// A step button: a press steps, a hold repeats; pointer only.
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.enabled,
    required this.isIncrement,
    required this.builder,
    required this.onStep,
    required this.repeatDelay,
    required this.repeatInterval,
  });

  final bool enabled;
  final bool isIncrement;
  final RawNumberFieldButtonBuilder builder;
  // Steps once; false when it could not (the limit), which ends a hold.
  final bool Function() onStep;
  final Duration repeatDelay;
  final Duration repeatInterval;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;
  bool _pressed = false;
  bool _hovered = false;

  @override
  void didUpdateWidget(_StepButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _release();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    if (!widget.onStep()) return _release();
    _timer = Timer(widget.repeatDelay, () {
      _timer = Timer.periodic(widget.repeatInterval, (_) {
        if (!mounted || !widget.onStep()) _release();
      });
    });
  }

  void _release() {
    _timer?.cancel();
    _timer = null;
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) => _ButtonBox(
    child: ExcludeSemantics(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: widget.enabled ? (_) => _press() : null,
          onTapUp: widget.enabled ? (_) => _release() : null,
          onTapCancel: _release,
          child: widget.builder(
            context,
            RawNumberFieldButtonDetails(
              isIncrement: widget.isIncrement,
              states: {
                if (!widget.enabled) WidgetState.disabled,
                if (widget.enabled && _pressed) WidgetState.pressed,
                if (widget.enabled && _hovered) WidgetState.hovered,
              },
            ),
          ),
        ),
      ),
    ),
  );
}
