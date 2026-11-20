/// Choosing: `[x]` a checkbox, `(•)` a radio, `[ ■]` a switch, each with
/// its label on the same line.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../internal/pointer.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../primitives/spring.dart';
import '../style.dart';
import '../theme.dart';

/// The face of a choice: three cells (bracket, mark, bracket) then, with a
/// label, a space and the words. Shared by the checkbox and the radio.
///
/// An error is a `✗` in the danger ink a cell after the words (after the
/// box, without them), and the brackets in the danger ink while the choice
/// can still be changed. The `✗` stays when the choice is disabled, its
/// brackets and words gone dim, so a locked box still says what is wrong
/// with it. A screen reader hears the error from the control's state.
class _ChoiceFace extends StatelessWidget {
  const _ChoiceFace({
    required this.shape,
    required this.states,
    required this.mark,
    required this.label,
    required this.style,
    required this.themed,
  });

  final TermBracketShape shape;
  final Set<WidgetState> states;
  final Widget Function(TermThemeData theme, TermGrid grid, Color ink) mark;
  final String? label;
  final TermStyle? style;
  final TermStyle? themed;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final stroke = termStroke(theme, grid);
    final disabled = states.contains(WidgetState.disabled);
    final error = states.contains(WidgetState.error);
    final own = TermStyleOf([style, themed], states);
    return TermStateSprings(
      pressed: states.contains(WidgetState.pressed),
      focused: states.contains(WidgetState.focused),
      builder: (context, press, focus) {
        final brackets = disabled
            ? theme.rule.withValues(alpha: 0.6)
            : error
            ? theme.danger
            : termHoverInk(theme, theme.rule, states);
        final cursor = disabled ? 0.0 : focus;
        final ink = disabled
            ? theme.rule
            : termCursorInk(
                theme,
                Color.lerp(theme.accent, theme.background, press)!,
                cursor,
              );
        final box = CustomPaint(
          painter: TermBracketPainter(
            grid: grid,
            color: own.edge ?? brackets,
            stroke: stroke,
            fill: own.fill ?? (disabled ? null : theme.foreground),
            fillAmount: press,
            shape: shape,
            cursor: cursor,
            cursorColor: theme.accent,
            knockout: theme.onAccent,
          ),
          child: SizedBox(
            width: grid.cols(3),
            height: grid.lineHeight,
            child: Center(child: mark(theme, grid, ink)),
          ),
        );
        // Ordinary cells after the rest, outside the cursor: the danger ink
        // on the ground reads under any state.
        final wrong = <Widget>[
          if (error) ...[
            SizedBox(width: grid.cellWidth),
            ExcludeSemantics(
              child: Text(
                '✗',
                style: theme.textStyle.copyWith(color: theme.danger),
              ),
            ),
          ],
        ];
        if (label == null) {
          return wrong.isEmpty
              ? box
              : Row(mainAxisSize: MainAxisSize.min, children: [box, ...wrong]);
        }
        // The cursor takes the whole line, the label with the box, as a
        // terminal's selection does.
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            box,
            Flexible(
              child: TermCursorSpan(
                focus: cursor,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: grid.cellWidth),
                    Flexible(
                      child: Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: theme.textStyle
                            .merge(own.textStyle)
                            .copyWith(
                              color: termCursorInk(
                                theme,
                                own.foreground ??
                                    (disabled ? theme.rule : theme.foreground),
                                cursor,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...wrong,
          ],
        );
      },
    );
  }
}

/// A checkbox, `[x]`, with its [label] after it on the same line when given
/// (the whole line is then its target, as a terminal's form toggles one).
///
/// [value] true draws `x` in the accent, false nothing, null (with
/// [tristate]) `-`. The mark springs in and out; a press fills the box in
/// inverse video; the keyboard's focus is the cursor over the line, the
/// box's brackets and mark and the label cut out of it; under the pointer
/// the brackets take the accent. [onChanged] null disables it.
///
/// ```dart
/// TermCheckbox(
///   value: autoMerge,
///   label: 'merge when checks pass',
///   onChanged: (value) => setState(() => autoMerge = value!),
/// )
/// ```
///
/// Reads [TermStyle]'s `fill` (the press), `foreground` (the label), `edge`
/// (the brackets) and `textStyle`.
class TermCheckbox extends StatelessWidget {
  /// A checkbox showing [value].
  const TermCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.tristate = false,
    this.isError = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(tristate || value != null);

  /// Checked, unchecked, or (with [tristate]) mixed.
  final bool? value;

  /// Called with the next value; null disables the checkbox.
  final ValueChanged<bool?>? onChanged;

  /// The words after the box, or null for the box alone.
  final String? label;

  /// What a screen reader calls it in place of [label]: for a control
  /// whose words stand elsewhere on the line, such as a config file's key.
  final String? semanticLabel;

  /// Whether null is a value (mixed).
  final bool tristate;

  /// Whether it shows an error (a required box left empty): a `✗` in the
  /// danger ink after it, and its brackets in that ink while it is enabled.
  final bool isError;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Overrides, over the theme's [TermThemeData.checkboxStyle]: `fill`
  /// (the mark), `edge` (the brackets), `foreground` and `textStyle` (the
  /// label's colour and weight).
  final TermStyle? style;

  void _toggle() {
    final next = switch (value) {
      false => true,
      true => tristate ? null : false,
      null => false,
    };
    onChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final mark = switch (value) {
      true => 'x',
      false => '',
      null => '-',
    };
    return TermTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: DesignPressable(
        onPressed: onChanged == null ? null : _toggle,
        focusNode: focusNode,
        autofocus: autofocus,
        isError: isError,
        checked: value ?? false,
        mixed: value == null,
        semanticLabel: semanticLabel ?? label,
        button: false,
        excludeSemantics: true,
        mouseCursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) => _ChoiceFace(
          shape: TermBracketShape.square,
          states: states,
          label: label,
          style: style,
          themed: TermTheme.of(context).checkboxStyle,
          mark: (theme, grid, ink) => TermSpring(
            target: value == false ? 0 : 1,
            token: TermMotion.press,
            builder: (context, t, _) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.scale(
                scale: 0.6 + 0.4 * t.clamp(0, 1),
                child: Text(
                  mark.isEmpty ? 'x' : mark,
                  style: theme.boldStyle.copyWith(color: ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('value', value))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      )
      ..add(FlagProperty('tristate', value: tristate, ifTrue: 'tristate'))
      ..add(FlagProperty('isError', value: isError, ifTrue: 'error'));
  }
}

/// A radio button, `(•)`, one of a group sharing [groupValue], with its
/// [label] after it on the same line when given. Under the pointer its
/// brackets take the accent; the keyboard's focus is the cursor.
///
/// ```dart
/// TermRadio<String>(
///   value: 'production',
///   groupValue: environment,
///   label: 'production',
///   onChanged: (value) => setState(() => environment = value!),
/// )
/// ```
///
/// Reads [TermStyle]'s `fill`, `foreground`, `edge` and `textStyle`, as
/// [TermCheckbox] does.
class TermRadio<T> extends StatelessWidget {
  /// The radio for [value] in the group at [groupValue].
  const TermRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The value this radio stands for.
  final T value;

  /// The group's value: this radio is chosen when it equals [value].
  final T? groupValue;

  /// Called with [value] when chosen; null disables it.
  final ValueChanged<T?>? onChanged;

  /// The words after the radio, or null.
  final String? label;

  /// What a screen reader calls it in place of [label]: for a control
  /// whose words stand elsewhere on the line, such as a config file's key.
  final String? semanticLabel;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Overrides, over the theme's [TermThemeData.radioStyle]: `fill` (the
  /// dot), `edge` (the round brackets), `foreground` and `textStyle` (the
  /// label's colour and weight).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final chosen = value == groupValue;
    return TermTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: DesignPressable(
        onPressed: onChanged == null ? null : () => onChanged!(value),
        focusNode: focusNode,
        autofocus: autofocus,
        checked: chosen,
        inMutuallyExclusiveGroup: true,
        semanticLabel: semanticLabel ?? label,
        button: false,
        excludeSemantics: true,
        mouseCursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) => _ChoiceFace(
          shape: TermBracketShape.round,
          states: states,
          label: label,
          style: style,
          themed: TermTheme.of(context).radioStyle,
          mark: (theme, grid, ink) => TermSpring(
            target: chosen ? 1 : 0,
            token: TermMotion.press,
            builder: (context, t, _) => CustomPaint(
              size: Size.square(grid.cellWidth),
              painter: _Dot(color: ink, amount: t.clamp(0, 1)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(DiagnosticsProperty<T>('groupValue', groupValue))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _Dot extends CustomPainter {
  const _Dot({required this.color, required this.amount});

  final Color color;
  final double amount;

  @override
  void paint(Canvas canvas, Size size) {
    if (amount <= 0) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.width * 0.32 * amount,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Dot old) => old.color != color || old.amount != amount;
}

/// A switch, `[■ ]` off and `[ ■]` on: a block that slides between the two
/// cells inside its brackets, dim at the start when off and in the accent at
/// the end when on, so it reads without colour. With a [label], the words
/// follow it on the line. Under the pointer its brackets take the accent.
///
/// ```dart
/// TermSwitch(
///   value: notify,
///   label: 'notify on failure',
///   onChanged: (value) => setState(() => notify = value),
/// )
/// ```
///
/// Reads [TermStyle]'s `fill` (the block), `foreground` (the label), `edge`
/// (the brackets) and `textStyle`.
class TermSwitch extends StatelessWidget {
  /// A switch showing [value].
  const TermSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// On or off.
  final bool value;

  /// Called with the next value; null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// The words after the switch, or null for the switch alone.
  final String? label;

  /// What a screen reader calls it in place of [label]: for a control
  /// whose words stand elsewhere on the line, such as a config file's key.
  final String? semanticLabel;

  /// {@macro term.focusNode}
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Overrides, over the theme's [TermThemeData.switchStyle]: `fill` (the
  /// on side), `edge` (the brackets), `foreground` and `textStyle` (the
  /// label's colour and weight).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    return TermTapTarget(
      alignment: AlignmentDirectional.centerStart,
      child: DesignPressable(
        onPressed: onChanged == null ? null : () => onChanged!(!value),
        focusNode: focusNode,
        autofocus: autofocus,
        toggled: value,
        semanticLabel: semanticLabel ?? label,
        button: false,
        excludeSemantics: true,
        mouseCursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states, _) {
          final theme = TermTheme.of(context);
          final grid = context.termGrid;
          final stroke = termStroke(theme, grid);
          final disabled = states.contains(WidgetState.disabled);
          final own = TermStyleOf([style, theme.switchStyle], states);
          final direction = Directionality.of(context);
          return TermStateSprings(
            pressed: states.contains(WidgetState.pressed),
            focused: states.contains(WidgetState.focused),
            builder: (context, press, focus) => TermSpring(
              target: value ? 1 : 0,
              token: TermMotion.move,
              spatial: true,
              builder: (context, t, _) {
                final block =
                    own.fill ??
                    (disabled
                        ? theme.rule.withValues(alpha: 0.5)
                        : Color.lerp(theme.rule, theme.accent, t.clamp(0, 1))!);
                final cursor = disabled ? 0.0 : focus;
                final face = CustomPaint(
                  painter: TermBracketPainter(
                    grid: grid,
                    color:
                        own.edge ??
                        (disabled
                            ? theme.rule.withValues(alpha: 0.6)
                            : termHoverInk(theme, theme.rule, states)),
                    stroke: stroke,
                    cursor: cursor,
                    cursorColor: theme.accent,
                    knockout: theme.onAccent,
                  ),
                  foregroundPainter: _Thumb(
                    grid: grid,
                    at: t,
                    // Held, the block lights towards the words' ink; under
                    // the cursor, block and track are cut out of it.
                    color: termCursorInk(
                      theme,
                      own.fill != null || disabled
                          ? block
                          : Color.lerp(block, theme.foreground, press * 0.6)!,
                      cursor,
                    ),
                    track: termCursorInk(theme, theme.rule, cursor),
                    press: press,
                    direction: direction,
                  ),
                  child: SizedBox(width: grid.cols(4), height: grid.lineHeight),
                );
                if (label == null) return face;
                // The cursor takes the whole line, the label with the
                // switch.
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    face,
                    Flexible(
                      child: TermCursorSpan(
                        focus: cursor,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: grid.cellWidth),
                            Flexible(
                              child: Text(
                                label!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: theme.textStyle
                                    .merge(own.textStyle)
                                    .copyWith(
                                      color: termCursorInk(
                                        theme,
                                        own.foreground ??
                                            (disabled
                                                ? theme.rule
                                                : theme.foreground),
                                        cursor,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'on', ifFalse: 'off'))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _Thumb extends CustomPainter {
  const _Thumb({
    required this.grid,
    required this.at,
    required this.color,
    required this.track,
    required this.press,
    required this.direction,
  });

  final TermGrid grid;
  final double at;
  final Color color;
  final Color track;
  final double press;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    // The block caret's size: a full cell wide, 1.25 em tall.
    final h = grid.fontSize * (1.25 - 0.15 * press);
    final cy = size.height / 2;
    // The two inner cells; the block slides from the first to the second.
    final from = cw;
    final to = cw * 2;
    var x = from + (to - from) * at;
    if (direction == TextDirection.rtl) x = size.width - x - cw;
    // A dot in the cell the block is not in, so the empty side still reads.
    final dotX = direction == TextDirection.rtl
        ? (at < 0.5 ? cw * 1.5 : cw * 2.5)
        : (at < 0.5 ? cw * 2.5 : cw * 1.5);
    canvas
      ..drawCircle(Offset(dotX, cy), 1.5, Paint()..color = track)
      ..drawRect(Rect.fromLTWH(x, cy - h / 2, cw, h), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Thumb old) =>
      old.at != at ||
      old.color != color ||
      old.track != track ||
      old.press != press ||
      old.grid != grid ||
      old.direction != direction;
}
