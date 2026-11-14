/// Actions behind a list row, revealed by a swipe, painted on ui_core's
/// swipe actions; and swipe-to-delete.
library;

import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../internal/kit_paint.dart';
import '../localizations.dart';
import '../theme.dart';
import 'tag.dart';

/// One action a [MinimalSwipeActions] row reveals: a square the row's full
/// height on the muted ground, holding the glyph over a short label in its
/// [tone]'s ink.
///
/// Destructive actions say `destructive: true` (the destructive ink); every
/// other word is the full ink, or a status's own ink — `success` for a
/// "done", `warning` for a snooze — and `neutral` is the quiet ink of a
/// "more".
///
/// ```dart
/// MinimalSwipeAction('Archive', icon: LucideIcons.archive, onPressed: archive)
/// ```
@immutable
class MinimalSwipeAction {
  /// An action saying [label] behind a row.
  const MinimalSwipeAction(
    this.label, {
    required this.onPressed,
    this.icon,
    this.destructive = false,
    this.tone,
  });

  /// The word under the glyph, and what a screen reader offers as the row's
  /// custom action.
  final String label;

  /// Runs it; the row closes after.
  final VoidCallback onPressed;

  /// A glyph over the label.
  final IconData? icon;

  /// The destructive register: the destructive ink, whatever [tone] says.
  final bool destructive;

  /// The words' ink; null takes the full ink (the destructive ink for
  /// [destructive]).
  final MinimalTone? tone;

  /// The tone this action resolves to.
  MinimalTone get resolvedTone =>
      destructive ? MinimalTone.destructive : (tone ?? MinimalTone.primary);
}

/// Leading and trailing swipe actions for a list row: dragging the row
/// aside reveals square actions the row's full height on the muted ground,
/// a hairline between each, with no rounding and no gap: the acts are
/// words, as everything in Minimal is; no block of colour stands behind
/// them.
///
/// The row snaps open past half its actions' width (or on a flick) and
/// closed below it; while open, a tap on the row closes it rather than
/// opening the row. Full swipe is opt-in ([allowsFullSwipe]): past 60 % of
/// the row the FIRST action on that edge grows to meet it and runs on
/// release (a [MinimalSwipeAction.destructive] one slides the row away first).
/// The keyboard opens a side with the arrows and focuses its first action
/// (Escape closes it, focus back in the row); every action is also offered
/// as a custom semantics action, so the row is fully usable without the
/// gesture. Right-to-left layouts mirror the edges. The behaviour is
/// ui_core's ([DesignSwipeActions]); Minimal paints it.
///
/// ```dart
/// MinimalSwipeActions(trailing: [MinimalSwipeAction('Delete', destructive: true, icon: LucideIcons.trash2, onPressed: delete)], child: row)
/// ```
class MinimalSwipeActions extends StatelessWidget {
  /// [child] with actions behind it.
  const MinimalSwipeActions({
    super.key,
    required this.child,
    this.leading = const [],
    this.trailing = const [],
    this.allowsFullSwipe = false,
    this.initiallyOpen = false,
  });

  /// The row — usually a [MinimalThemeData.rowHeight] row with its own
  /// hairline.
  final Widget child;

  /// Actions revealed by a drag toward the trailing edge, first nearest the
  /// leading edge.
  final List<MinimalSwipeAction> leading;

  /// Actions revealed by a drag toward the leading edge, first nearest the
  /// trailing edge.
  final List<MinimalSwipeAction> trailing;

  /// A long swipe past 60 % of the row performs the first action on that
  /// edge.
  final bool allowsFullSwipe;

  /// Start with the trailing actions revealed (the leading ones when there
  /// are no trailing ones): a preview, or a one-time hint that the row
  /// swipes.
  final bool initiallyOpen;

  /// The least width each revealed action takes. A word wider than that at
  /// the current text size (a larger text, a longer language) widens every
  /// square on the row to it, so no word runs into its square's edge.
  static const double actionWidth = 64;

  /// The squares' width on this row: [actionWidth], or the widest word with
  /// its square's side air where that is wider.
  double _extent(BuildContext context) {
    final style = _ActionCell.labelStyleOf(context.minimalTheme);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var extent = actionWidth;
    for (final a in [...leading, ...trailing]) {
      final word = TextPainter(
        text: TextSpan(text: a.label, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      extent = math.max(
        extent,
        (word.width + 2 * _ActionCell.padH).ceilToDouble(),
      );
      word.dispose();
    }
    return extent;
  }

  static DesignSwipeAction _design(MinimalSwipeAction a) => DesignSwipeAction(
    label: a.label,
    onPressed: () {
      HapticFeedback.selectionClick();
      a.onPressed();
    },
    destructive: a.destructive,
    data: a,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // The row slides within its own box: what moves past the list's edge
    // is cut there, never hanging past the hairlines or over a neighbour.
    return ClipRect(
      child: DesignSwipeActions(
        startActions: [for (final a in leading) _design(a)],
        endActions: [for (final a in trailing) _design(a)],
        actionExtent: _extent(context),
        fullSwipe: allowsFullSwipe,
        initiallyOpen: initiallyOpen,
        actionBuilder: (context, action, state) => _ActionCell(
          action: action.data! as MinimalSwipeAction,
          state: state,
        ),
        // The row's own ground, so the actions stay hidden under it until
        // it moves.
        child: ColoredBox(color: t.background, child: child),
      ),
    );
  }
}

/// One revealed square: the muted ground with a hairline on its side toward
/// the row (between two squares, and between the row and the inner one;
/// none at the row's outer edge), the
/// glyph over the label in the tone's ink when the row is tall enough to
/// carry both at the current text scale, else the label alone; the word is
/// what says what the square does.
class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.action, required this.state});

  final MinimalSwipeAction action;
  final DesignSwipeActionDetails state;

  /// The cell's air above and below its content, and between the glyph and
  /// the label.
  static const double _padV = 3;
  static const double _gap = MinimalSpacing.s2;
  static const double _glyph = MinimalIconSize.i14;

  /// The cell's air at each side of its word: a word that widens the
  /// squares (larger text, a longer word) keeps 12 px from the divider and
  /// the row's end, as a button keeps its words off its edge.
  static const double padH = MinimalSpacing.s12;

  /// The label's type, before its ink.
  static TextStyle labelStyleOf(MinimalThemeData t) => t.caption.medium;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // The accent is the page's one act, so a swipe's word never wears it.
    final ink = switch (action.resolvedTone) {
      MinimalTone.primary => t.foreground,
      MinimalTone.success => t.successInk,
      MinimalTone.warning => t.warningInk,
      MinimalTone.destructive => t.destructiveInk,
      MinimalTone.neutral => t.mutedForeground,
    };
    final labelStyle = labelStyleOf(t).c(ink);
    final icon = action.icon;
    // The press wash and the focus ring lie inside the square: its
    // neighbours butt against it.
    final states = state.states;
    return Container(
      foregroundDecoration: BoxDecoration(
        color: states.down ? t.foreground.withValues(alpha: 0.08) : null,
        border: states.ring
            ? Border.fromBorderSide(
                BorderSide(
                  color: t.ring,
                  width: t.focusWidth,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              )
            : null,
      ),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.muted,
            // The strip runs from the row's edge inward (ui_core reverses
            // the end side), so the side toward the row is the end.
            border: BorderDirectional(end: t.rule),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final size = labelStyle.fontSize ?? 12;
              final line =
                  MediaQuery.textScalerOf(context).scale(size) *
                  (labelStyle.height ?? 1.2);
              final both =
                  icon != null &&
                  c.maxHeight >= 2 * _padV + _glyph + _gap + line;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: padH,
                    vertical: _padV,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (both) ...[
                        MinimalIcon(icon, size: _glyph, color: ink),
                        const MinimalGap(_gap),
                      ],
                      // The row widens its squares to the widest word; a
                      // word that still overruns (a rounding) shrinks to fit
                      // rather than losing its end: the word is the action.
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            action.label,
                            style: labelStyle,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Swipe-to-delete for a list row, pulled from the trailing edge only.
///
/// ONE direction, endToStart: a row that dismisses both ways deletes on a
/// mis-swipe toward the back gesture. Under the row lies the muted ground,
/// square and full-bleed like the row itself, with the trash glyph and
/// [label] in [MinimalThemeData.destructiveInk] at the trailing gutter, so the
/// intent is legible before the finger commits. A screen reader gets the
/// same act as a custom action named [label].
///
/// UNDO IS THE PAGE'S BUSINESS: this removes the row and calls
/// [onDismissed]; the page keeps the record in hand and offers the way back
/// through `showMinimalSnackBar(context, 'Deleted', actionLabel: 'Undo',
/// onAction: restore)`.
///
/// ```dart
/// MinimalDismissible(key: ValueKey(habit.id), onDismissed: () => remove(habit), child: row)
/// ```
class MinimalDismissible extends StatelessWidget {
  /// [child], swiped away to dismiss it.
  const MinimalDismissible({
    required super.key,
    required this.onDismissed,
    required this.child,
    this.label,
  });

  /// Called once the row has left; the page owns the record and the undo.
  final VoidCallback onDismissed;

  /// The row.
  final Widget child;

  /// The word on the ground behind the row.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = label ?? MinimalLocalizations.of(context).delete;
    return Semantics(
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        CustomSemanticsAction(label: words): onDismissed,
      },
      // The row leaves through its list's edge, not over what stands beyond.
      child: ClipRect(
        child: Dismissible(
          // The gesture's own identity, distinct from this widget's: the
          // caller's key names the RECORD.
          key: ObjectKey(key),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDismissed(),
          background: ColoredBox(
            color: t.muted,
            child: Padding(
              padding: MinimalInsets.gutter,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MinimalIcon(
                      LucideIcons.trash2,
                      size: MinimalIconSize.i16,
                      color: t.destructiveInk,
                    ),
                    const MinimalGap(MinimalSpacing.s8),
                    Flexible(
                      child: Text(
                        words,
                        style: t.control.c(t.destructiveInk),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: ColoredBox(color: t.background, child: child),
        ),
      ),
    );
  }
}
