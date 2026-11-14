import 'package:flutter/widgets.dart';

import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/in_row.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../checkbox/checkbox.dart' show Fluent2LabelPosition;
import '../pressable/pressable.dart';

/// A switch's size, Fluent's `size`: [medium] a 40 by 20 track, [small]
/// 32 by 16 with its label in caption1.
enum Fluent2SwitchSize {
  /// The medium size.
  medium,

  /// The small size.
  small,
}

/// Fluent 2's Switch: a 40 by 20 track (32 by 16 small) 8 in from its
/// edges, its 14 thumb 3 inside the stroke, and its [label] 4 beside it in
/// body1, the whole row one switch. Off, the accessible stroke and thumb;
/// on, the brand fill (`compoundBrandBackground`) with the white thumb at
/// its end, sliding over `durationNormal`. A press or Space asks
/// [onChanged] for the other state; null [onChanged] draws it disabled.
///
/// [style] restyles the track over `Fluent2ThemeData.switchTheme`, in its
/// states (selected while on, hovered, pressed, disabled): `fill` (the
/// track), `foreground` (the thumb), `edge`, `side`, `shape` (the track's
/// outline; the thumb follows it), `minimumSize` (the track's size) and
/// `textStyle` (the label's). The track is a pill unless `shape` says
/// otherwise, and the thumb rounds in step.
///
/// ```dart
/// Fluent2Switch(value: away, label: 'Show me as away', onChanged: (v) => setState(() => away = v))
/// ```
class Fluent2Switch extends StatelessWidget {
  /// A switch holding [value].
  const Fluent2Switch({
    required this.value,
    required this.onChanged,
    this.label,
    this.semanticLabel,
    this.labelPosition = Fluent2LabelPosition.after,
    this.size = Fluent2SwitchSize.medium,
    this.style,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         label != null || semanticLabel != null,
         'a switch is named: give it a label or a semanticLabel',
       );

  /// Whether it is on.
  final bool value;

  /// Called with the new state when the user flips it; null puts it out of use.
  final ValueChanged<bool>? onChanged;

  /// The switch's label, shown and spoken; null shows none.
  final String? label;

  /// What a screen reader says; null says [label].
  final String? semanticLabel;

  /// [Fluent2LabelPosition.after], [Fluent2LabelPosition.before] or
  /// [Fluent2LabelPosition.above].
  final Fluent2LabelPosition labelPosition;

  /// Fluent's `size`: medium or small.
  final Fluent2SwitchSize size;

  /// This switch's own look, slot by slot, over the switch theme.
  final Fluent2Style? style;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final layers = [style, t.switchTheme];
    final change = onChanged;
    final tap = change == null ? null : () => change(!value);
    final small = size == Fluent2SwitchSize.small;
    final words = label;
    // The press's node stands at the switch's root, its one node.
    return MergeSemantics(
      child: Fluent2HitSlop(
        child: Fluent2Pressable(
          focusNode: focusNode,
          autofocus: autofocus,
          onPressed: tap,
          radius: Fluent2Radius.medium,
          label: semanticLabel ?? words,
          toggled: value,
          builder: (context, states) {
            final press = states.press;
            final off = press == Fluent2Press.disabled;
            final look = Fluent2StyleOf(layers, states);
            final track = _Track(
              value: value,
              press: press,
              small: small,
              look: look,
            );
            final type = (small ? t.caption1 : t.body1).merge(look.textStyle);
            final ink = off
                ? c.neutralForegroundDisabled
                : c.neutralForeground1;
            if (words == null) {
              // Alone it keeps 8 round its track; at a list row's end the
              // row's own room stands there instead.
              return Padding(
                padding: Fluent2InRow.of(context)
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(Fluent2Spacing.s),
                child: track,
              );
            }
            switch (labelPosition) {
              case Fluent2LabelPosition.above:
                // The label's words and the track on the keyline, the room
                // round them hanging outside.
                return Fluent2HangRoom(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Fluent2Spacing.s,
                          vertical: Fluent2Spacing.xs,
                        ),
                        child: Text(words, style: type.c(ink)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Fluent2Spacing.s,
                          0,
                          Fluent2Spacing.s,
                          Fluent2Spacing.s,
                        ),
                        child: track,
                      ),
                    ],
                  ),
                );
              case Fluent2LabelPosition.before:
              case Fluent2LabelPosition.after:
              case Fluent2LabelPosition.below:
                final before = labelPosition == Fluent2LabelPosition.before;
                // The words lead on the keyline when they come first; the
                // track leads on it when it does, its room hanging outside.
                final text = Flexible(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      before ? 0 : Fluent2Spacing.xs,
                      Fluent2Spacing.s,
                      before ? Fluent2Spacing.xs : Fluent2Spacing.s,
                      Fluent2Spacing.s,
                    ),
                    child: Text(words, style: type.c(ink)),
                  ),
                );
                final box = fluent2OnFirstLine(
                  context,
                  type,
                  Padding(
                    padding: const EdgeInsets.all(Fluent2Spacing.s),
                    child: track,
                  ),
                );
                final row = Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: before ? [text, box] : [box, text],
                );
                return before ? row : Fluent2HangRoom(child: row);
            }
          },
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.value,
    required this.press,
    required this.small,
    required this.look,
  });

  final bool value;
  final Fluent2Press press;
  final bool small;
  final Fluent2StyleOf look;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final off = press == Fluent2Press.disabled;
    // Fluent: the track 40 by 20 (32 by 16), the thumb CircleFilled at the
    // track's height less 2 (a disc 0.8 of that: 14, 11), sliding by the
    // width less the thumb's box less 2.
    final width = look.minimumSize?.width ?? (small ? 32.0 : 40.0);
    final height = look.minimumSize?.height ?? (small ? 16.0 : 20.0);
    final box = height - 2;
    final thumb = (box * 0.8).roundToDouble();
    final Color fill;
    final Color stroke;
    final Color knob;
    if (value) {
      // Out of use, Fluent's disabled grey laid over the ground, so the
      // track stays a track on the tinted page.
      fill = off
          ? fluent2WellDisabled(t)
          : press.pick(
              c.compoundBrandBackground,
              c.compoundBrandBackgroundHover,
              c.compoundBrandBackgroundPressed,
            );
      stroke = off
          ? c.transparentStrokeDisabled
          : press == Fluent2Press.rest
          ? c.transparentStroke
          : c.transparentStrokeInteractive;
      knob = off ? c.neutralForegroundDisabled : c.neutralForegroundInverted;
    } else {
      fill = c.transparentBackground;
      stroke = press.pick(
        c.neutralStrokeAccessible,
        c.neutralStrokeAccessibleHover,
        c.neutralStrokeAccessiblePressed,
        fluent2Step(t, c.neutralStrokeDisabled),
      );
      knob = off
          ? c.neutralForegroundDisabled
          : press.pick(
              c.neutralStrokeAccessible,
              c.neutralStrokeAccessibleHover,
              c.neutralStrokeAccessiblePressed,
            );
    }
    final duration = Fluent2Motion.on(context)
        ? Fluent2Motion.normal
        : Duration.zero;
    final rim =
        look.side ??
        BorderSide(color: look.edge ?? stroke, width: Fluent2Stroke.thin);
    final styled = look.shape;
    final corner = height / 2;
    final knobFill = look.foreground ?? knob;
    return AnimatedContainer(
      duration: duration,
      curve: Fluent2Motion.easyEase,
      width: width,
      height: height,
      decoration: styled != null
          ? ShapeDecoration(
              color: look.fill ?? fill,
              shape: styled.copyWith(side: rim),
            )
          : BoxDecoration(
              color: look.fill ?? fill,
              borderRadius: BorderRadius.circular(corner),
              border: Border.all(color: rim.color, width: rim.width),
            ),
      child: AnimatedAlign(
        duration: duration,
        curve: Fluent2Motion.easyEase,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: SizedBox(
          width: box,
          height: box,
          child: Center(
            child: Container(
              width: thumb,
              height: thumb,
              decoration: styled != null
                  ? ShapeDecoration(color: knobFill, shape: styled)
                  : corner >= height / 2
                  ? BoxDecoration(shape: BoxShape.circle, color: knobFill)
                  : BoxDecoration(
                      color: knobFill,
                      borderRadius: BorderRadius.circular(
                        corner * thumb / height,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
