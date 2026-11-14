import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/panel.dart';
import '../../theme.dart';

/// What a [FrostedSwipeAction] is lit as: [quiet] the wash in a hairline,
/// [accent] the ink act of something worth doing (Pin, Pay), [danger] the
/// danger fill of a loss (Delete).
enum FrostedSwipeTone {
  /// The wash in a hairline.
  quiet,

  /// The ink act: something worth doing.
  accent,

  /// The danger fill: a loss.
  destructive,
}

/// One action a swiped row reveals: a [label] under a glyph on a tile of
/// its [tone].
@immutable
class FrostedSwipeAction {
  /// Creates a [FrostedSwipeAction].
  const FrostedSwipeAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = FrostedSwipeTone.quiet,
  });

  /// The word, and what a screen reader calls the action.
  final String label;

  /// The glyph, from the Lucide set.
  final IconData icon;

  /// What the action does.
  final VoidCallback onPressed;

  /// How its tile is lit.
  final FrostedSwipeTone tone;
}

/// Actions revealed by swiping a row sideways: dragging the row uncovers
/// tiles ([FrostedSwipeAction], 84 wide with the 8 toward the row, corners
/// of 14) standing in the gap it leaves, the first nearest the edge. Let go
/// past half their width and the row settles open; short of that it
/// settles shut. A press on an open row closes it, a press on a tile does
/// it and closes the row. With [fullSwipe] a drag past 65% of the width
/// does the first action on that edge (the row's delete), its tile
/// widening to say so. The arrows open a side from the keyboard and Escape
/// closes it; each action is also a custom action on the row, so a screen
/// reader reaches it without the gesture. ui_core's [DesignSwipeActions]
/// is the behaviour. [initiallyOpen] starts the row open, its trailing
/// actions showing (the leading ones when it has no trailing): a preview,
/// or a one-time hint that the row swipes; it closes as any open row does.
/// The tiles are as tall as the row, and the row is at least a target tall
/// ([FrostedBreakpoints.hitTargetOf]).
/// DERIVED: the source has no swipes; the tiles take the wash,
/// the ink act and the danger fill.
///
/// ```dart
/// FrostedSwipeActions(trailing: [FrostedSwipeAction(label: 'Delete', icon: FrostedGlyphs.delete, tone: FrostedSwipeTone.destructive, onPressed: delete)], fullSwipe: true, child: row)
/// ```
class FrostedSwipeActions extends StatelessWidget {
  /// [child] with [leading] and [trailing] actions behind its edges.
  const FrostedSwipeActions({
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.fullSwipe = false,
    this.initiallyOpen = false,
    super.key,
  });

  /// The row.
  final Widget child;

  /// The actions under the leading edge.
  final List<FrostedSwipeAction> leading;

  /// The actions under the trailing edge.
  final List<FrostedSwipeAction> trailing;

  /// Whether a drag most of the way across does the edge's first action.
  final bool fullSwipe;

  /// Whether it starts open: the trailing actions showing (the leading
  /// ones when it has no trailing).
  final bool initiallyOpen;

  static DesignSwipeAction _behind(FrostedSwipeAction a) => DesignSwipeAction(
    label: a.label,
    onPressed: a.onPressed,
    destructive: a.tone == FrostedSwipeTone.destructive,
    data: a,
  );

  @override
  Widget build(BuildContext context) => ClipRect(
    // The row slides within its own lane: what it leaves behind goes under
    // the lane's edge, never out over the page's gutter (ui_core clips the
    // actions only). The lane reaches as far as a tile's focus ring.
    clipper: const _Lane(
      FrostedChromeMetrics.focusRingGap + FrostedChromeMetrics.focusRingWidth,
    ),
    child: DesignSwipeActions(
      startActions: [for (final a in leading) _behind(a)],
      endActions: [for (final a in trailing) _behind(a)],
      actionExtent: FrostedChromeMetrics.swipeBlock,
      fullSwipe: fullSwipe,
      fullSwipeFraction: FrostedChromeMetrics.swipeFull,
      initiallyOpen: initiallyOpen,
      actionBuilder: (tileContext, action, state) => _Tile(
        action.data! as FrostedSwipeAction,
        state.states,
        Directionality.of(context),
      ),
      // The tiles stand as tall as the row, so the row is at least a
      // target tall: 48 under a finger, 44 under a pointer.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: FrostedBreakpoints.hitTargetOf(context),
        ),
        child: child,
      ),
    ),
  );
}

class _Lane extends CustomClipper<Rect> {
  const _Lane(this.reach);

  final double reach;

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(reach);

  @override
  bool shouldReclip(_Lane old) => old.reach != reach;
}

/// One revealed tile: the glyph over the word on its tone's face, a gap of
/// 8 toward the row; its face dims while pressed and wears the focus ring
/// from the keyboard.
class _Tile extends StatelessWidget {
  const _Tile(this.action, this.states, this.direction);

  final FrostedSwipeAction action;
  final Set<WidgetState> states;

  /// The page's direction. ui_core lays the end side's tiles out reversed
  /// (its first nearest the edge), which the gap toward the row follows;
  /// the face's words read in the page's own direction, so a word cut at
  /// large text loses its end, not its start.
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final (
      Color ink,
      Color? fill,
      List<Gradient> gradients,
      Color? ring,
      Color? sheen,
      List<BoxShadow> shadows,
    ) = switch (action.tone) {
      FrostedSwipeTone.quiet => (
        t.colorScheme.textPrimary,
        t.glass.wash,
        const <Gradient>[],
        t.colorScheme.border,
        null,
        const <BoxShadow>[],
      ),
      FrostedSwipeTone.accent => (
        t.colorScheme.onButton,
        null,
        <Gradient>[t.colorScheme.buttonFill],
        null,
        t.colorScheme.buttonSheen,
        t.shadows.button,
      ),
      FrostedSwipeTone.destructive => (
        t.colorScheme.onDanger,
        t.colorScheme.danger,
        const <Gradient>[],
        null,
        t.colorScheme.buttonSheen,
        const <BoxShadow>[],
      ),
    };
    final face = FrostedFace(
      material: FrostedMaterial.paint,
      radius: BorderRadius.circular(FrostedCorners.r14),
      color: fill,
      gradients: gradients,
      ring: ring,
      sheen: sheen,
      shadows: shadows,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: FrostedSpacing.s4,
        children: [
          Icon(action.icon, size: FrostedIconSize.i20, color: ink),
          Text(
            action.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.overline.c(ink),
          ),
        ],
      ),
    );
    return Padding(
      // The tiles lie in a row whose start is the row's edge.
      padding: const EdgeInsetsDirectional.only(
        end: FrostedChromeMetrics.swipeGap,
      ),
      child: Directionality(
        textDirection: direction,
        child: frostedRingFor(
          states,
          states.contains(WidgetState.pressed)
              ? Opacity(opacity: 0.7, child: face)
              : face,
          radius: FrostedCorners.r14,
        ),
      ),
    );
  }
}
