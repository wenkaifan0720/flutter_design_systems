import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// Where a control's label stands, Fluent's `labelPosition`: a checkbox
/// takes [before] or [after], a switch [before], [after] or [above], a
/// radio [after] or [below].
enum Fluent2LabelPosition {
  /// The label before the control.
  before,

  /// The label after the control.
  after,

  /// The label above the control.
  above,

  /// The label below the control.
  below,
}

/// A checkbox's indicator, Fluent's `shape`: [square] at 2, [circular] a
/// disc.
enum Fluent2CheckboxShape {
  /// A square box.
  square,

  /// A circular box.
  circular,
}

/// A checkbox's size, Fluent's `size`: [medium] a 16 box with its 12
/// check, [large] a 20 box with its 16 check.
enum Fluent2CheckboxSize {
  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// Fluent's checkbox indicator in [press]: the box (16 or 20, 1 stroke,
/// corner 2 or a disc) with its check or mixed mark. Plumbing.
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.value,
    required this.press,
    required this.shape,
    required this.size,
    this.look,
  });

  final bool? value;
  final Fluent2Press press;
  final Fluent2CheckboxShape shape;
  final Fluent2CheckboxSize size;

  /// The style and checkbox theme in the box's states.
  final Fluent2StyleOf? look;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final large = size == Fluent2CheckboxSize.large;
    final side = look?.minimumSize?.shortestSide ?? (large ? 20.0 : 16.0);
    final glyph = look?.iconSize ?? (large ? 16.0 : 12.0);
    final off = press == Fluent2Press.disabled;
    final Color fill;
    final Color stroke;
    final Color ink;
    if (value == true) {
      fill = press.pick(
        c.compoundBrandBackground,
        c.compoundBrandBackgroundHover,
        c.compoundBrandBackgroundPressed,
        c.transparentBackground,
      );
      stroke = off ? fluent2Step(t, c.neutralStrokeDisabled) : fill;
      ink = off ? c.neutralForegroundDisabled : c.neutralForegroundInverted;
    } else if (value == null) {
      fill = c.transparentBackground;
      stroke = press.pick(
        c.compoundBrandStroke,
        c.compoundBrandStrokeHover,
        c.compoundBrandStrokePressed,
        fluent2Step(t, c.neutralStrokeDisabled),
      );
      ink = press.pick(
        c.compoundBrandForeground1,
        c.compoundBrandForeground1Hover,
        c.compoundBrandForeground1Pressed,
        c.neutralForegroundDisabled,
      );
    } else {
      fill = c.transparentBackground;
      stroke = press.pick(
        c.neutralStrokeAccessible,
        c.neutralStrokeAccessibleHover,
        c.neutralStrokeAccessiblePressed,
        fluent2Step(t, c.neutralStrokeDisabled),
      );
      ink = c.transparentBackground;
    }
    return fluent2EasedInks([fill, stroke, ink], (context, inks) {
      final [fill, stroke, ink] = inks;
      final circular = shape == Fluent2CheckboxShape.circular;
      final styled = look?.shape;
      final boxFill = look?.fill ?? fill;
      final mine = look?.foreground ?? ink;
      final rim =
          look?.side ??
          BorderSide(color: look?.edge ?? stroke, width: Fluent2Stroke.thin);
      // Fluent's small corner, kept to a quarter of the box.
      final corner = Fluent2Radius.small.clamp(0, side / 4).toDouble();
      final Widget? mark = switch (value) {
        true => Icon(
          large
              ? Fluent2Icons.checkmark16Filled
              : Fluent2Icons.checkmark12Filled,
          size: glyph,
          color: mine,
        ),
        // Fluent's Square12Filled (8 square, corner 1.5) or Square16Filled
        // (12, corner 2.5); a circular box takes CircleFilled at the glyph
        // size (a disc 0.8 of it).
        null => Container(
          width: circular ? glyph * 0.8 : (large ? 12 : 8),
          height: circular ? glyph * 0.8 : (large ? 12 : 8),
          decoration: BoxDecoration(
            color: mine,
            borderRadius: circular
                ? null
                : BorderRadius.circular(large ? 2.5 : 1.5),
            shape: circular ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        false => null,
      };
      return Container(
        width: side,
        height: side,
        alignment: Alignment.center,
        decoration: styled != null
            ? ShapeDecoration(
                color: boxFill,
                shape: styled.copyWith(side: rim),
              )
            : BoxDecoration(
                color: boxFill,
                border: Border.all(color: rim.color, width: rim.width),
                borderRadius: circular ? null : BorderRadius.circular(corner),
                shape: circular ? BoxShape.circle : BoxShape.rectangle,
              ),
        child: mark,
      );
    });
  }
}

/// Fluent 2's Checkbox: the box (16, its corner 2; [Fluent2CheckboxShape
/// .circular] a disc; [Fluent2CheckboxSize.large] 20) 8 in from its edges,
/// its [label] 4 beside it in body1, the whole row one checkbox. Unchecked
/// it is the accessible stroke with the label in the third ink; checked
/// the brand fill (`compoundBrandBackground`) with the white check and the
/// label in the first ink; a null [value] is mixed, the brand stroke round
/// the brand square. A press, or Space, asks [onChanged] for the other
/// state (mixed goes to checked); null [onChanged] draws it disabled.
///
/// [style] restyles the box over `Fluent2ThemeData.checkboxTheme`, in its
/// states (selected while checked, hovered, pressed, disabled): `fill`,
/// `foreground` (the mark), `edge`, `side`, `shape`, `minimumSize` (the
/// box's side), `iconSize` (the mark's) and `textStyle` (the label's). The
/// box takes Fluent's small corner, at most a quarter of its side.
///
/// ```dart
/// Fluent2Checkbox(value: notify, label: 'Email me when files change', onChanged: (v) => setState(() => notify = v))
/// ```
class Fluent2Checkbox extends StatelessWidget {
  /// A check box holding [value].
  const Fluent2Checkbox({
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.shape = Fluent2CheckboxShape.square,
    this.size = Fluent2CheckboxSize.medium,
    this.labelPosition = Fluent2LabelPosition.after,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         label != null || semanticLabel != null,
         'a checkbox is named: give it a label or a semanticLabel',
       ),
       assert(
         labelPosition == Fluent2LabelPosition.before ||
             labelPosition == Fluent2LabelPosition.after,
         "a checkbox's label stands before or after its box, as Fluent's "
         'does; a switch takes above',
       );

  /// Checked, unchecked, or null for mixed.
  final bool? value;

  /// Called with the new state when the user changes it; null puts it out of
  /// use.
  final ValueChanged<bool>? onChanged;

  /// The words beside the box.
  final String? label;

  /// What a screen reader says; null says [label].
  final String? semanticLabel;

  /// Fluent's `shape`: square or circular.
  final Fluent2CheckboxShape shape;

  /// Fluent's `size`: medium or large.
  final Fluent2CheckboxSize size;

  /// [Fluent2LabelPosition.before] or [Fluent2LabelPosition.after]
  /// (Fluent's checkbox has no other; above and below are refused).
  final Fluent2LabelPosition labelPosition;

  /// This box's own look, slot by slot, over the checkbox theme.
  final Fluent2Style? style;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final layers = [style, t.checkboxTheme];
    final change = onChanged;
    final tap = change == null ? null : () => change(value != true);
    final large = size == Fluent2CheckboxSize.large;
    final words = label;
    final before = labelPosition == Fluent2LabelPosition.before;
    // The press's node stands at the control's root, its one node.
    return MergeSemantics(
      child: Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: tap,
          radius: Fluent2Radius.medium,
          label: semanticLabel ?? words,
          checked: value ?? false,
          mixed: value == null,
          builder: (context, states) {
            final press = states.press;
            final ink = value != false
                ? (press == Fluent2Press.disabled
                      ? c.neutralForegroundDisabled
                      : c.neutralForeground1)
                : press.pick(
                    c.neutralForeground3,
                    c.neutralForeground2,
                    c.neutralForeground1,
                    c.neutralForegroundDisabled,
                  );
            return fluent2EasedInks([ink], (context, inks) {
              final [ink] = inks;
              final look = Fluent2StyleOf(layers, states);
              final box = Padding(
                padding: const EdgeInsets.all(Fluent2Spacing.s),
                child: _Indicator(
                  value: value,
                  press: press,
                  shape: shape,
                  size: size,
                  look: look,
                ),
              );
              if (words == null) return box;
              // The label: 8 round, 4 on the box's side, its 20 line drawn
              // into the box's 8 above and under (Fluent's negative margin).
              final lift = (large ? 20 : 16) - 20;
              // The words lead on the keyline when they come first; the box
              // leads on it when it does, its room hanging outside.
              final type = t.body1.merge(look.textStyle);
              final text = Flexible(
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    before ? 0 : Fluent2Spacing.xs,
                    Fluent2Spacing.s + lift / 2,
                    before ? Fluent2Spacing.xs : Fluent2Spacing.s,
                    Fluent2Spacing.s + lift / 2,
                  ),
                  child: Text(words, style: type.c(ink)),
                ),
              );
              final mark = fluent2OnFirstLine(context, type, box);
              final row = Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: before ? [text, mark] : [mark, text],
              );
              return before ? row : Fluent2HangRoom(child: row);
            });
          },
        ),
      ),
    );
  }
}

/// A task's done mark drawn as Fluent's circular checkbox at its large
/// size: a 20 ring in the accessible stroke while open, the brand disc
/// with the white check once [done]. A press or Space asks [onChanged] for
/// the other state; with no [onChanged] it is disabled, inert in the
/// disabled inks; [readOnly] makes it a mark that only reports (drawn at
/// full strength, not a control).
/// [label] names the task to a screen reader. Its target is 44.
///
/// ```dart
/// Fluent2CompletionCheck(value: task.done, label: 'Review the launch deck', onChanged: (v) => setState(() => task.done = v))
/// ```
class Fluent2CompletionCheck extends StatelessWidget {
  /// A task's done mark holding [value].
  const Fluent2CompletionCheck({
    required this.value,
    required this.label,
    this.onChanged,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Whether the task is done.
  final bool value;

  /// The task it marks, as a screen reader names it.
  final String label;

  /// Asked for the other state; null disables it.
  final ValueChanged<bool>? onChanged;

  /// A mark that only reports: drawn at full strength, no press, as
  /// [EditableText.readOnly] shows its text.
  final bool readOnly;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final change = readOnly ? null : onChanged;
    final tap = change == null ? null : () => change(!value);
    Widget face(Fluent2Press press) => Padding(
      padding: const EdgeInsets.all(Fluent2Spacing.xxs),
      child: _Indicator(
        value: value,
        press: press,
        shape: Fluent2CheckboxShape.circular,
        size: Fluent2CheckboxSize.large,
      ),
    );
    // A mark that only reports is no control: one node that says it, no press.
    // It stands the room a live one's target takes under a finger, so a list
    // of tasks keeps one column of marks.
    if (readOnly) {
      final room = Fluent2Layout.padded(context)
          ? Fluent2Layout.hitTargetOf(context)
          : 0.0;
      return Semantics(
        container: true,
        excludeSemantics: true,
        checked: value,
        label: label,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: room, minHeight: room),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: face(Fluent2Press.rest),
          ),
        ),
      );
    }
    return MergeSemantics(
      child: Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: tap,
          radius: Fluent2Radius.circular,
          label: label,
          checked: value,
          builder: (context, states) => face(states.press),
        ),
      ),
    );
  }
}
