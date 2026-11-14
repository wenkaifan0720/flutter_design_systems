import 'package:flutter/widgets.dart';

import '../../icons.dart';
import '../../internal/well.dart';
import '../../styled.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// Fluent 2's Checkbox indicator as a selectable card, list row, table row
/// and tree item draw it (`useCheckboxStyles`): a 16 square at the small
/// corner (2) in a 1 stroke of `neutralStrokeAccessible`; checked, the
/// `compoundBrandBackground` fill with the 12 checkmark in
/// `neutralForegroundInverted`; mixed ([checked] null), the brand stroke
/// round an 8 square of `compoundBrandForeground1`; disabled, the disabled
/// stroke and mark. Drawn in [press]'s step. Plumbing of the structure
/// components, never exported: the control a page places is the
/// checkbox's own.
class Fluent2CheckIndicator extends StatelessWidget {
  /// A check indicator, [checked] on, off or mixed.
  const Fluent2CheckIndicator({
    required this.checked,
    this.press = Fluent2Press.rest,
    super.key,
  });

  /// On, off, or null for mixed.
  final bool? checked;

  /// The pressed, hovered or resting step it is drawn in.
  final Fluent2Press press;

  /// The indicator's side.
  static const double side = 16;

  @override
  Widget build(BuildContext context) {
    final c = context.fluent2Theme.colors;
    final disabled = press == Fluent2Press.disabled;
    final on = checked;
    final Color fill;
    final Color stroke;
    final Color mark;
    if (disabled) {
      fill = c.transparentBackground;
      stroke = fluent2Step(context.fluent2Theme, c.neutralStrokeDisabled);
      mark = c.neutralForegroundDisabled;
    } else if (on == true) {
      fill = press.pick(
        c.compoundBrandBackground,
        c.compoundBrandBackgroundHover,
        c.compoundBrandBackgroundPressed,
      );
      stroke = fill;
      mark = c.neutralForegroundInverted;
    } else if (on == null) {
      fill = c.transparentBackground;
      stroke = press.pick(
        c.compoundBrandStroke,
        c.compoundBrandStrokeHover,
        c.compoundBrandStrokePressed,
      );
      mark = press.pick(
        c.compoundBrandForeground1,
        c.compoundBrandForeground1Hover,
        c.compoundBrandForeground1Pressed,
      );
    } else {
      fill = c.transparentBackground;
      stroke = press.pick(
        c.neutralStrokeAccessible,
        c.neutralStrokeAccessibleHover,
        c.neutralStrokeAccessiblePressed,
      );
      mark = c.transparentBackground;
    }
    return fluent2EasedInks([fill, stroke, mark], (context, inks) {
      final [fill, stroke, mark] = inks;
      return SizedBox.square(
        dimension: side,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(Fluent2Radius.small),
            border: Border.all(color: stroke),
          ),
          child: Center(
            child: on == null
                ? SizedBox.square(
                    dimension: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: mark,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  )
                : on
                ? Icon(Fluent2Icons.checkmark12, size: 12, color: mark)
                : null,
          ),
        ),
      );
    });
  }
}
