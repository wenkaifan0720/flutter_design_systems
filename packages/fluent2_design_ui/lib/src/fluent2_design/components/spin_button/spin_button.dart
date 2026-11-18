import '../../internal/well.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/measure.dart';
import '../../theme.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';

/// Fluent 2's SpinButton: a number in a field 32 tall (24 small), 10 in
/// at its start, and at its end the two 24 wide steppers stacked, the
/// up and down chevrons (16) in the third ink on a subtle fill under the
/// pointer; each moves [value] to the next multiple of [step] within [min]
/// and [max] (the one at a bound is disabled), repeating while held, as do
/// the up and down arrow keys (Page Up and Down by ten steps); figures typed
/// in the reader's digits are taken on Enter (the field keeps the focus) or
/// when the field lets go of it, and text that is no number puts the last
/// value back. [format] says the value in the field while it rests (the
/// number at [step]'s precision by default); editing, it shows the number.
/// [onChanged] gets each value; null draws it disabled. Read as an
/// adjustable field named [label]. It is ui_core's `DesignNumberField` in
/// Fluent's field and steppers.
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
    this.style,
    super.key,
  }) : assert(
         size != Fluent2InputSize.large,
         "Fluent's SpinButton is small or medium",
       );

  /// This field's own look, slot by slot, over the text field theme
  /// ([Fluent2ThemeData.textFieldTheme]): the slots [Fluent2FieldFrame]
  /// names.
  final Fluent2Style? style;

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

  /// {@macro fluent2.appearance}
  final Fluent2InputAppearance appearance;

  /// {@macro fluent2.invalid}
  final bool invalid;

  /// The field's width at the default text size, growing with the reader's
  /// text size so its value is never cut; `double.infinity` takes the
  /// parent's.
  final double width;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  State<Fluent2SpinButton> createState() => _Fluent2SpinButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
    );
    properties
      ..add(DiagnosticsProperty<num>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<num>?>.has('onChanged', onChanged))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DiagnosticsProperty<num>('min', min, defaultValue: null))
      ..add(DiagnosticsProperty<num>('max', max, defaultValue: null))
      ..add(DiagnosticsProperty<num>('step', step, defaultValue: 1))
      ..add(
        ObjectFlagProperty<String Function(num value)?>.has('format', format),
      )
      ..add(
        EnumProperty<Fluent2InputSize>(
          'size',
          size,
          defaultValue: Fluent2InputSize.medium,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2InputAppearance.outline,
        ),
      )
      ..add(FlagProperty('invalid', value: invalid, ifTrue: 'invalid'))
      ..add(DoubleProperty('width', width, defaultValue: 120))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _Fluent2SpinButtonState extends State<Fluent2SpinButton> {
  // A whole value stepped by whole steps answers a whole number.
  num _out(double v) =>
      widget.value is int && widget.step is int && v == v.roundToDouble()
      ? v.round()
      : v;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final scope = Fluent2FieldScope.maybeOf(context);
    final change = widget.onChanged;
    final live = change != null;
    final small = widget.size == Fluent2InputSize.small;
    final format = widget.format;
    final style = (small ? t.caption1 : t.body1).c(
      live ? c.neutralForeground1 : c.neutralForegroundDisabled,
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
    // Asked to take its parent's width, from 600 it stops at 320, its
    // buttons beside it under a finger included.
    final width = widget.width.isInfinite && fluent2Roomy(context)
        ? fluent2ControlMax - (touch ? 2 * target - 24 : 0)
        : widget.width.isInfinite
        ? widget.width
        : MediaQuery.textScalerOf(context).scale(widget.width);
    // The field's states, for the frame round it, and its words.
    var states = const <WidgetState>{};
    var words = '';
    return DesignNumberField(
      value: widget.value.toDouble(),
      onChanged: !live
          ? null
          : (v) {
              // Cleared, the field shows the value again.
              if (v == null) return setState(() {});
              final next = _out(v);
              if (next != widget.value) change(next);
            },
      min: widget.min?.toDouble(),
      max: widget.max?.toDouble(),
      step: widget.step.toDouble(),
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      semanticLabel: widget.label ?? scope?.label,
      semanticFormatterCallback: format == null ? null : (v) => format(_out(v)),
      fieldBuilder: (context, field) {
        states = field.states;
        words = field.controller.text;
        final editor = Fluent2FieldEditor(
          controller: field.controller,
          focusNode: field.focusNode,
          enabled: live,
          keyboardType: field.keyboardType,
          inputFormatters: field.inputFormatters,
          // Enter takes the typed value and, as Fluent's text fields do,
          // gives up the focus (a phone's keyboard closes); ui_core's keeps
          // it.
          onEditingComplete: () {
            field.onEditingComplete();
            field.focusNode.unfocus();
          },
          style: style,
        );
        if (format == null || states.contains(WidgetState.focused)) {
          return editor;
        }
        // At rest the field says the value [format]'s way over the number,
        // which a screen reader still reads.
        return Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Opacity(opacity: 0, alwaysIncludeSemantics: true, child: editor),
            IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  format(widget.value),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: style,
                ),
              ),
            ),
          ],
        );
      },
      buttonBuilder: (context, button) => _Stepper(
        up: button.isIncrement,
        touch: touch,
        appearance: widget.appearance,
        states: button.states,
      ),
      // ui_core's node steps the value: it says the value too. A Material
      // text field and that node both say whether they are enabled, which
      // Flutter will not merge, so the field stands in a node of its own
      // under it.
      layoutBuilder: (context, field, down, up) => Semantics(
        // At rest, [format]'s words, as its next values say theirs.
        value:
            words.isEmpty ||
                format == null ||
                states.contains(WidgetState.focused)
            ? words
            : format(widget.value),
        child: SizedBox(
          width: touch ? width + 2 * target - 24 : width,
          child: Fluent2FieldFrame(
            appearance: widget.appearance,
            style: widget.style,
            focused: states.contains(WidgetState.focused),
            enabled: live,
            invalid:
                widget.invalid ||
                (scope?.invalid ?? false) ||
                states.contains(WidgetState.error),
            // The field's words, flags and editing in one node the frame's
            // size, as a text field's (under ui_core's node, which steps).
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
                        Expanded(child: field),
                        SizedBox(width: target, child: down),
                        SizedBox(width: target, child: up),
                      ]
                    : [
                        Expanded(child: field),
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
      ),
    );
  }
}

/// A stepper's face in the states ui_core's step button reports (it is no
/// tab stop and no node: the field itself steps).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.up,
    required this.touch,
    required this.appearance,
    required this.states,
  });

  final bool up;
  final bool touch;
  final Fluent2InputAppearance appearance;
  final Set<WidgetState> states;

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
      _ => (c.subtleBackgroundHover, fluent2Step(t, c.subtleBackgroundPressed)),
    };
    return MouseRegion(
      cursor: states.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: Container(
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
