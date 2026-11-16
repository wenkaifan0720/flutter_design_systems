import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Lets a choice control's room hang outside its keyline: a checkbox, radio
/// or switch keeps Fluent's 8 of room round its indicator,
/// which holds the focus ring, and is moved back by those 8 toward the start,
/// so the indicator's ink, the label above a switch included, starts where a
/// field and a title in the same column start. Paint and hits move together;
/// the part lays out at its own size. Plumbing of the components; pages
/// never place one.
class Fluent2HangRoom extends StatelessWidget {
  /// [child] moved toward the start by Fluent's 8.
  const Fluent2HangRoom({required this.child, super.key});

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return Transform.translate(
      offset: Offset(rtl ? Fluent2Spacing.s : -Fluent2Spacing.s, 0),
      transformHitTests: true,
      child: child,
    );
  }
}
