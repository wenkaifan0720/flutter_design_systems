import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';
import '../pressable/pressable.dart';

/// One act a swiped row reveals, as a mail app's rows set them: its
/// [label] under its [icon] on a full-height pane of its [tone]'s solid
/// (archive in success's green, delete in danger's red, flag in warning's
/// orange, read in the brand, a quiet act in the informative grey).
///
/// ```dart
/// Fluent2SwipeAction(label: 'Archive', icon: Fluent2Icons.archive, tone: Fluent2Tone.success, onPressed: archive)
/// ```
@immutable
class Fluent2SwipeAction {
  /// A swipe action labelled [label].
  const Fluent2SwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = Fluent2Tone.informative,
  });

  /// The word, and what a screen reader calls the act.
  final String label;

  /// The act's glyph.
  final IconData icon;

  /// Called when the act is pressed or swiped through.
  final VoidCallback onPressed;

  /// The act's colour.
  final Fluent2Tone tone;
}

/// A row with acts revealed by a swipe, as a phone's mail app lays a
/// message's: dragging the row sideways uncovers full-height panes 80
/// wide in the tones' solids, the first nearest the edge. Let go past half
/// their width and the row settles open; short of it, it settles shut. A
/// press on a pane does its act and shuts the row. With [fullSwipe] a drag
/// past 60% of the width does the edge's first act (a mail app's archive
/// or delete), its pane widening as it arms. The arrows open a side from the
/// keyboard and focus its first pane; Escape shuts it. Each act is also a
/// custom action on the row, so a screen reader or a pointer that cannot
/// swipe reaches it. [initiallyOpen] stands an edge open on the first
/// frame: the trailing one, the leading one when there is no trailing act.
/// The behaviour is the design kit's DesignSwipeActions; Fluent 2 paints
/// the panes.
///
/// ```dart
/// Fluent2SwipeActions(leading: [Fluent2SwipeAction(label: 'Archive', icon: Fluent2Icons.archive, tone: Fluent2Tone.success, onPressed: archive)], trailing: [Fluent2SwipeAction(label: 'Delete', icon: Fluent2Icons.delete, tone: Fluent2Tone.danger, onPressed: delete)], child: row)
/// ```
class Fluent2SwipeActions extends StatelessWidget {
  /// Swipe actions on [child].
  const Fluent2SwipeActions({
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.fullSwipe = false,
    this.initiallyOpen = false,
    super.key,
  });

  /// The row: opaque, so the panes show only in the gap it leaves.
  final Widget child;

  /// The acts a drag toward the end shows, the first nearest the edge.
  final List<Fluent2SwipeAction> leading;

  /// The acts a drag toward the start shows, the first nearest the edge.
  final List<Fluent2SwipeAction> trailing;

  /// Whether a drag past 60% of the row does its edge's first act.
  final bool fullSwipe;

  /// Whether an edge stands open on the first frame (the trailing one, the
  /// leading one when there is no trailing act): a preview, or a one-time
  /// hint that the row swipes.
  final bool initiallyOpen;

  /// One pane's width.
  static const double paneWidth = 80;

  static List<DesignSwipeAction> _kit(List<Fluent2SwipeAction> acts) => [
    for (final a in acts)
      DesignSwipeAction(
        label: a.label,
        onPressed: a.onPressed,
        destructive: a.tone == Fluent2Tone.danger,
        data: a,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    // The row slides inside its own bounds: the face moved aside is cut at
    // the row's edges, never carried past the page's margin.
    return ClipRect(
      child: DesignSwipeActions(
        startActions: _kit(leading),
        endActions: _kit(trailing),
        actionExtent: paneWidth,
        fullSwipe: fullSwipe,
        initiallyOpen: initiallyOpen,
        actionBuilder: (context, action, state) => _Pane(
          action: action.data! as Fluent2SwipeAction,
          states: state.states,
        ),
        child: child,
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.action, required this.states});

  final Fluent2SwipeAction action;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final colors = t.tone(action.tone);
    final ink = colors.onSolid;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ColoredBox(
          color: colors.solid,
          child: ClipRect(
            child: OverflowBox(
              minWidth: Fluent2SwipeActions.paneWidth,
              maxWidth: Fluent2SwipeActions.paneWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: Fluent2Spacing.xs,
                children: [
                  Icon(action.icon, size: Fluent2IconSize.i20, color: ink),
                  // Whole, 8 in from the pane's sides: drawn smaller where
                  // a large text size would run it past them, never cut.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Fluent2Spacing.s,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        action.label,
                        maxLines: 1,
                        softWrap: false,
                        style: t.caption1Strong.c(ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (states.focused)
          const Positioned.fill(
            child: IgnorePointer(child: Fluent2FocusRing(radius: 0)),
          ),
      ],
    );
  }
}
