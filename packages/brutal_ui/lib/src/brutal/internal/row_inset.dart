import 'package:flutter/widgets.dart';

/// How far in from its sides a row keeps its words and its focus: a list
/// group's rule's width, which the group draws over its rows' sides; zero
/// outside a group.
class BrutalRowInset extends InheritedWidget {
  /// [inset] for the row in [child].
  const BrutalRowInset({super.key, required this.inset, required super.child});

  /// The room at each side.
  final double inset;

  /// The nearest inset; zero outside a group.
  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrutalRowInset>()?.inset ?? 0;

  @override
  bool updateShouldNotify(BrutalRowInset old) => inset != old.inset;
}

/// [row] running to its group's sides under a rule [inset] wide: a row that
/// [keepsRoom] keeps its words clear of the rule itself; any other stands
/// inside the rule, as it would in a frame.
Widget brutalToSides(Widget row, double inset, {required bool keepsRoom}) =>
    keepsRoom
    ? BrutalRowInset(inset: inset, child: row)
    : BrutalRowInset(
        inset: 0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: row,
        ),
      );
