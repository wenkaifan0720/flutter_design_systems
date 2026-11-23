import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';
import 'button_stretch.dart';

/// A dialog's or a sheet's actions in Civic's order, the one that does what
/// the title asks first. On a phone they stand one under another, each the
/// whole width (as Civic's buttons are there), the first on top. Wider, they
/// stand side by side from the start while they fit, else in one column of
/// one width with the first on top: ui_core's RawActionBar lays them out,
/// and as it puts its last action on top once they stack, the bar hands it
/// Civic's order reversed while they stack.
class CivicDialogActions extends StatefulWidget {
  /// A bar of [actions], the one that does what the title asks first.
  const CivicDialogActions({super.key, required this.actions});

  /// The actions, in Civic's order.
  final List<Widget> actions;

  @override
  State<CivicDialogActions> createState() => _CivicDialogActionsState();
}

class _CivicDialogActionsState extends State<CivicDialogActions> {
  bool _stacked = false;

  @override
  Widget build(BuildContext context) {
    // Keyed by their place in Civic's order, so each keeps its state (its
    // focus) as the bar turns them round.
    final actions = [
      for (final (i, action) in widget.actions.indexed)
        KeyedSubtree(key: ValueKey(i), child: action),
    ];
    if (MediaQuery.sizeOf(context).width < CivicLayout.medium) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CivicSpacing.s12,
        children: actions,
      );
    }
    // Stacked, every button spans the column (Civic's buttons keep their
    // words' width on a desk).
    return CivicButtonStretch(
      stretch: _stacked,
      child: RawActionBar(
        spacing: CivicSpacing.s16,
        overflowSpacing: CivicSpacing.s12,
        alignment: MainAxisAlignment.start,
        onStackedChanged: (stacked) {
          if (mounted && stacked != _stacked) {
            setState(() => _stacked = stacked);
          }
        },
        children: _stacked ? actions.reversed.toList() : actions,
      ),
    );
  }
}
