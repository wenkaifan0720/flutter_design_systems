import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/hit_slop.dart';
import '../../internal/measure.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';

/// Fluent 2's SpinButton: a number in a field 32 tall (24 small), 10 in
/// at its start, and at its end the two 24 wide steppers stacked, the
/// up and down chevrons (16) in the third ink on a subtle fill under the
/// pointer; each moves [value] by [step] within [min] and [max] (the one
/// at a bound is disabled), as do the up and down arrow keys (Page Up and
/// Down by ten steps); typed figures are taken on Enter or when the field
/// lets go of focus. [format] says the value in the field (the number at
/// [step]'s precision by default). [onChanged] gets each value; null
/// draws it disabled. Read as a spin button named [label].
///
/// ```dart
/// Fluent2SpinButton(label: 'Seats', value: seats, min: 1, max: 50, onChanged: (v) => setState(() => seats = v.toInt()))
/// ```
class Fluent2SpinButton extends StatefulWidget {
  /// A spin button: a number field with its step buttons.
  const Fluent2SpinButton({
    required this.value,
    required this.onChanged,
    this.label,
    this.min,
    this.max,
    this.step = 1,
    this.format,
    this.size = Fluent2InputSize.medium,
    this.appearance = Fluent2InputAppearance.outline,
    this.invalid = false,
    this.width = 120,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         size != Fluent2InputSize.large,
         "Fluent's SpinButton is small or medium",
       );

  /// The number shown.
  final num value;

  /// Called with the new number when the user types or steps it; null puts it
  /// out of use.
  final ValueChanged<num>? onChanged;

  /// The spoken name; null takes the enclosing field's label.
  final String? label;

  /// The least number; null sets no bound.
  final num? min;

  /// The greatest number; null sets no bound.
  final num? max;

  /// How far a step button moves the number.
  final num step;

  /// The words the field shows for a value.
  final String Function(num value)? format;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Whether it shows Fluent's invalid state, its edge in the danger colour.
  final bool invalid;

  /// The field's width at the default text size, growing with the reader's
  /// text size so its value is never cut; `double.infinity` takes the
  /// parent's.
  final double width;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2SpinButton> createState() => _Fluent2SpinButtonState();
}

class _Fluent2SpinButtonState extends State<Fluent2SpinButton> {
  late final TextEditingController _text = TextEditingController(
    text: _say(widget.value),
  );
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  int get _precision {
    final s = widget.step.toString();
    final dot = s.indexOf('.');
    return dot < 0 ? 0 : s.length - dot - 1;
  }

  String _say(num v) =>
      widget.format?.call(v) ??
      (_precision == 0 ? v.round().toString() : v.toStringAsFixed(_precision));

  num _clamp(num v) {
    var out = v;
    if (widget.min case final lo?) out = math.max(out, lo);
    if (widget.max case final hi?) out = math.min(out, hi);
    return _precision == 0
        ? out.round()
        : double.parse(out.toStringAsFixed(_precision));
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(Fluent2SpinButton old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
    final words = _say(widget.value);
    if (!_focus.hasFocus && words != _text.text) _text.text = words;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ownFocus?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (!_focus.hasFocus) _commit();
    if (mounted) setState(() {});
  }

  void _commit() {
    final typed = num.tryParse(_text.text.replaceAll(RegExp(r'[^0-9.\-]'), ''));
    final next = typed == null ? widget.value : _clamp(typed);
    _text.text = _say(next);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  void _by(num steps) {
    final next = _clamp(widget.value + widget.step * steps);
    _text.text = _say(next);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final scope = Fluent2FieldScope.maybeOf(context);
    final live = widget.onChanged != null;
    final small = widget.size == Fluent2InputSize.small;
    final canUp = live && (widget.max == null || widget.value < widget.max!);
    final canDown = live && (widget.min == null || widget.value > widget.min!);
    final style = (small ? t.caption1 : t.body1).c(
      live ? c.neutralForeground1 : c.neutralForegroundDisabled,
    );
    final editor = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _by(1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _by(-1),
        const SingleActivator(LogicalKeyboardKey.pageUp): () => _by(10),
        const SingleActivator(LogicalKeyboardKey.pageDown): () => _by(-10),
      },
      child: Semantics(
        label: widget.label ?? scope?.label,
        increasedValue: canUp ? _say(_clamp(widget.value + widget.step)) : null,
        decreasedValue: canDown
            ? _say(_clamp(widget.value - widget.step))
            : null,
        onIncrease: canUp ? () => _by(1) : null,
        onDecrease: canDown ? () => _by(-1) : null,
        child: Fluent2FieldEditor(
          autofocus: widget.autofocus,
          controller: _text,
          focusNode: _focus,
          enabled: live,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onSubmitted: (_) => _commit(),
          style: style,
        ),
      ),
    );
    final h = small ? 24.0 : 32.0;
    // Fluent's SpinButton draws its border in an overlay over the root's
    // padding (10, small 8), so the words start that far from the edge,
    // the stroke inside it.
    final strokes = Fluent2FieldFrame.strokesOf(widget.appearance);
    // Under a finger the two steppers stand side by side, each a whole
    // target (48) square, and the field grows by the room they add, so the
    // figures keep theirs.
    final touch = Fluent2Layout.padded(context);
    const target = Fluent2Layout.touchHitTarget;
    final up = _Stepper(
      up: true,
      touch: touch,
      appearance: widget.appearance,
      onTap: canUp ? () => _by(1) : null,
    );
    final down = _Stepper(
      up: false,
      touch: touch,
      appearance: widget.appearance,
      onTap: canDown ? () => _by(-1) : null,
    );
    // Asked to take its parent's width, from 600 it stops at 320, its
    // buttons beside it under a finger included.
    final width = widget.width.isInfinite && fluent2Roomy(context)
        ? fluent2ControlMax - (touch ? 2 * target - 24 : 0)
        : widget.width.isInfinite
        ? widget.width
        : MediaQuery.textScalerOf(context).scale(widget.width);
    return SizedBox(
      width: touch ? width + 2 * target - 24 : width,
      child: Fluent2HitSlop(
        child: Fluent2FieldFrame(
          appearance: widget.appearance,
          focused: _focus.hasFocus,
          enabled: live,
          invalid: widget.invalid || (scope?.invalid ?? false),
          textNode: true,
          minHeight: h,
          padding: EdgeInsetsDirectional.only(
            start:
                (small ? Fluent2Spacing.s : Fluent2Spacing.mNudge) -
                strokes.left,
          ),
          child: SizedBox(
            height: touch ? target : math.max(h - strokes.vertical, 0),
            child: Row(
              spacing: Fluent2Spacing.xs,
              children: touch
                  ? [
                      Expanded(child: editor),
                      SizedBox(width: target, child: down),
                      SizedBox(width: target, child: up),
                    ]
                  : [
                      Expanded(child: editor),
                      SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            Expanded(child: up),
                            Expanded(child: down),
                          ],
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One stepper: 24 wide, half the field's height, its chevron 16 drawn
/// toward the field's middle (Fluent's 4 and 1 of room), its corner at the
/// field's end; under a finger ([touch]) a 48 square with its chevron in
/// the middle, the down one before the up one, which holds the end's
/// corners.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.up,
    required this.touch,
    required this.appearance,
    required this.onTap,
  });

  final bool up;
  final bool touch;
  final Fluent2InputAppearance appearance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final r = Radius.circular(
      appearance == Fluent2InputAppearance.underline
          ? 0
          : Fluent2Radius.medium - 1,
    );
    final (hover, pressed) = switch (appearance) {
      Fluent2InputAppearance.filledDarker => (
        c.neutralBackground3Hover,
        c.neutralBackground3Pressed,
      ),
      Fluent2InputAppearance.filledLighter => (
        c.neutralBackground1Hover,
        c.neutralBackground1Pressed,
      ),
      _ => (c.subtleBackgroundHover, c.subtleBackgroundPressed),
    };
    return Fluent2Pressable(
      onPressed: onTap,
      label: up
          ? Fluent2Localizations.of(context).increase
          : Fluent2Localizations.of(context).decrease,
      radius: Fluent2Radius.small,
      builder: (context, states) => Container(
        decoration: BoxDecoration(
          color: states.press.pick(
            c.transparentBackground,
            hover,
            pressed,
            c.transparentBackground,
          ),
          borderRadius: touch
              ? BorderRadiusDirectional.horizontal(end: up ? r : Radius.zero)
              : BorderRadiusDirectional.only(
                  topEnd: up ? r : Radius.zero,
                  bottomEnd: up ? Radius.zero : r,
                ),
        ),
        alignment: touch
            ? Alignment.center
            : up
            ? const Alignment(0, 0.25)
            : const Alignment(0, -0.25),
        child: OverflowBox(
          maxHeight: 16,
          child: Icon(
            up ? Fluent2Icons.chevronUp16 : Fluent2Icons.chevronDown16,
            size: 16,
            color: states.press.pick(
              c.neutralForeground3,
              c.neutralForeground3Hover,
              c.neutralForeground3Pressed,
              c.neutralForegroundDisabled,
            ),
          ),
        ),
      ),
    );
  }
}
